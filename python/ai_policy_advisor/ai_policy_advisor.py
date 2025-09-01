# stdlib
import json
from typing import Any

# third-party
from docx import Document
from IPython import get_ipython
from IPython.display import clear_output
import numpy as np
import pandas as pd
import requests


# AIPolicyAdvisor Python class
class AIPolicyAdvisor:
    # Initialize the class
    def __init__(self):
        # Initialize the AI prompt as an empty string
        self.ai_prompt = ""
        # Maximum number of characters allowed in the AI prompt
        self.max_chars = 32000

    # Function adding results to the AI prompt for later querying
    def add_to_ai_prompt(self, results: Any, context: str = "") -> Any:
        """
        Args:
            results: The results to add (can be various data types)
            context: Optional context string to prepend to results

        Returns:
            The original results (for chaining)
        """
        # Check if the results are a string, list, tuple, or numpy array
        if isinstance(results, (str, list, tuple, np.ndarray)):
            # Convert to data object into a string
            if isinstance(results, (list, tuple, np.ndarray)):
                # Clip very long arrays/lists to avoid bloating the prompt
                max_preview_length = 100
                if len(results) > max_preview_length:
                    preview_results = results[:max_preview_length]
                    results_string = " ".join(str(x) for x in preview_results)
                    results_string += f" ... [and {len(results) - max_preview_length} more]"
                else:
                    results_string = " ".join(str(x) for x in results)
            else:
                results_string = str(results)

            # Add context if provided
            if context:
                results_string = f"{context} {results_string}"

            # Add the results to the AI prompt
            self.ai_prompt += results_string + "\n"

        elif isinstance(results, (pd.DataFrame, pd.Series)):
            # Convert pandas objects to string representation with row limits
            if isinstance(results, pd.DataFrame):
                max_rows = 50
                if len(results) > max_rows:
                    # Show header with dimensions and preview first N rows
                    header = f"[DataFrame: {len(results)} rows x {len(results.columns)} cols] showing first {max_rows} rows\n"
                    preview_df = results.head(max_rows)
                    results_string = header + preview_df.to_string()
                else:
                    results_string = results.to_string()
            else:
                # For Series, limit to first 100 items
                max_items = 100
                if len(results) > max_items:
                    preview_series = results.head(max_items)
                    results_string = preview_series.to_string() + f"\n... [and {len(results) - max_items} more]"
                else:
                    results_string = results.to_string()
            if context:
                results_string = f"{context}\n{results_string}"
            self.ai_prompt += results_string + "\n"

        elif isinstance(results, dict):
            # Convert dict to formatted string
            results_string = json.dumps(results, indent=2)
            if context:
                results_string = f"{context}\n{results_string}"
            self.ai_prompt += results_string + "\n"

        else:
            # Try to convert to string
            try:
                results_string = str(results)
                if context:
                    results_string = f"{context} {results_string}"
                self.ai_prompt += results_string + "\n"
            except Exception as e:
                raise ValueError(
                    f"Invalid data type. Please use strings, lists, arrays, dataframes, or dictionaries. Error: {e}"
                ) from e

        # Returns the original results for so the function can be chained inside other functions
        return results

    # Function to read a markdown file and add its content to the AI prompt
    def read_file_for_ai(self, file_path: str, max_rows: int = 50) -> str:
        """
        Read a CSV or markdown file and add its content to the AI prompt.
        CSV printing is row-limited to avoid token blowups.

        Args:
            file_path: Path to the CSV or markdown file
            max_rows: Maximum rows to show for CSV files (default: 50)

        Returns:
            The content of the file as a string
        """
        try:
            # Check if the file is a CSV file
            if file_path.endswith(".csv"):
                # Read the CSV file
                df = pd.read_csv(file_path)
                # Create a header showing data dimensions and row limit
                header = f"[DataFrame: {len(df)} rows x {len(df.columns)} cols] showing first {min(len(df), max_rows)} rows\n"     
                # Only show first max_rows to avoid token blowups
                if len(df) > max_rows:
                    preview_df = df.head(max_rows)
                    text = header + preview_df.to_string()
                else:
                    text = header + df.to_string()
                self.ai_prompt += text + "\n"
            elif file_path.endswith(".md"):
                # Read the markdown file
                with open(file_path, encoding="utf-8") as file:
                    text = file.read()
                # Add the markdown content to the AI prompt
                self.ai_prompt += text + "\n"
            else:
                raise ValueError(
                    "Invalid file type. Please use a CSV or markdown file."
                )
            return text
        except FileNotFoundError:
            raise FileNotFoundError(f"File not found: {file_path}") from None
        except Exception as e:
            raise Exception(f"Error reading file: {e}") from e

    def ai_policy_advisor(self, config: dict) -> str:
        """
        Get AI interpretation of your data using a config dictionary.

        Args:
            config: Dictionary with required keys:
                - data_background: Description of what the data represents
                - policy_question: Specific question you're trying to answer
                - model: Ollama model name

        Example config at top of your file:
        CONFIG = {
            "data_background": "The following is drug overdose data across demographics over 5 years, including some rates of change.",
            "policy_question": "What are the trends in drug overdose rates across demographics and how might we address them including for any particular subpopulations?",
            "model": "qwen3:8b"
        }

        Usage:
        ai_policy_advisor(CONFIG)
        """
        # Validate config dictionary exists
        if not config:
            raise ValueError("""
        ❌ CONFIG DICTIONARY REQUIRED!

        You must pass a config dictionary. Add this at the top of your file:

        CONFIG = {
            "data_background": "Brief description of what your data represents",
            "policy_question": "What specific question are you trying to answer?",
            "model": "Which Ollama model to use (e.g., 'qwen3:14b')"
        }

        Then call: ai_policy_advisor(CONFIG)
                """)

        # Validate whether the required keys are included in the config dictionary and named correctly
        required_keys = ["data_background", "policy_question", "model"]
        missing_keys = [key for key in required_keys if key not in config]

        if missing_keys:
            raise ValueError(f"""
        ❌ MISSING REQUIRED CONFIG KEYS: {missing_keys}

        Your config dictionary must include all these keys:
        {required_keys}

        Current config: {config}

        Fix by adding the missing keys to your CONFIG dictionary and naming them correctly.
                """)

        # Extract values from config
        data_background = config["data_background"]
        policy_question = config["policy_question"]
        model_name = config["model"]

        # Use instance prompt if none provided
        ai_prompt = self.ai_prompt

        if not ai_prompt or ai_prompt == "":
            raise ValueError(
                "Please provide a prompt to the ai_policy_advisor function."
            )

        if not model_name:
            raise ValueError(
                "Please pass an AI model name as the model parameter. Make sure to set the model in the top of the file in the CONFIG dictionary."
            )

        # Check for optional parameters and provide helpful messages
        if not data_background:
            print(
                "!!! For better results, provide some background about the data. Pass it as data_background parameter.\n"
            )

        if not policy_question:
            print(
                "!!! If you want a specific policy or decision-making question answered, pass it as policy_question parameter.\n"
            )

        # Prepare background and policy question text
        if data_background:
            data_background = f"Here is the data background: {data_background}"

        if policy_question:
            policy_question = f"I need help answering a specific policymaking/decision-making question: {policy_question}"

        # Prepare the system message
        system_message = f"You are a policy analyst/data scientist assisting in interpreting the data. {data_background} {policy_question} Focus on synthesizing the data results and providing insights across results, backing up every interpretation with clear evidence and rationale. Make sure to double and triple check that any numbers you repeat accurately reflect the numbers specifically given to you in the prompt. Provide a strong summary at the end."

        # Prepare the prompt text, truncating if it's too long
        prompt_text = ai_prompt
        if len(prompt_text.encode('utf-8')) > self.max_chars:
            # Truncate based on byte length to handle unicode characters properly
            prompt_text = ai_prompt[:self.max_chars]

        # Call Ollama with Jupyter-friendly streaming
        ai_response = self.call_ollama(
            model_name, system_message, prompt_text, stream=True
        )

        # Create disclaimer and final interpretation
        disclaimer = """----- Disclaimer: This interpretation was produced by a Large Language Model running locally via Ollama, which generates answers based on the text it was trained on. Therefore the answers may contain errors. It is important to verify the information with a domain expert before making any decisions. The AI Policy Advisor is meant to be a cheap, immediate, first-pass at interpreting data for policy and decision-making purposes. -----

## AI Policy Advisor
"""
        ai_interpretation = disclaimer + ai_response

        # Save to Word document as default
        doc = Document()
        for line in ai_interpretation.split("\n"):
            doc.add_paragraph(line)
        doc.save("ai_interpretation.docx")

        # Clear the prompt
        self.ai_prompt = ""

        return ai_interpretation

    def call_ollama(
        self, model: str, system_message: str, user_prompt: str, stream: bool = True
    ) -> str:
        """Make API call to local Ollama instance."""
        try:
            url = "http://localhost:11434/api/generate"
            payload = {
                "model": model,
                "prompt": f"{system_message}\n\nUser data: {user_prompt}",
                "stream": stream,
            }

            response = requests.post(url, json=payload, timeout=420, stream=stream)

            if response.status_code == 200:
                if stream:
                    # Check if we're in Jupyter for cleaner output
                    jupyter_mode = get_ipython() is not None

                    # Stream the response and show it in real-time
                    full_response = ""

                    if jupyter_mode:
                        # Jupyter-friendly streaming with clear_output
                        print("🤖 AI Response (streaming):")
                        print("-" * 50)

                        for line in response.iter_lines():
                            if line:
                                try:
                                    chunk = line.decode("utf-8")
                                    data = json.loads(chunk)

                                    if "response" in data:
                                        token = data["response"]
                                        full_response += token

                                        # Clear and redraw the entire response
                                        clear_output(wait=True)
                                        print("🤖 AI Response (streaming):")
                                        print("-" * 50)
                                        print(full_response)
                                        print("-" * 50)

                                    if data.get("done", False):
                                        break
                                except json.JSONDecodeError:
                                    continue
                    else:
                        # Regular terminal streaming
                        print("🤖 AI Response (streaming):")
                        print("-" * 50)

                        for line in response.iter_lines():
                            if line:
                                try:
                                    chunk = line.decode("utf-8")
                                    data = json.loads(chunk)

                                    if "response" in data:
                                        token = data["response"]
                                        print(
                                            token, end="", flush=True
                                        )  # Print without newline
                                        full_response += token

                                    if data.get("done", False):
                                        break
                                except json.JSONDecodeError:
                                    continue

                        print("\n" + "-" * 50)

                    return full_response
                else:
                    # Non-streaming (original behavior)
                    response_data = response.json()
                    return response_data.get("response", "")
            else:
                raise Exception(
                    f"Ollama API request failed with status {response.status_code}. Make sure Ollama is running and the model is available. You may be trying to pass too much information to the model at once. Try less."
                )

        except requests.exceptions.ConnectionError:
            raise Exception(
                "Could not connect to Ollama. Make sure Ollama is installed and running. On macOS, it should start automatically. You can check if it's running with: ollama list"
            ) from None
        except requests.exceptions.ReadTimeout:
            raise Exception(f"""
⏰ OLLAMA TIMEOUT (7 minutes)

The model '{model}' is taking too long to respond. Try these solutions:

1. **Use a smaller/faster model:**
   - qwen3:8b (faster)
   - llama3.2:latest (smaller)

2. **Reduce your data size:**
   - Send smaller chunks of data
   - Summarize data before sending

3. **Check your hardware:**
   - Close other applications
   - Ensure sufficient RAM/GPU memory

Current model: {model}
Timeout: 420 seconds (7 minutes)
            """) from None
        except Exception as e:
            raise Exception(f"Error connecting to Ollama: {str(e)}") from e


# Instantiate the class
advisor = AIPolicyAdvisor()


# Global convenience functions
def add_to_ai_prompt(results: Any, context: str = "") -> Any:
    """Global function to add results to the AI prompt."""
    return advisor.add_to_ai_prompt(results, context)


def read_file_for_ai(file_path: str, max_rows: int = 50) -> str:
    """Global function to read CSV or markdown files for AI."""
    return advisor.read_file_for_ai(file_path, max_rows)


def ai_policy_advisor(config: dict = None) -> str:
    """Global function to run the AI policy advisor using local Ollama."""
    if config is None:
        config = {}
    return advisor.ai_policy_advisor(config)
