#' @keywords internal

AIPolicyAdvisor <- R6::R6Class(
  "AIPolicyAdvisor",
  public = list(
    ai_prompt = "",
    MAX_CHARS = 32000L,

    initialize = function() {
      self$ai_prompt <- ""
    },
# Append arbitrary results to the running AI prompt buffer as plain text.
# - Supports "atomic" vectors (character/logical/numeric/integer/factor),
#   "rectangular" objects (data.frame/matrix/table), and nested lists.
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

    read_file_for_ai = function(file_path) {
      if (!file.exists(file_path)) stop(sprintf("File not found: %s", file_path))
      ext <- tolower(tools::file_ext(file_path))
      if (identical(ext, "csv")) {
        df <- utils::read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)
        string <- paste(utils::capture.output(print(df)), collapse = "\n")
        self$ai_prompt <- paste0(self$ai_prompt, string, "\n")
        return(string)
      } else if (identical(ext, "md")) {
        txt <- paste(readLines(file_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
        self$ai_prompt <- paste0(self$ai_prompt, txt, "\n")
        return(txt)
      }
      stop("Invalid file type. Use .csv or .md.")
    },

    ai_policy_advisor = function(config = list()) {
      req <- c("data_background", "policy_question", "model")
      miss <- setdiff(req, names(config))
      if (length(miss)) stop(sprintf("Missing required keys: %s", paste(miss, collapse = ", ")))

      if (!nzchar(self$ai_prompt)) stop("Prompt is empty. Call add_to_ai_prompt(...) first.")

      data_background <- as.character(config[["data_background"]] %||% "")
      policy_question <- as.character(config[["policy_question"]] %||% "")
      model_name      <- as.character(config[["model"]] %||% "")
      if (!nzchar(model_name) || identical(model_name, "<ENTER YOUR MODEL HERE>")) {
        stop("Please set a valid model name in CONFIG$model (e.g., 'qwen3:14b').")
      }

      if (nzchar(data_background)) data_background <- paste("Here is the data background:", data_background)
      if (nzchar(policy_question)) policy_question <- paste("I need help answering a specific policymaking/decision-making question:", policy_question)

      system_message <- paste(
        "You are a policy analyst/data scientist assisting in interpreting the data.",
        data_background, policy_question,
        "Focus on synthesizing the data results and providing insights across results,",
        "backing up every interpretation with clear evidence and rationale.",
        "Make sure any numbers you repeat exactly match those provided.",
        "Provide a strong summary at the end."
      )

      user_blob <- {
        blob <- self$ai_prompt
        if (nchar(blob, type = "bytes") > self$max_chars) substr(blob, 1L, self$max_chars) else blob
      }

      out <- self$call_ollama(model_name, system_message, user_blob, stream = TRUE)

      header <- paste(
        "----- Disclaimer: This interpretation was produced by a local LLM via Ollama and may contain errors.",
        "Verify with a domain expert before making decisions. This is a fast, first-pass interpretation.",
        "-----\n\n## AI Policy Advisor\n"
      )
      res <- paste0(header, out)
      writeLines(res, "ai_interpretation.md")
      self$ai_prompt <- ""  # clear like Python
      res
    },

    call_ollama = function(model, system_message, user_prompt, stream = TRUE) {
      url <- "http://localhost:11434/api/generate"
      payload <- list(
        model  = model,
        prompt = paste0(system_message, "\n\nUser data: ", user_prompt),
        stream = isTRUE(stream)
      )

      if (isTRUE(stream) && requireNamespace("curl", quietly = TRUE)) {
        full <- ""
        h <- curl::new_handle()
        curl::handle_setheaders(h, "Content-Type" = "application/json")
        curl::handle_setopt(h, postfields = jsonlite::toJSON(payload, auto_unbox = TRUE))
        cat("🤖 AI Response (streaming):\n", strrep("-", 50), "\n", sep = "")
        cb <- function(data) {
          for (ln in strsplit(rawToChar(data), "\n", fixed = TRUE)[[1]]) {
            if (!nzchar(ln)) next
            obj <- try(jsonlite::fromJSON(ln), silent = TRUE)
            if (!inherits(obj, "try-error") && !is.null(obj$response)) {
              token <- obj$response
              full <<- paste0(full, token)
              cat(token); flush.console()
            }
          }
          TRUE
        }
        res <- try(curl::curl_fetch_stream(url, cb, handle = h), silent = TRUE)
        if (inherits(res, "try-error")) stop("Error connecting to Ollama (streaming). Is 'ollama serve' running?")
        cat("\n", strrep("-", 50), "\n", sep = "")
        return(full)
      }

      resp <- httr::POST(url, body = payload, encode = "json", httr::timeout(420))
      if (httr::status_code(resp) != 200L) {
        body <- tryCatch(httr::content(resp, as = "text", encoding = "UTF-8"), error = function(...) "")
        stop(paste0("Ollama API failed (HTTP ", httr::status_code(resp), "). ", if (nzchar(body)) paste0("Body: ", body)))
      }
      parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
      parsed$response %||% ""
    }
  )
)

# internal null-coalescing
`%||%` <- function(a, b) if (!is.null(a)) a else b