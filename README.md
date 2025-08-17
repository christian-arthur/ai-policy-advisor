# AI Policy Advisor

## Overview
The `ai_policy_advisor` is a Python package (with an R version available) designed to assist epidemiologists and data scientists in interpreting data for public health decision-making. The tool uses [Ollama](https://ollama.ai/) to run large language models locally, providing a secure, private, and cost-effective way to get AI assistance without sending data to external services.

`ai_policy_advisor` innovates by...
1. Integrating LLM intelligence and reasoning directly into the epidemiologist's workflow, versus copy and pasting into a separate chat window 
2. Employing prompt engineering to improve the quality of the AI interpretation and recommendation.
3. Posting the AI's response to a document, for easy reading and sharing
4. Running completely locally for data privacy and security, using Ollama 

The tool provides an automated, fast, and cost-effective first pass at interpreting data and informing policymaking. It's designed to enhance existing decision-making processes, not replace human expertise.

## Disclaimer
[Large Language Models](https://www.wired.com/story/how-chatgpt-works-large-language-model/) use statistics to generate 
text, as predicted by the data they were "trained" on, mostly writing scraped from the internet. LLMs may hallucinate in 
ways that sound convincing but are factually incorrect or illogical. Scientists continue to explore whether these AI can 
truly understand or reason, or whether they're blindly [parroting](https://en.wikipedia.org/wiki/Stochastic_parrot) 
training data. 

Yet, [cities are experimenting](https://bloombergcities.jhu.edu/news/
cities-are-ramping-make-most-generative-ai#:~:text=According%20to%20the%20recent%20survey,
or%20generate%2C%20new%20content%20after) with LLMs to improve municipal functions, such as [Boston, MA](https://www.
fastcompany.com/90983427/chatgpt-generative-ai-government-reform-biden-garces-boston-goldsmith-harvard). LLMs and 
artificial intelligence have the potential to [improve decision-making](https://napawash.org/standing-panel-blog/
decision-making-and-ai-in-public-service), leveraging a deep reservoir of human knowledge, efficiently synthesizing 
pieces of information, and articulating clear summaries.

## Installation

### Option 1: Install python module from GitHub (Recommended)
```bash
pip install git+https://github.com/christian-arthur/ai-policy-advisor.git
```

## Prerequisites

### Installing Ollama
Ollama runs open-source Large Language Models locally on your device. Your data stays secure and never gets sent to external AI providers.

1. Visit [ollama.ai](https://ollama.ai/) and install Ollama for your operating system
2. Start the Ollama server
3. Pull a recommended model:

Above 16GB Recommendation - In August 2025 [OpenAI](https://openai.com/index/introducing-gpt-oss/) open-sourced a reasoning model which is highly performant, [gpt-oss:20b](https://ollama.com/library/gpt-oss:20b). 

**For 16GB RAM:**
```bash
ollama pull qwen3:14b
```

**Lightweight option:**
```bash
ollama pull gemma3:4b
```

## Quick Start

### Python Version Basic Usage
```python
from ai_policy_advisor import add_to_ai_prompt, ai_policy_advisor

# Configure your analysis
CONFIG = {
    "data_background": "Write you background here",
    "policy_question": "Write yoru policy question here",
    "model": "qwen3:14b"
}

# Add your analysis results
add_to_ai_prompt(my_dataframe, "Guest demographics data:")
add_to_ai_prompt(summary_stats, "Statistical summary:")

# Get AI interpretation
ai_policy_advisor(CONFIG)
```

### Jupyter Notebook 
```python
# In Jupyter, you'll see AI responses stream in real-time
import pandas as pd
from ai_policy_advisor import add_to_ai_prompt as prompt, ai_policy_advisor as ai

# Configure
CONFIG = {
    "data_background": "Your data description",
    "policy_question": "Your specific question",
    "model": "qwen3:14b"
}

# Add data
df = pd.read_csv("your_data.csv")
prompt(df.head(), "Sample data:")
prompt(df.describe(), "Data summary:")

# Run analysis (streams output in real-time)
ai(CONFIG)
```

## Detailed Usage

### Adding Data to AI Prompt
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

### Configuration Dictionary
All settings are passed via a single config dictionary:

```python
CONFIG = {
    "data_background": "Brief description of your data and context",
    "policy_question": "Specific question you want answered", 
    "model": "ollama_model_name"
}
```

**Required fields:**
- `data_background`: Context about your data
- `policy_question`: What you want to understand
- `model`: Which Ollama model to use

### Reading Markdown Files
Include external markdown content in your analysis:

```python
from ai_policy_advisor import read_markdown_for_ai

read_markdown_for_ai("background_info.md")
ai_policy_advisor(CONFIG)
```


## R Version
An R version is also available in `ai_policy_advisor.r` with similar functionality:

```r
source("ai_policy_advisor.r")

CONFIG <- list(
  data_background = "Your data description",
  policy_question = "Your question",
  model = "qwen3:14b"
)

add_to_ai_prompt(results, "context")
ai_policy_advisor(CONFIG)
```

## Contributing

This project is open source under the GNU AFFERO license. Contributions welcome!

## License

GNU AFFERO General Public License - see LICENSE file for details.