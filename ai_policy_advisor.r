library(httr)
library(jsonlite)

# AI Policy Advisor R implementation
# This tool provides AI-assisted policy analysis using local Ollama models

ai_policy_advisor <- function(config) {
  # Validate config list exists
  if (is.null(config) || length(config) == 0) {
    stop("
❌ CONFIG LIST REQUIRED!

You must pass a config list. Add this at the top of your file:

CONFIG <- list(
  data_background = \"Brief description of what your data represents\",
  policy_question = \"What specific question are you trying to answer?\",
  model = \"Which Ollama model to use (e.g., 'qwen3:14b')\"
)

Then call: ai_policy_advisor(CONFIG)
    ")
  }
  
  # Validate required keys
  required_keys <- c("data_background", "policy_question", "model")
  missing_keys <- required_keys[!required_keys %in% names(config)]
  
  if (length(missing_keys) > 0) {
    stop(paste0("
❌ MISSING REQUIRED CONFIG KEYS: ", paste(missing_keys, collapse = ", "), "

Your config list must include all these keys:
", paste(required_keys, collapse = ", "), "

Current config: ", paste(names(config), collapse = ", "), "

Fix by adding the missing keys to your CONFIG list.
    "))
  }
  
  # Extract values from config
  data_background <- config$data_background
  policy_question <- config$policy_question
  model_name <- config$model
  
  # Check if the user has provided data background and policy question
  # and if not, provide a message to remind that doing so increases the AI helpfulness
  if (data_background == "") {
    cat("!!! For better results, provide some background about the data. Pass it as data_background parameter.\n\n")
  }
  if (policy_question == "") {
    cat("!!! If you want a specific policy or decision-making question answered, pass it as policy_question parameter.\n\n")
  }
  
  # Check if model is set
  if (model_name == "<ENTER YOUR MODEL HERE>") {
    stop("Please pass an AI model name as the model parameter. Make sure to set the model in the top of the file.")
  }
  
  # Check if the user has provided data background and policy question
  # and if so, then include them in the AI response with some additional 
  # language to make the prompt clearer.
  if(data_background != "") {
    data_background <- paste("Here is the data background: ", data_background)
  }
  if (policy_question != "") {
    policy_question <- paste("I need help answering a specific policymaking/decision-making question: ", policy_question)
  }

  # Prepare the system message
  system_message <- paste("You are a policy analyst/data scientist assisting in interpreting the data. ", 
                         data_background, policy_question, 
                         "Focus on synthesizing the data results and providing insights across results, backing up every interpretation with clear evidence and rationale. Make sure to double and triple check that any numbers you repeat accurately reflect the numbers specifically given to you in the prompt.",
                         "Provide a strong summary at the end.", sep = "")
  
  # Ollama API call with 7-minute timeout
  tryCatch({
    response <- POST(
      url = "http://localhost:11434/api/generate",
      body = list(
        model = model_name,
        prompt = paste(system_message, "\n\nUser data:", ai_prompt, sep = ""),
        stream = FALSE
      ),
      encode = "json",
      timeout(420)  # 7 minutes timeout
    )
    
    if (response$status_code == 200) {
      response_data <- fromJSON(rawToChar(response$content))
      ai_response <- response_data$response
    } else {
      stop("Ollama API request failed. Make sure Ollama is running and the model is available. You may be trying to pass too much information to the model at once. Try less.")
    }
  }, error = function(e) {
    stop("Error connecting to Ollama: ", e$message, "\nMake sure Ollama is running with: ollama serve")
  })
  
  # Define the disclaimer
  disclaimer <- "----- Disclaimer: This interpretation was produced by a Large Language Model running locally via Ollama, which generates answers based on the text it was trained on. Therefore the answers may contain errors. It is important to verify the information with a domain expert before making any decisions. The AI Policy Advisor is meant to be a cheap, immediate, first-pass at interpreting data for policy and decision-making purposes. -----\n \n\n## AI Policy Advisor\n" 
  ai_interpretation <- paste(disclaimer, ai_response, sep = "")
  
  # Save the AI interpretation with the disclaimer as a markdown file
  writeLines(ai_interpretation, "ai_interpretation.md")
  
  # Clear the prompt after use
  ai_prompt <<- ""
  
  # Return the interpretation
  return(ai_interpretation)
}

# Global variable to store the AI prompt
ai_prompt <- ""

# Function to add results to the AI prompt for later querying
add_to_ai_prompt <- function(results = NULL, context = "") {
  if (is.null(results)) {
    # Try to auto-capture based on environment
    captured_output <- capture_last_output()
    if (captured_output != "") {
      ai_prompt <<- paste0(ai_prompt, captured_output, "\n")
    }
    return(captured_output)
  } else {
    # Existing logic for when results are passed
    if (is.vector(results) || is.factor(results) || is.logical(results)) {
      # Convert results to a string using paste
      results_string <- paste(results, collapse = " ")
      # Add context if provided
      if (context != "") {
        results_string <- paste(context, results_string)
      }
      # Append results_string to the global variable ai_prompt
      ai_prompt <<- paste0(ai_prompt, results_string, "\n")
    } else if (is.list(results) || is.matrix(results) || is.data.frame(results) || is.table(results)) {
      # Convert results to a string using capture.output
      results_string <- paste(capture.output(print(results)), collapse = "\n")
      # Add context if provided
      if (context != "") {
        results_string <- paste(context, "\n", results_string, sep = "")
      }
      # Append results_string to the global variable ai_prompt
      ai_prompt <<- paste0(ai_prompt, results_string, "\n")
    } else {
      stop("Invalid data type. Please use a vector (including single strings, datetime, or factor. List, matrix, data frame, or table are also supported but in development.")
    }
    # Return the original results for chaining
    return(results)
  }
}

# Function to capture the last output from R's history
# In practice, users will need to explicitly pass results or use context
capture_last_output <- function() {
  # For now, return empty string as R doesn't have built-in output capture
  # Users can still use add_to_ai_prompt() with explicit results
  return("")
}

# Function to read CSV or markdown files and add their content to the AI prompt
read_file_for_ai <- function(file_path) {
  tryCatch({
    # Check if the file is a CSV file
    if (grepl("\\.csv$", file_path)) {
      # Read the CSV file using read.csv
      df <- read.csv(file_path)
      # Add the CSV content to the AI prompt
      ai_prompt <<- paste0(ai_prompt, paste(capture.output(print(df)), collapse = "\n"), "\n")
      return(paste(capture.output(print(df)), collapse = "\n"))
    } else if (grepl("\\.md$", file_path)) {
      # Read the markdown file
      lines <- readLines(file_path)
      # Concatenate the lines into a single string
      text <- paste(lines, collapse = "\n")
      ai_prompt <<- paste0(ai_prompt, text, "\n")
      # Return the text
      return(text)
    } else {
      stop("Invalid file type. Please use a CSV or markdown file.")
    }
  }, error = function(e) {
    if (grepl("cannot open", e$message)) {
      stop("File not found: ", file_path)
    } else {
      stop("Error reading file: ", e$message)
    }
  })
}