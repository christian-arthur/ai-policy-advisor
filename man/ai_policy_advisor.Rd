\name{ai_policy_advisor}
\alias{ai_policy_advisor}
\title{AI Policy Advisor}
\description{
Get AI interpretation of data using local Ollama models.
}
\usage{
ai_policy_advisor(config)
}
\arguments{
\item{config}{List with required keys: data_background, policy_question, model}
}
\value{
String containing the AI interpretation
}
\examples{
\dontrun{
CONFIG <- list(
  data_background = "Your data description",
  policy_question = "Your question",
  model = "qwen3:14b"
)
ai_policy_advisor(CONFIG)
}
}
