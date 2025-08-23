"""Tests for ai_policy_advisor package."""

import pytest
from ai_policy_advisor import ai_policy_advisor, add_to_ai_prompt


def test_add_to_ai_prompt():
    """Test adding data to AI prompt."""
    # Test with vector data
    data = [1, 2, 3, 4, 5]
    result = add_to_ai_prompt(data, "test_vector")
    assert result == data

    # Test with string data
    text = "hello world"
    result = add_to_ai_prompt(text, "test_string")
    assert result == text


def test_ai_policy_advisor_config_validation():
    """Test config validation in ai_policy_advisor."""
    # Test missing config
    with pytest.raises(ValueError):
        ai_policy_advisor({})

    # Test missing required keys
    incomplete_config = {"data_background": "test"}
    with pytest.raises(ValueError):
        ai_policy_advisor(incomplete_config)

    # Test valid config structure
    valid_config = {
        "data_background": "Test data",
        "policy_question": "Test question",
        "model": "test-model",
    }
    # This should not raise an error (though may fail on Ollama connection)
    try:
        ai_policy_advisor(valid_config)
    except Exception as e:
        # Expected to fail if Ollama not running, but config validation should pass
        assert "Ollama" in str(e) or "connection" in str(e).lower()


if __name__ == "__main__":
    pytest.main([__file__])
