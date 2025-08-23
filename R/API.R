#' Add results to the AI prompt buffer
#' @param results Object to append (vector/list/data.frame/matrix/table)
#' @param context Optional label/header
#' @return The original results (invisible)
#' @export
add_to_ai_prompt <- function(results, context = "") {
  .pkgenv$advisor$add_to_ai_prompt(results, context)
}

#' Read a CSV or Markdown file into the AI prompt buffer
#' @param file_path Path to .csv or .md
#' @return Text content read
#' @export
read_file_for_ai <- function(file_path) {
  .pkgenv$advisor$read_file_for_ai(file_path)
}

#' Run the AI policy advisor using the accumulated prompt
#' @param config Named list: data_background, policy_question, model
#' @return Character; also writes 'ai_interpretation.md'
#' @export
ai_policy_advisor <- function(config = list()) {
  .pkgenv$advisor$ai_policy_advisor(config)
}

#' Set a defensive max prompt size (bytes)
#' @param n Positive integer
#' @export
set_ai_prompt_max_chars <- function(n) {
  stopifnot(is.numeric(n), length(n) == 1L, is.finite(n), n > 0)
  .pkgenv$advisor$max_chars <- as.integer(n)
  invisible(NULL)
}