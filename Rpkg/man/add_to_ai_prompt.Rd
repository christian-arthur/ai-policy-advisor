\name{add_to_ai_prompt}
\alias{add_to_ai_prompt}
\title{Add to AI Prompt}
\description{
Add results to the AI prompt for later processing.
}
\usage{
add_to_ai_prompt(results, context = "")
}
\arguments{
\item{results}{The results to add (vectors, data frames, lists, etc.)}
\item{context}{Optional context string to prepend to results}
}
\value{
The original results (for chaining)
}
\examples{
\dontrun{
add_to_ai_prompt(my_data, "Sample data:")
}
}
