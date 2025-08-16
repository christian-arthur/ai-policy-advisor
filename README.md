# README for ai_policy_advisor

## Overview
The `ai_policy_advisor` scripts (available in both R and Python) are tools designed to assist epidemiologists in interpreting and applying data to public health decision-making. The code uses [Ollama](https://ollama.ai/) to run large language models locally, providing a secure, private, and cost-effective way to get AI assistance without sending data to external services.

`ai_policy_advisor` innovates by...
1. Integrating LLM intelligence and reasoning directly into the epidemiologist's workflow, versus copy and pasting into a separate chat window 
2. Employing prompt engineering to improve the quality of the AI interpretation and recommendation.
3. Posting the AI's response to a document, for easy reading and sharing
4. Running completely locally for data privacy and security, using Ollama 

The script is intended to provide an automated, fast, and cost-effective first pass at interpreting data and informing policymaking. It is not intended to replace human involvement, but rather enhance and improve existing decision-making processes. 

## Disclaimer

[Large Language Models](https://www.wired.com/story/how-chatgpt-works-large-language-model/) use statistics to generate text, as predicted by the data they were "trained" on, mostly writing scraped from the internet. LLMs may hallucinate in ways that sound convincing but are factually incorrect or illogical. Scientists continue to explore whether these AI can truly understand or reason, or whether they're blindly [parroting](https://en.wikipedia.org/wiki/Stochastic_parrot) training data. 

Yet, [cities are experimenting](https://bloombergcities.jhu.edu/news/cities-are-ramping-make-most-generative-ai#:~:text=According%20to%20the%20recent%20survey,or%20generate%2C%20new%20content%20after) with LLMs to improve municipal functions, such as [Boston, MA](https://www.fastcompany.com/90983427/chatgpt-generative-ai-government-reform-biden-garces-boston-goldsmith-harvard). LLMs and artificial intelligence have the potential to [improve decision-making](https://napawash.org/standing-panel-blog/decision-making-and-ai-in-public-service), leveraging a deep reservoir of human knowledge, efficiently synthesizing pieces of information, and articulating clear summaries.

[City of Boston generative AI policy](https://www.boston.gov/sites/default/files/file/2023/05/Guidelines-for-Using-Generative-AI-2023.pdf) recommends the human user review and fact-check any answers produced by an LLM, in order to address any potential hallucinations or bias. 

## Prerequisites

### Installing Ollama
Ollama is a platform for running open source Large Language Models on your local deivice. They are secure and do not expose the epidemiological data to AI providers like OpenAI or Google. 

You need to install Ollama to run the AI models locally. Visit [ollama.ai](https://ollama.ai/) and follow the installation instructions for your operating system, including booting up the Ollama server manually for the first time. 

After installation, you'll need to pull a model. There are a variety of good models available, specializing in critical thinking and math. Some models are reasoning models, which combine LLM with architecture to chain thought and reason logically. Different-sized models have different RAM requirements, so double check your computer is capable of running your preferred model.

16GB Recommendation - In August 2025 [OpenAI](https://openai.com/index/introducing-gpt-oss/) open-sourced a reasoning model which is highly performant, [gpt-oss:20b](https://ollama.com/library/gpt-oss:20b). It can run on devices with 16GB of RAM. 

```bash
ollama pull gpt-oss:20b
```

8GB Recommendation – Google offers an excellent model, Gemma 3, released in August 2025. The [4B parameter model](https://ollama.com/library/gemma3:4b) shoudl run on an device with 8GB of RAM. 

```bash
ollama pull gemma3:4b
```

### Installing Dependencies

#### For R users:
```r
install.packages(c("httr", "jsonlite"))
```

#### For Python users:
```bash
pip install -r requirements.txt
```

## How to Use `ai_policy_advisor`

### Importing the Script

#### In R:
```r
source("path/to/ai_policy_advisor.R")
```

#### In Python:
```python
from ai_policy_advisor import ai_policy_advisor, add_to_ai_prompt, read_markdown_for_ai
```

Replace the path with the true path to the file. If your working directory is the ai_policy_advisor project folder, then the path would be "ai_policy_advisor.R" or "ai_policy_advisor.py".

### Compiling Results with `add_to_ai_prompt`
The `add_to_ai_prompt` function is used to compile multiple results in preparation for prompting the AI. It accepts multiple datatypes, which it appends to the global `ai_prompt` variable.

```r
# R
add_to_ai_prompt(results)

# Python
add_to_ai_prompt(results)
```

For better results, pass additional context to the function, so the AI has more information to incorporate into its interpretation.

```r
# R
add_to_ai_prompt(paste("Context about your results", results))

# Python
add_to_ai_prompt(results, context="Context about your results")
```

Supported datatypes:
- Good support: strings and other vectors
- Partial support (but in development so watch out for bugs): list, matrix, dataframe, table
- Not supported: other datatypes  

This implementation is aiming to fit seamlessly with the epidemiologist's existing workflow and coding experience. For example, when using the function `cat` or `print` to output results, the user can wrap the results first with `add_to_ai_prompt`. Doing so aggregates the results alongside others from the analysis, preparing to prompt the AI, but avoids disrupting the usual workflow with a substantial amount of additional code.

### Preparing a Markdown File with read_markdown_for_ai
The epidemiologist may want to prompt the AI with text from an existing markdown file. The `read_markdown_for_ai` function reads a markdown file and prepares it for the `ai_policy_advisor` function:

```r
# R
read_markdown_for_ai("path/to/markdown.md")

# Python
read_markdown_for_ai("path/to/markdown.md")
```

### Specifying the Data Background and Policy Question
The `ai_policy_advisor` function can also accept two optional parameters: `data_background` and `policy_question`. These parameters provide more context to the AI, which can improve the quality of its responses.

- `data_background` should be a string that provides some background information about the data you're analyzing. For example, associated determinants, environmental factors, or implementation details.
- `policy_question` should be a string that poses a specific policy or decision-making question that you want the AI to help answer.

Here's an example of how to specify these parameters:
```r
# R
data_background <- "Description of the data"
policy_question <- "What policy should be implemented?"

# Python
data_background = "Description of the data"
policy_question = "What policy should be implemented?"
```

### Running the `ai_policy_advisor` Function
Finally, you can run the `ai_policy_advisor` function to prompt the AI and write its response to a markdown file:

```r
# R
ai_policy_advisor(ai_prompt, data_background, policy_question)

# Python
ai_policy_advisor(ai_prompt, data_background, policy_question)
```

This function accepts three parameters:
- `ai_prompt`: The string containing the prompt for the AI. This should be compiled using the `add_to_ai_prompt` and `read_markdown_for_ai` functions.
- `data_background`: A string providing some background information about the data. This is optional but recommended.
- `policy_question`: A string posing a specific policy or decision-making question. This is also optional but recommended.

The function prompts the AI and writes its response to a markdown file in the project folder called `ai_interpretation.md`.

### Customizing the AI Model
You can specify which Ollama model to use by passing the `model` parameter:

```r
# R
ai_policy_advisor(ai_prompt, model = "llama3.1:8b")

# Python
ai_policy_advisor(ai_prompt, model="llama3.1:8b")
```

## Benefits of Local AI Processing

1. **Data Privacy**: Your data never leaves your machine
2. **Cost Effective**: No API costs or usage limits
3. **Offline Capability**: Works without internet connection
4. **Customizable**: Use any model available in Ollama
5. **Secure**: No data transmission to external services

## Troubleshooting

### Ollama Connection Issues
If you get connection errors, make sure:
1. Ollama is installed and running
2. The model you specified is available (check with `ollama list`)
3. Ollama is accessible at `http://localhost:11434`

### Model Performance
- Smaller models (like `gemma2:2b`) are faster but may be less accurate
- Larger models (like `llama3.1:8b`) are more accurate but slower
- Choose based on your balance of speed vs. quality needs
