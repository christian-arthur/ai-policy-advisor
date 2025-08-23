# AI Policy Advisor - Python Package

AI-powered policy analysis tool using local Ollama models.

## Development Setup

### Install Dependencies

```bash
# Install the package in development mode
pip install -e .

# Install development dependencies
pip install -e ".[dev]"
```

### Code Quality Tools

#### Ruff (Linter & Formatter)
```bash
# Check code quality
ruff check .

# Format code
ruff format .

# Auto-fix issues
ruff check --fix .
```

#### Pytest (Testing)
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=ai_policy_advisor

# Run specific test file
pytest tests/test_ai_policy_advisor.py
```

### Pre-commit Hooks (Optional)

Install pre-commit to automatically run Ruff and Pytest on commit:

```bash
pip install pre-commit
pre-commit install
```

## Project Structure

```
python/
├── ai_policy_advisor/          # Main package
│   ├── __init__.py
│   └── ai_policy_advisor.py
├── tests/                      # Test files
│   └── test_ai_policy_advisor.py
├── pyproject.toml             # Package configuration
├── requirements.txt            # Runtime dependencies
└── MANIFEST.in                # Package manifest
```

## Configuration

All tool configurations are in `pyproject.toml`:
- **Ruff**: Linting and formatting rules
- **Pytest**: Testing framework settings
- **Package metadata**: Dependencies, version, etc.
