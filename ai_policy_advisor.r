library(httr)
library(jsonlite)

# Make sure to change this to the model you want to use
ollama_model <- "<ENTER YOUR MODEL HERE>"

ai_policy_advisor <- function(ai_prompt = "", data_background = "", policy_question = "", model = ollama_model) {
  # Defaults to Ollama mode which runs locally
  # If the user has not provided any prompt, return an error message
  if (ai_prompt == "") {
    stop("Please provide a prompt to the ai_policy_advisor function.")
  }
  
  # Check if the user has provided data background and policy question
  # and if not, provide a message to remind that doing so increases the AI helpfulness
  if (data_background == "") {
    cat("!!! For better results, provide some background about the data. Assign the string to a variable and pass it to the ai_policy_advisor function with the format ai_policy_advisor(ai_prompt, data_background=your_background_variable, policy_question=policy_variable). \n\n")
  }
  if (policy_question == "") {
    cat("!!! If you want a specific policy or decision-making question answered, assign the string to a variable and pass it to the ai_policy_advisor function like ai_policy_advisor(ai_prompt, data_background=background_variable, policy_question=policy_variable)). \n\n")
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

  # Check if model is set
  if (model == "<ENTER YOUR MODEL HERE>") {
    stop("Please pass an AI model name as the model parameter. Make sure to set the model in the top of the file.")
  }

  # Prepare the system message
  system_message <- paste("You are a policy analyst/data scientist assisting in interpreting the data. ", 
                         data_background, policy_question, 
                         "Focus on synthesizing the data results and providing insights across results, backing up every interpretation with clear evidence and rationale. Make sure to double and triple check that any numbers you repeat accurately reflect the numbers specifically given to you in the prompt.",
                         "Provide a strong summary at the end.", sep = "")
  
  # Ollama API call
  tryCatch({
    response <- POST(
      url = "http://localhost:11434/api/generate",
      body = list(
        model = model,
        prompt = paste(system_message, "\n\nUser data:", ai_prompt, sep = ""),
        stream = FALSE
      ),
      encode = "json"
    )
    
    if (response$status_code == 200) {
      response_data <- fromJSON(rawToChar(response$content))
      ai_response <- response_data$response
    } else {
      stop("Ollama API request failed. Make sure Ollama is running and the model is available.")
    }
  }, error = function(e) {
    stop("Error connecting to Ollama: ", e$message, "\nMake sure Ollama is running with: ollama serve")
  })
  
  # Define the disclaimer
  disclaimer <- "----- Disclaimer: This interpretation was produced by a Large Language Model running locally via Ollama, which generates answers based on the text it was trained on. Therefore the answers may contain errors. It is important to verify the information with a domain expert before making any decisions. The AI Policy Advisor is meant to be a cheap, immediate, first-pass at interpreting data for policy and decision-making purposes. -----\n \n\n## AI Policy Advisor\n" 
  ai_interpretation <- paste(disclaimer, ai_response, sep = "")
  
  # Save the AI interpretation with the disclaimer as a markdown files
  writeLines(ai_interpretation, "ai_interpretation.md")
  ai_prompt <<- ""
  
  # Return the interpretation
  return(ai_interpretation)
}

ai_prompt <- ""
add_to_ai_prompt <- function(results = NULL) {
  if (is.vector(results) || is.factor(results) || is.logical(results)) {
    # Convert results to a string using paste
    results_string <- paste(results, collapse = " ")
    # Append results_string to the global variable ai_prompt
    ai_prompt <<- paste0(ai_prompt, results_string, "\n")
  } else if (is.list(results) || is.matrix(results) || is.data.frame(results) || is.table(results)) {
    # Convert results to a string using capture.output
    results_string <- paste(capture.output(print(results)), collapse = "\n")
    # Append results_string to the global variable ai_prompt
    ai_prompt <<- paste0(ai_prompt, results_string, "\n")
  } else {
    stop("Invalid data type. Please use a vector (including single strings, datetime, or factor. List, matrix, data frame, or table are also supported but in development.")
  }
  # Return the original results
  return(results)
}

read_markdown_for_ai <- function(file_path) {
  # Read the file
  lines <- readLines(file_path)
  # Concatenate the lines into a single string
  text <- paste(lines, collapse = "\n")
  ai_prompt <<- paste0(ai_prompt, text, "\n")
  # Return the text
  return(text)
}
