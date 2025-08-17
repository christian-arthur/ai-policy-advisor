# AI Policy Advisor

## Table of Contents
- [AI Policy Advisor](#ai-policy-advisor)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Disclaimer](#disclaimer)
  - [Ollama Prerequisite](#ollama-prerequisite)
    - [Installing Ollama](#installing-ollama)
    - [Guide for Chooosing an Ollama LLM Model](#guide-for-chooosing-an-ollama-llm-model)
  - [How the AI Policy Advisor Works](#how-the-ai-policy-advisor-works)
  - [Installing and Using the Tool](#installing-and-using-the-tool)
    - [Python Module](#python-module)
    - [R Package](#r-package)
  - [Open Source Contributors Welcome!](#open-source-contributors-welcome)
  - [Intellectual Property License](#intellectual-property-license)

## Overview
The `ai_policy_advisor` is a Python package (with an R version available) designed to assist epidemiologists and data scientists in interpreting data for public health decision-making. The tool uses [Ollama](https://ollama.ai/) to run large language models locally, providing a secure, private, and cost-effective way to get AI assistance without sending data to external services.

`ai_policy_advisor` innovates by...
1. Integrating LLM intelligence and reasoning directly into the epidemiologist's workflow, versus copy and pasting into a separate chat window 
2. Running completely locally for data privacy and security, a key feature requested by epidemiologists 
3. Employing prompt engineering to improve the quality of the AI interpretation and recommendation.
4. Posting the AI's response to a document, for easy reading and sharing

The tool provides an automated, fast, and cost-effective first pass at interpreting data and informing policymaking. It's designed to enhance existing decision-making processes, not replace human expertise.

## Disclaimer
[Large Language Models](https://www.wired.com/story/how-chatgpt-works-large-language-model/) use statistics to generate 
text, as predicted by the data they were "trained" on, mostly writing scraped from the internet. LLMs may hallucinate in 
ways that sound convincing but are factually incorrect or illogical. Scientists continue to explore whether these AI can 
truly understand or reason, or whether they're blindly [parroting](https://en.wikipedia.org/wiki/Stochastic_parrot) 
training data. 

Yet, [cities are experimenting](https://bloombergcities.jhu.edu/news/cities-are-ramping-make-most-generative-ai#:~:text=According%20to%20the%20recent%20surveyor%20generate%2C%20new%20content%20after) with LLMs to improve municipal functions, such as [Boston, MA](https://www.fastcompany.com/90983427/chatgpt-generative-ai-government-reform-biden-garces-boston-goldsmith-harvard). LLMs and artificial intelligence have the potential to [improve decision-making](https://napawashorgstanding-panel-blogdecision-making-and-ai-in-public-service), leveraging a deep reservoir of human knowledge, efficiently synthesizing pieces of information, and articulating clear summaries.

## Ollama Prerequisite

Ollama runs open-source Large Language Models (LLM) locally on your device. Your data stays secure and won't get sent to external AI providers like OpenAI or Google. Using an API with those companies would grant access to the smartest AI in the world, but at the cost of exposing data (and also fees!). Even smaller open source models are capable of college or professional-level analysis and [intelligence](https://artificialanalysis.ai/models/open-source/small). 

### Installing Ollama

1. Visit [ollama.ai](https://ollama.ai/) and install Ollama for your operating system
2. Start the Ollama server
3. Pull a model. Find options [here](https://ollama.com/search)

### Guide for Chooosing an Ollama LLM Model

Running an LLM on you local device is compute-intensive, so older computers or devices with cheaper hardware will struggle to accomodate larger LLMs. The larger the model parameters, the more compute resources needed. Most computers these days have 16GB of RAM, with cheaper devices often having 8GB, and more powerful devices boasting over 16GB (i.e. 24 or 32GB). 

[Artificial Analysis](https://artificialanalysis.ai/models/open-source/small) compares small LLM models and their performance on evaluations. Here are some recommendations based on different levels of computer hardware (as of August 2025 model releases).

**Over 16GB Recommendation**  

In August 2025 [OpenAI](https://openai.com/index/introducing-gpt-oss/) open-sourced a reasoning model which is highly performant, [gpt-oss:20b](https://ollama.com/library/gpt-oss:20b). It barely runs on 16GB (not practical) but should be more comfortable at 24GB and **maybe** 18GB of RAM. gpt-oss:20b is a [reasoning model](https://en.wikipedia.org/wiki/Reasoning_language_model), which means it uses additional architecture to reason towards better answers. Run the following command in your terminal to download the model:

```bash
ollama pull gpt-oss:20b
```

**For 16GB RAM:**  

Chinese company Alibaba trained the model Qwen3, which comes in both 14 and 8 billion parameter versions. They're both reasoning models, capable of strong analysis, clear writing, math, outputting tables, etc. The 14B model will approach the limits of a 16GB RAM device, so make sure to minimize running other applications or computer-intensive operations concurrently with the model. Having an IDE and web browser open concurrently has tested fine. Alternatively, the 8B model is only a little dumber, but allows for more headspace to run other applications and analyses. Download:

```bash
ollama pull qwen3:14b
```

```bash
ollama pull qwen3:8b
```

**Lightweight option:**  

Google offers a smaller but still perfomant model worth sending data and policy questions for an additional perspective. [Gemma3](https://ollama.com/library/gemma3) is available in a 4 billion parameter version. Download:

```bash
ollama pull gemma3:4b
```

## How the AI Policy Advisor Works

The AI Policy Advisor exists in both Python module and R package forms, catering to different epidemiologist and data scientist coding paradigms. But the principles of the tool remain the same across the different implentations. 

One function wraps text, tables, and various datatypes and automatically aggregates them into an AI prompt. Another function then makes a call to the local LLM model. 

In advance of calling the LLM, the user must configure the function, providing background context, a policy question, and specifying the Ollama model they want to use. 

## Installing and Using the Tool

### Python Module

**Installing the module from Github** 

```bash
pip install git+https://github.com/christian-arthur/ai-policy-advisor.git
```

**Using the tool in Python** 

```python
from ai_policy_advisor import add_to_ai_prompt, ai_policy_advisor

# Configure your analysis
CONFIG = {
    "data_background": "Write the data background here",
    "policy_question": "Write the policy question here",
    "model": "qwen3:14b"
}

# Add your analysis results
add_to_ai_prompt(my_dataframe, "Guest demographics data:")
add_to_ai_prompt(summary_stats, "Statistical summary:")

# Get AI interpretation
ai_policy_advisor(CONFIG)
```

**Adding Data to AI Prompt**  

The `add_to_ai_prompt` function compiles multiple results for AI analysis:

```python
# Basic usage
add_to_ai_prompt(results)

# With context (recommended)
add_to_ai_prompt(results, context="Description of this data")

# Supported data types
add_to_ai_prompt(dataframe)           # pandas DataFrames
add_to_ai_prompt(series)              # pandas Series  
add_to_ai_prompt(dictionary)          # Python dictionaries
add_to_ai_prompt(list_data)           # Lists and arrays
add_to_ai_prompt("text results")      # Strings
```

**Configuration Dictionary**  

All settings are passed via a single config dictionary. You must include this in your file. All three fields are REQUIRED.

```python
CONFIG = {
    "data_background": "Brief description of your data and context",
    "policy_question": "Specific question you want answered", 
    "model": "ollama_model_name"
}

```

**Reading Markdown Files**

An extra function that allows you to read an external markdown file and add it to your AI prompt.

```python
from ai_policy_advisor import read_markdown_for_ai

read_markdown_for_ai("background_info.md")
ai_policy_advisor(CONFIG)
```

### R Package

**Install the package from GitHub** 

```r
install.packages("devtools")
devtools::install_github("christian-arthur/ai-policy-advisor")
```

**Using the tool in R** 

```r
library(aipolicyadvisor)

CONFIG <- list(
  data_background = "Your data description",
  policy_question = "Your question",
  model = "qwen3:14b"
)

add_to_ai_prompt(results, "context")
ai_policy_advisor(CONFIG)
```

## Open Source Contributors Welcome!

This project is open source under the GNU AFFERO license. Contributions welcome! Feel free to make the tool easier to use and integrate into workflow, or correct any bugs.

## Intellectual Property License

GNU AFFERO General Public License - see LICENSE file for details.