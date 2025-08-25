#' @keywords internal

# This class is used to build an AI prompt and call the AI policy advisor.
# - `ai_prompt` is the running AI prompt buffer.
# - `MAX_CHARS` is the maximum number of characters allowed in the AI prompt.
# - `initialize()` initializes the class with an empty prompt.
# - `add_to_ai_prompt()` appends (string versions of) results to the running AI prompt
# - `read_file_for_ai()` reads a file and adds its contents to the AI prompt.
# - `ai_policy_advisor()` calls the AI policy advisor.

AIPolicyAdvisor <- R6::R6Class(
  "AIPolicyAdvisor",
  
  # Key variables:
  public = list(
    ai_prompt = "",
    max_chars = 32000L,

    # Initialize the class with an empty prompt.
    initialize = function() {
      self$ai_prompt <- ""
    },

    # Append arbitrary results to the running AI prompt buffer as plain text.
# - Supports "atomic" vectors (character/logical/numeric/integer/factor),
#   "rectangular" objects (data.frame including and tibble/matrix/table), and nested lists.
# - Everything is rendered to text, then a newline is appended.
# - Returns the original `results` invisibly so this can be used inline in pipelines.
    add_to_ai_prompt = function(results, context = "") {
      # Guard: caller must supply `results` (prevents silent NULL input).
      stopifnot(!missing(results))

      # Small helper function: append a line to the internal buffer with a trailing newline.
      add_line <- function(txt) self$ai_prompt <- paste0(self$ai_prompt, txt, "\n")

      # ----- Atomic vectors: collapse to a single space-separated line.
      if (is.character(results) || is.logical(results) || is.numeric(results) ||
          is.integer(results)  || is.factor(results)) {

        # Collapse vector elements into one string (e.g., c(1,2,3) -> "1 2 3").
        string <- paste(results, collapse = " ")

        # If a `context` label is provided and non-empty, prefix it.
        # `nzchar(x)` is an efficient "non-empty string" check.
        if (nzchar(context)) string <- paste(context, string)

        # Call add_line helper function to append the string to the prompt.
        add_line(string)
      
      # ----- Rectangular data: print() to a console-friendly table.
      } else if (inherits(results, "data.frame") || is.matrix(results) || inherits(results, "table")) {
        
        # Capture printed table output as a character vector, then join with newlines.
        # `capture.output(print(x))` mirrors what you'd see in an interactive session.
        string <- paste(utils::capture.output(print(results)), collapse = "\n")

        # When appending to AI prompt, put context for the data above the table to frame the LLM's interpretation.
        if (nzchar(context)) string <- paste(context, "\n", string, sep = "")
        add_line(string)

      # ----- Lists / nested structures: JSON when possible; fallback to `str()`.
      } else if (is.list(results)) {

        # Try pretty JSON with stable scalars (`auto_unbox = TRUE`).
        # This is more compact and easier to parse than `str()`.
        string <- tryCatch(
          as.character(jsonlite::toJSON(results, pretty = TRUE, auto_unbox = TRUE)),
          error = function(e) {
            # If JSON fails (e.g., with non-serializable elements), fall back to `str()`.
            paste(utils::capture.output(str(results)), collapse = "\n")
          }
        )

        # When appending to AI prompt, put context for the data above the table to frame the LLM's interpretation.
        if (nzchar(context)) string <- paste(context, "\n", string, sep = "")
        add_line(string)

      # ----- Last resort: coerce unknown types to character, or error.
      } else {
        string <- tryCatch(as.character(results), error = function(e) NULL)
        if (is.null(string)) stop("Unsupported type for add_to_ai_prompt().")
        if (nzchar(context)) string <- paste(context, string)
        add_line(string)
      }

      # Invisibly return the original input so caller can keep using it.
      invisible(results)
    },

# Read a file and add its contents to the AI prompt.
# - Supports .csv and .md files.
# - .csv files are printed as a table.
# - .md files are added as plain text.
# - Returns the file contents as a string.
# - Errors if the file doesn't exist or has an invalid extension.
    read_file_for_ai = function(file_path) {
      # Guard: caller must supply `file_path` (prevents silent NULL input).
      stopifnot(!missing(file_path))

      # Guard: file must exist.
      if (!file.exists(file_path)) stop(sprintf("File not found: %s", file_path))

      # Determine file type and handle accordingly.
      file_extension <- tolower(tools::file_ext(file_path))

      # ----- .csv files: print() to a console-friendly table.
      if (identical(file_extension, "csv")) {
        # Read the CSV file into a data frame.
        df <- utils::read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)

        # Capture printed table output as a character vector, then join with newlines.
        string <- paste(utils::capture.output(print(df)), collapse = "\n")

        # Append the table to the AI prompt.
        self$ai_prompt <- paste0(self$ai_prompt, string, "\n")

        # Return the table as a string.
        return(string)

      # ----- .md files: add as plain text.
      } else if (identical(file_extension, "md")) {
        # Read the Markdown file as plain text.
        txt <- paste(readLines(file_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

        # Append the text to the AI prompt.
        self$ai_prompt <- paste0(self$ai_prompt, txt, "\n")

        # Return the text as a string.
        return(txt)
      }

      # Error if the file type is invalid.
      stop("Invalid file type. Use .csv or .md.")
    },

    # Call the AI policy advisor.
# - Requires `data_background`, `policy_question`, and `model` in the `config` list.
# - Errors if any required keys are missing.
# - Errors if the prompt is empty.
# - Errors if the model name is invalid.
# - Returns the AI policy advisor's response as a string.
    ai_policy_advisor = function(config = list()) {
      # Guard: required parameters must be present.
      required_parameters <- c("data_background", "policy_question", "model")
      missing_parameters <- setdiff(required_parameters, names(config))
      if (length(missing_parameters)) stop(sprintf("Missing required parameters: %s", paste(missing_parameters, collapse = ", ")))

      # Guard: prompt must be non-empty.
      if (!nzchar(self$ai_prompt)) stop("Prompt is empty. Call add_to_ai_prompt(...) first.")

      # Extract the required parameters from the config list.
      data_background <- as.character(config[["data_background"]] %||% "")
      policy_question <- as.character(config[["policy_question"]] %||% "")
      model_name      <- as.character(config[["model"]] %||% "")

      # Guard: model name must be valid (specified in the config).
      if (!nzchar(model_name) || identical(model_name, "<ENTER YOUR MODEL HERE>")) {
        stop("Please set a valid model name in CONFIG$model (e.g., 'qwen3:14b').")
      }

      # Format the data background and policy question for the AI prompt.
      if (nzchar(data_background)) data_background <- paste("Here is the data background:", data_background)
      if (nzchar(policy_question)) policy_question <- paste("I need help answering a specific policymaking/decision-making question:", policy_question)

      # Assemble the system message for the AI prompt and provide some prompt engineering instructions, framing LLM's role.
      system_message <- paste(
        "You are a policy analyst/data scientist assisting in interpreting the data.",
        data_background, policy_question,
        "Focus on synthesizing the data results and providing insights across results,",
        "backing up every interpretation with clear evidence and rationale.",
        "Make sure any numbers you repeat exactly match those provided.",
        "Provide a strong summary at the end."
      )

      # Assemble the user blob for the AI prompt.
      prompt_text <- {
        text <- self$ai_prompt
        # If the text is longer than the maximum number of characters, truncate it.
        if (nchar(text, type = "bytes") > self$max_chars) substr(text, 1L, self$max_chars) else text
      }

      # Call the AI policy advisor. Enables streaming of the response.
      model_output <- self$call_ollama(model_name, system_message, prompt_text, stream = TRUE)

      # Format the output.
      header <- paste(
        "----- Disclaimer: This interpretation was produced by a local LLM via Ollama and may contain errors.",
        "Verify with a domain expert before making decisions. This is a fast, first-pass interpretation.",
        "-----\n\n## AI Policy Advisor\n"
      )

      # Format the response.
      response <- paste0(header, model_output)

      # Write the response to a file.
      writeLines(response, "ai_interpretation.md")

      # Clear the prompt string.
      self$ai_prompt <- ""

      # Return the response.
      response
    },

    # Call the Ollama API.
    # - Requires `model`, `system_message`, and `user_prompt`.
    # - Errors if the model name is invalid.
    # - Errors if the system message is empty.
    # - Errors if the user prompt is empty.
    # - Returns the model's response as a string.
    call_ollama = function(model, system_message, user_prompt, stream = TRUE) {
      # The Ollama API endpoint.
      url <- "http://localhost:11434/api/generate"

      # Assemble the request data.
      request_data <- list(
        model  = model,
        prompt = paste0(system_message, "\n\nUser data: ", user_prompt),
        stream = isTRUE(stream)
      )

      # If streaming is enabled, use curl to stream the response.
      if (isTRUE(stream) && requireNamespace("curl", quietly = TRUE)) {
        # Initialize the response string.
        full <- ""

        # Create a new connection to the API.
        api_connection <- curl::new_handle()

        # Set the headers for the request. Headers are used to identify the request as JSON.
        curl::handle_setheaders(api_connection, "Content-Type" = "application/json")

        # Set the request data for the API connection.
        curl::handle_setopt(api_connection, postfields = jsonlite::toJSON(request_data, auto_unbox = TRUE))
        
        # Display streaming header.
        cat("🤖 AI Response (streaming):\n", strrep("-", 50), "\n", sep = "")
        
        # Define callback function to process streaming response chunks.
        callback <- function(data) {
          # Split incoming data into lines and process each one.
          for (ln in strsplit(rawToChar(data), "\n", fixed = TRUE)[[1]]) {
            if (!nzchar(ln)) next
            
            # Try to parse each line as JSON.
            obj <- try(jsonlite::fromJSON(ln), silent = TRUE)
            
            # If parsing succeeds and contains a response token, display and accumulate it.
            if (!inherits(obj, "try-error") && !is.null(obj$response)) {
              token <- obj$response
              full <<- paste0(full, token)
              cat(token); flush.console()
            }
          }
          TRUE
        }
        
        # Execute the streaming request and handle any errors.
        res <- try(curl::curl_fetch_stream(url, callback, handle = api_connection), silent = TRUE)
        if (inherits(res, "try-error")) stop("Error connecting to Ollama (streaming). Is 'ollama serve' running?")
        
        # Display streaming footer and return the complete response.
        cat("\n", strrep("-", 50), "\n", sep = "")
        return(full)
      }

      # Fallback to non-streaming request if curl is not available.
      resp <- httr::POST(url, body = request_data, encode = "json", httr::timeout(420))
      
      # Check if the request was successful.
      if (httr::status_code(resp) != 200L) {
        # Extract error message from response body.
        body <- tryCatch(httr::content(resp, as = "text", encoding = "UTF-8"), error = function(...) "")
        stop(paste0("Ollama API failed (HTTP ", httr::status_code(resp), "). ", if (nzchar(body)) paste0("Body: ", body)))
      }
      
      # Parse the JSON response and extract the model's output.
      parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
      parsed$response %||% ""
    }
  )
)

# internal null-coalescing
`%||%` <- function(a, b) if (!is.null(a)) a else b