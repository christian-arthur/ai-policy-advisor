"""
AI Policy Advisor - AI-powered policy analysis tool using local Ollama models.

This package provides tools for analyzing data and generating policy insights
using locally-hosted AI models via Ollama.
"""

from ai_policy_advisor import (
    AIPolicyAdvisor,
    add_to_ai_prompt,
    read_markdown_for_ai,
    ai_policy_advisor,
)

__version__ = "0.1.0"
__author__ = "Christian Arthur"

__all__ = [
    "AIPolicyAdvisor",
    "add_to_ai_prompt", 
    "read_markdown_for_ai",
    "ai_policy_advisor",
]
