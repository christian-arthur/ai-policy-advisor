import json
import requests
from typing import Optional, Union, List, Dict, Any
import pandas as pd
import numpy as np

# Make sure to change this to the model you want to use
ollama_model = "<ENTER YOUR MODEL HERE>"

class AIPolicyAdvisor:
    def __init__(self):
        self.ai_prompt = ""
    
    def add_to_ai_prompt(self, results: Any, context: str = "") -> Any:
        """
        Add results to the AI prompt for later processing.
        
        Args:
            results: The results to add (can be various data types)
            context: Optional context string to prepend to results
            
        Returns:
            The original results (for chaining)
        """
        if isinstance(results, (str, list, tuple, np.ndarray)):
            # Convert to string
            if isinstance(results, (list, tuple, np.ndarray)):
                results_string = " ".join(str(x) for x in results)
            else:
                results_string = str(results)
            
            # Add context if provided
            if context:
                results_string = f"{context} {results_string}"
            
            self.ai_prompt += results_string + "\n"
            
        elif isinstance(results, (pd.DataFrame, pd.Series)):
            # Convert pandas objects to string representation
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
            except:
                raise ValueError("Invalid data type. Please use strings, lists, arrays, dataframes, or dictionaries.")
        
        return results
    
    def read_markdown_for_ai(self, file_path: str) -> str:
        """
        Read a markdown file and add its content to the AI prompt.
        
        Args:
            file_path: Path to the markdown file
            
        Returns:
            The content of the file
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                text = file.read()
            self.ai_prompt += text + "\n"
            return text
        except FileNotFoundError:
            raise FileNotFoundError(f"File not found: {file_path}")
        except Exception as e:
            raise Exception(f"Error reading file: {e}")
    
    def ai_policy_advisor(self, 
                         ai_prompt: str = "", 
                         data_background: str = "", 
                         policy_question: str = "", 
                         model: str = ollama_model) -> str:
        """
        Main function to get AI interpretation of data using local Ollama.
        
        Args:
            ai_prompt: The prompt containing data to analyze
            data_background: Background information about the data
            policy_question: Specific policy question to answer
            model: The Ollama model to use (set manually in the top of the file)
            
        Returns:
            The AI interpretation as a string
        """
        # Use instance prompt if none provided
        if not ai_prompt:
            ai_prompt = self.ai_prompt
        
        if not ai_prompt:
            raise ValueError("Please provide a prompt to the ai_policy_advisor function.")
        
        # Check for optional parameters and provide helpful messages
        if not data_background:
            print("!!! For better results, provide some background about the data. Pass it as data_background parameter.\n")
        
        if not policy_question:
            print("!!! If you want a specific policy or decision-making question answered, pass it as policy_question parameter.\n")
        
        
        if model is "<ENTER YOUR MODEL HERE>":
            raise ValueError("Please pass an AI model name as the model parameter. Make sure to set the model in the top of the file.")
        
        # Prepare background and policy question text
        if data_background:
            data_background = f"Here is the data background: {data_background}"
        
        if policy_question:
            policy_question = f"I need help answering a specific policymaking/decision-making question: {policy_question}"
        
        # Prepare the system message
        system_message = f"You are a policy analyst/data scientist assisting in interpreting the data. {data_background} {policy_question} Focus on synthesizing the data results and providing insights across results, backing up every interpretation with clear evidence and rationale. Make sure to double and triple check that any numbers you repeat accurately reflect the numbers specifically given to you in the prompt. Provide a strong summary at the end."
        
        # Call Ollama
        ai_response = self._call_ollama(model, system_message, ai_prompt)
        
        # Create disclaimer and final interpretation
        disclaimer = """----- Disclaimer: This interpretation was produced by a Large Language Model running locally via Ollama, which generates answers based on the text it was trained on. Therefore the answers may contain errors. It is important to verify the information with a domain expert before making any decisions. The AI Policy Advisor is meant to be a cheap, immediate, first-pass at interpreting data for policy and decision-making purposes. -----

## AI Policy Advisor
"""
        ai_interpretation = disclaimer + ai_response
        
        # Save to markdown file
        with open("ai_interpretation.md", "w", encoding="utf-8") as f:
            f.write(ai_interpretation)
        
        # Clear the prompt
        self.ai_prompt = ""
        
        return ai_interpretation
    
    def _call_ollama(self, model: str, system_message: str, user_prompt: str) -> str:
        """Make API call to local Ollama instance."""
        try:
            url = "http://localhost:11434/api/generate"
            payload = {
                "model": model,
                "prompt": f"{system_message}\n\nUser data: {user_prompt}",
                "stream": False
            }
            
            response = requests.post(url, json=payload, timeout=60)
            
            if response.status_code == 200:
                response_data = response.json()
                return response_data.get("response", "")
            else:
                raise Exception(f"Ollama API request failed with status {response.status_code}. Make sure Ollama is running and the model is available.")
                
        except requests.exceptions.ConnectionError:
            raise Exception("Could not connect to Ollama. Make sure Ollama is installed and running. On macOS, it should start automatically. You can check if it's running with: ollama list")
        except Exception as e:
            raise Exception(f"Error connecting to Ollama: {str(e)}")

# Create a global instance for convenience
advisor = AIPolicyAdvisor()

# Convenience functions that mirror the R interface
def add_to_ai_prompt(results: Any, context: str = "") -> Any:
    """Global function to add results to the AI prompt."""
    return advisor.add_to_ai_prompt(results, context)

def read_markdown_for_ai(file_path: str) -> str:
    """Global function to read markdown for AI."""
    return advisor.read_markdown_for_ai(file_path)

def ai_policy_advisor(ai_prompt: str = "", 
                     data_background: str = "", 
                     policy_question: str = "", 
                     model: str = ollama_model) -> str:
    """Global function to run the AI policy advisor using local Ollama."""
    return advisor.ai_policy_advisor(ai_prompt, data_background, policy_question, model) 