#' @keywords internal
# This class is used to build an AI prompt and call the AI policy advisor.
# - `ai_prompt` is the running AI prompt buffer.
# - `max_chars` is the maximum number of characters allowed in the AI prompt.
# - `initialize()` initializes the class with an empty prompt.
# - `add_to_ai_prompt()` appends (string versions of) results to the running AI prompt
# - `read_file_for_ai()` reads a file and adds its contents to the AI prompt.
# - `ai_policy_advisor()` calls the AI policy advisor.
#
# NOTES:
# - R6::R6Class() creates an object-oriented class system (like Python's classes)
# - This is more advanced than basic R functions - it creates objects with methods
# - The class has "public" methods that can be called from outside
# - Each method is a function that can access the class's data via `self$`

AIPolicyAdvisor <- R6::R6Class(  # R6::R6Class() creates a new class - this is object-oriented programming
  "AIPolicyAdvisor",              # The name of the class (used for debugging and documentation)
  
  # Key variables:
  public = list(                   # "public" means these methods can be called from outside the class
    ai_prompt = "",                # Class variable: stores the AI prompt text
    max_chars = 32000L,            # Class variable: L suffix makes this an integer (not double)

    # Initialize the class with an empty prompt.
    initialize = function() {        # Constructor runs when pkgenv.R .onLoad() loads package, creates class instance
      self$ai_prompt <- ""          # self$ refers to the current object's variables
    },

    # Append arbitrary results to the running AI prompt buffer as plain text.
    # - Supports atomic vectors, rectangular objects (data.frame/matrix/table),
    #   model/test objects, and lists (JSON fallback to str()).
    # - Returns `results` invisibly for pipeability.
    add_to_ai_prompt = function(results, context = "") {
      stopifnot(!missing(results))   # stopifnot() checks if results is provided - stops execution if missing

      # Helper function defined inside the main function (nested function)
      add_line <- function(text) self$ai_prompt <- paste0(self$ai_prompt, text, "\n")
      # Helper function to add context with optional newline
      prepend_context <- function(string, newline = TRUE) {
        if (nzchar(context)) paste(context, if (newline) "\n" else " ", string, sep = "") else string
        # nzchar() checks if a string is non-empty (not zero characters)
      }

      # Check if results is an atomic vector (single values like numbers, text, etc.)
      if (is.atomic(results)) {
        # Convert factor to character to ensure readable output
        atomic_vector <- if (is.factor(results)) as.character(results) else results
        
        # Clip very long atomic vectors to avoid bloating the prompt
        max_preview_length <- 100L
        is_long_vector <- length(atomic_vector) > max_preview_length
        preview_vector <- if (is_long_vector) utils::head(atomic_vector, max_preview_length) else atomic_vector
        
        string <- paste(preview_vector, collapse = " ")
        if (is_long_vector) {
          string <- paste0(string, glue::glue(" ... [and {length(atomic_vector) - max_preview_length} more]"))
        }
        add_line(prepend_context(string, newline = FALSE))
      
      # Check if results is a rectangular data structure (tables, matrices, data frames)
      } else if (is.data.frame(results) || is.matrix(results) || inherits(results, "table")) {
        add_line(prepend_context(self$.render_table(results), newline = TRUE))
        # self$.render_table() calls a private method (note the dot prefix)

      # Check if results is a statistical model or test (MUST be before is.list() check)
      } else if (self$.is_model_or_test(results)) {   # MUST be before is.list()
        add_line(prepend_context(self$.render_stat(results), newline = TRUE))
        # Many models are lists, so we check this before the general list check

      # Check if results is a list (could be nested data, JSON-like structures)
      } else if (is.list(results)) {
        add_line(prepend_context(self$.render_list(results), newline = TRUE))

      # Last resort: try to convert to character, or give up
      } else {
        string <- tryCatch(as.character(results), error = function(error) NULL)
        # tryCatch() tries to run code, but catches errors and runs fallback code
        if (is.null(results) || length(string) == 0L) {
          # Render explicit NULLs in a readable way while preserving context
          string <- "Result was NULL"
        } else if (is.null(string)) {
          stop("Unsupported type for add_to_ai_prompt().")
        }
        add_line(prepend_context(string, newline = FALSE))
      }

      invisible(results)
    },

# Read a file and add its contents to the AI prompt.
# - Supports .csv and .md files.
    # - CSV printing is width-expanded and row-limited to avoid token blowups.
    read_file_for_ai = function(file_path, max_rows = 50L) {
      stopifnot(!missing(file_path))                                    # Check if file_path is provided
      if (!file.exists(file_path)) stop(glue::glue("File not found: {file_path}"))  # Check if file exists
      # file.exists() returns TRUE/FALSE. glue::glue() builds strings with placeholders, e.g.,
      # glue::glue() provides f-string-like interpolation

      file_extension <- tolower(tools::file_ext(file_path))              # Get file extension (e.g., "csv", "md")
      # tools::file_ext() extracts the extension, tolower() converts to lowercase

      if (identical(file_extension, "csv")) {                            # Check if file is CSV
        data_frame <- utils::read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)
        # utils::read.csv() reads CSV files, stringsAsFactors=FALSE keeps text as text (not factors)
        
        # Create a header showing data dimensions and row limit
        header <- glue::glue(
          "[data.frame: {nrow(data_frame)} rows x {ncol(data_frame)} cols] showing first {min(nrow(data_frame), max_rows)} rows\n"
        )
        # glue::glue() provides f-string-like interpolation
        
        # Define a function that prints the first few rows
        printer <- function() paste(utils::capture.output(print(utils::head(data_frame, max_rows))), collapse = "\n")
        # utils::head() shows first N rows, utils::capture.output() captures printed output as text
        
        # Try to use withr package for better formatting, fallback to basic printing
        body <- if (requireNamespace("withr", quietly = TRUE)) {
          withr::with_options(list(width = 1000L), printer())            # Temporarily set console width to 1000
        } else printer()
        
        string <- paste0(header, body)                                  # Combine header and data
        self$ai_prompt <- paste0(self$ai_prompt, string, "\n")          # Add to AI prompt
        return(string)

      } else if (identical(file_extension, "md")) {                      # Check if file is Markdown
        text <- paste(readLines(file_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
        # readLines() reads file line by line, paste() with collapse="\n" joins lines with newlines
        # warn=FALSE suppresses warnings, encoding="UTF-8" handles special characters
        
        self$ai_prompt <- paste0(self$ai_prompt, text, "\n")            # Add to AI prompt
        return(text)
      }

      stop("Invalid file type. Use .csv or .md.")
    },

    ai_policy_advisor = function(config = list()) {                      # Main method to call the AI
      required_parameters <- c("data_background", "policy_question", "model")  # List of required config items
      missing_parameters <- setdiff(required_parameters, names(config))        # Find which ones are missing
      # setdiff() returns elements in first vector that are NOT in second vector
      
      if (length(missing_parameters)) {                                  # If any parameters are missing
        stop(glue::glue("Missing required parameters: {paste(missing_parameters, collapse = ', ')}"))
        # paste() with collapse=", " joins missing parameters with commas
      }
      if (!nzchar(self$ai_prompt)) stop("Prompt is empty. Call add_to_ai_prompt(...) first.")
      # nzchar() checks if string is non-empty

      # Extract parameters from config list, with fallback to empty string if missing
      data_background <- as.character(config[["data_background"]] %||% "")    # %||% is our custom null-coalescing operator
      policy_question <- as.character(config[["policy_question"]] %||% "")    # as.character() converts to text
      model_name      <- as.character(config[["model"]] %||% "")             # config[["key"]] gets value from list

      # Check if model name is valid (not empty or placeholder)
      if (!nzchar(model_name) || identical(model_name, "<ENTER YOUR MODEL HERE>")) {
        stop("Please set a valid model name in CONFIG$model (e.g., 'qwen3:14b').")
        # identical() checks if two values are exactly the same
      }

      # Add context labels to non-empty parameters
      if (nzchar(data_background)) data_background <- paste("Here is the data background:", data_background)
      if (nzchar(policy_question)) policy_question <- paste("I need help answering a specific policymaking/decision-making question:", policy_question)

      # Construct the system message that tells the AI what role to play
      system_message <- paste(
        "You are a policy analyst/data scientist assisting in interpreting the data.",
        data_background, policy_question,                              # Include user's context
        "Focus on synthesizing the data results and providing insights across results,",
        "backing up every interpretation with clear evidence and rationale.",
        "Make sure any numbers you repeat exactly match those provided.",
        "Provide a strong summary at the end."
      )
      # paste() with multiple arguments joins them with spaces

      # Prepare the prompt text, truncating if it's too long
      prompt_text <- {
        text <- self$ai_prompt                                    # Get the current AI prompt
        if (nchar(text, type = "bytes") > self$max_chars) substr(text, 1L, self$max_chars) else text
        # nchar() with type="bytes" counts actual bytes (important for non-ASCII characters)
        # substr() extracts substring from position 1 to max_chars
        # The {} block allows us to do multiple operations and return the last result
      }

      # Call the Ollama API to generate a response
      model_output <- self$call_ollama(model_name, system_message, prompt_text, stream = TRUE)

      # Start assembling disclaimer and final interpretation
      header <- paste(
        "----- Disclaimer: This interpretation was produced by a local LLM via Ollama and may contain errors.",
        "Verify with a domain expert before making decisions. This is a fast, first-pass interpretation.",
        "-----\n\n## AI Policy Advisor\n"
      )

      # Combine header and model output
      response <- paste0(header, model_output)

      # Prefer writing a Word document if 'officer' is available; otherwise fallback to Markdown
      if (requireNamespace("officer", quietly = TRUE)) {
        doc <- officer::read_docx()
        # Split on newlines and add each as a paragraph to preserve formatting in Word
        for (line in strsplit(response, "\n", fixed = TRUE)[[1]]) {
          officer::body_add_par(doc, value = line, style = "Normal")
        }
        print(doc, target = "ai_interpretation.docx")
      } else {
      writeLines(response, "ai_interpretation.md")
      }

      # clear the AI prompt for next run
      self$ai_prompt <- ""
      response
    },

    call_ollama = function(model, system_message, user_prompt, stream = TRUE) {
      url <- "http://localhost:11434/api/generate"                    # Ollama API endpoint (local server)

      # Prepare the request data for the API call
      request_data <- list(
        model  = model,                                              # Which AI model to use
        prompt = paste0(system_message, "\n\nUser data: ", user_prompt),  # Combine system + user prompts
        stream = isTRUE(stream)                                      # Whether to stream response (real-time)
        # isTRUE() converts any value to TRUE/FALSE (safer than just stream)
      )

      # Try streaming response if curl package is available
      if (isTRUE(stream) && requireNamespace("curl", quietly = TRUE)) {
        # requireNamespace() checks if a package is installed, quietly=TRUE means no error if missing
        
        full_response <- ""                                           # Will accumulate the complete response
        handle <- curl::new_handle()                                  # Create a new curl connection handle
        curl::handle_setheaders(handle, "Content-Type" = "application/json")  # Set HTTP headers
        curl::handle_setopt(handle, postfields = jsonlite::toJSON(request_data, auto_unbox = TRUE))
        # jsonlite::toJSON() converts R list to JSON string, auto_unbox=TRUE removes unnecessary brackets

        cat("🤖 AI Response (may take a few minutes for AI to think):\n", strrep("-", 50), "\n", sep = "")  # Display header
        # Define callback function that processes each chunk of streaming data
        callback <- function(data) {
          for (line in strsplit(rawToChar(data), "\n", fixed = TRUE)[[1]]) {
            # the cur response is in raw bytes, so we need to convert it to characters
            # rawToChar() converts raw bytes to character, strsplit() splits by newlines
            # [[1]] gets first element (strsplit returns a list)
            
            if (!nzchar(line)) next                                  # Skip empty lines
            object <- try(jsonlite::fromJSON(line), silent = TRUE)    # Parse JSON line
            # try() attempts to run code, returns error object if it fails
            
            if (!inherits(object, "try-error") && !is.null(object$response)) {
              # Check if parsing succeeded and response field exists
              token <- object$response                                # Extract the text token
              full_response <<- paste0(full_response, token)          # Accumulate response
              # <<- assigns to variable in parent scope (not just local scope)
              cat(token); flush.console()                             # Display token immediately
            }
          }
          TRUE                                                       # Return TRUE to continue streaming
        }

        # Execute the streaming request
        result <- try(curl::curl_fetch_stream(url, callback, handle = handle), silent = TRUE)
        # curl::curl_fetch_stream() starts streaming HTTP request, calls callback for each chunk
        
        if (inherits(result, "try-error")) stop("Error connecting to Ollama (streaming). Is 'ollama serve' running?")
        # Check if streaming failed
        
        cat("\n", strrep("-", 50), "\n", sep = "")                    # Display footer
        return(full_response)                                          # Return complete response
      }

      # Non-streaming fallback (when curl package is not available)
      request_data$stream <- FALSE                                    # Disable streaming
      response <- httr::POST(url, body = request_data, encode = "json", httr::timeout(420))
      # httr::POST() makes HTTP POST request, timeout=420 sets 7 minute timeout
      
      if (httr::status_code(response) != 200L) {                      # Check if request succeeded
        # HTTP 200 means success, anything else is an error
        response_body <- tryCatch(httr::content(response, as = "text", encoding = "UTF-8"), error = function(...) "")
        # httr::content() extracts response body, tryCatch() handles errors gracefully
        stop(paste0("Ollama API failed (HTTP ", httr::status_code(response), "). ", if (nzchar(response_body)) paste0("Body: ", response_body)))
      }
      
      # Parse the JSON response and extract the AI's text
      parsed_response <- jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"))
      parsed_response$response %||% ""                                # Return response text or empty string
    },

    # ---- Helper Methods ----------------------------------------------------------
    # These are "private" methods (note the dot prefix) - they can only be called from inside the class

    .is_model_or_test = function(object) {
      # Check if object is a statistical model or test
      inherits(object, "htest") ||                                    # Base R hypothesis test objects
        (requireNamespace("insight", quietly = TRUE) && insight::is_model(object)) ||  # Use insight package if available
        self$.has_s3("summary", object)                               # Check if object has summary method
    },

    .has_s3 = function(generic, object) {
      classes <- class(object)
      any(vapply(classes, function(cls) isS3method(f = generic, class = cls), logical(1)))
    },

    .render_stat = function(object) {
      # Render statistical objects (models, tests) in a readable format
      printer <- function() paste(utils::capture.output(print(object)), collapse = "\n")
      # Define function that captures printed output and joins with newlines
      
      # Try to use withr package for better formatting, fallback to basic printing
      text <- if (requireNamespace("withr", quietly = TRUE)) {
        withr::with_options(list(width = 1000L), printer())            # Temporarily set console width to 1000
      } else printer()

      # Try to use broom package for standardized statistical output
      if (requireNamespace("broom", quietly = TRUE)) {
        glance_result <- try(broom::glance(object), silent = TRUE)     # Get model fit statistics (R², AIC, etc.)
        tidy_result <- try(broom::tidy(object),   silent = TRUE)      # Get coefficients table (estimates, p-values, etc.)

        parts <- character()                                           # Initialize empty character vector
        if (!inherits(tidy_result, "try-error")) {
          # If broom::tidy() succeeded, add coefficient table
          parts <- c(parts, paste0("\nTidy:\n",
            paste(utils::capture.output(print(tidy_result)), collapse = "\n")))
        }
        if (!inherits(glance_result, "try-error")) {
          # If broom::glance() succeeded, add model fit statistics
          parts <- c(parts, paste0("\nGlance:\n",
            paste(utils::capture.output(print(glance_result)), collapse = "\n")))
        }
        if (length(parts)) return(paste0(text, paste(parts, collapse = "")))
        # If we got any broom output, combine it with the original text
      }

      # Fallback: if broom failed, try object's own summary method
      if (self$.has_s3("summary", object)) {
        summary_printer <- function() paste(utils::capture.output(summary(object)), collapse = "\n")
        summary_text <- if (requireNamespace("withr", quietly = TRUE)) {
          withr::with_options(list(width = 1000L), summary_printer())   # Use withr for better formatting
        } else summary_printer()
        
        return(paste0(text, "\n\nSummary:\n", summary_text))          # Combine original + summary
      }

      text                                                              # Return just the original text if nothing else worked
    },

    .render_table = function(object) {
      # Render tables, matrices, and data frames in a readable format
      printer <- function() paste(utils::capture.output(print(object)), collapse = "\n")
      if (requireNamespace("withr", quietly = TRUE)) {
        withr::with_options(list(width = 1000L), printer())            # Use withr for better formatting
      } else printer()
    },

    .render_list = function(object) {
      # Render lists and nested structures
      tryCatch(
        # First try: convert to pretty JSON (most readable for complex structures)
        as.character(jsonlite::toJSON(object, pretty = TRUE, auto_unbox = TRUE)),
        # pretty=TRUE adds formatting, auto_unbox=TRUE removes unnecessary brackets
        
        error = function(error) {
          # If JSON fails, fallback to str() output
          printer <- function() paste(utils::capture.output(str(object)), collapse = "\n")
          # str() shows object structure in a compact way
          if (requireNamespace("withr", quietly = TRUE)) {
            withr::with_options(list(width = 1000L), printer())        # Use withr for better formatting
          } else printer()
        }
      )
    }
  )
)

# Internal null-coalescing operator (custom infix operator)
# This is like the ?? operator in other languages - returns first value if it's not null/empty, otherwise second value
`%||%` <- function(first_value, second_value) if (!is.null(first_value) && length(first_value) > 0) first_value else second_value
# %...% syntax creates a custom infix operator in R
# !is.null() checks if value is not NULL
# length() > 0 checks if vector/string is not empty