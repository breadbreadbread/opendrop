# Makefile for OpenDrop-ML build automation
# This addresses common build issues including mixed Python toolchain and SUNDIALS dependencies

.PHONY: help install install-dev clean setup-venv check-env

# Default target
help:
	@echo "OpenDrop-ML Build Commands:"
	@echo ""
	@echo "  setup-venv    - Set up Python virtual environment"
	@echo "  install       - Install dependencies and build package"
	@echo "  install-dev   - Install in development mode"
	@echo "  clean         - Clean build artifacts"
	@echo "  check-env     - Check Python environment consistency"
	@echo "  help          - Show this help message"

# Set up Python virtual environment
setup-venv:
	@echo "Setting up Python virtual environment..."
	@command -v uv >/dev/null 2>&1 && uv venv --python 3.10 .venv || python3 -m venv .venv
	@echo "Virtual environment created. Activate with: source .venv/bin/activate"

# Install dependencies and build package
install: check-env
	@echo "Installing OpenDrop-ML..."
	@source .venv/bin/activate && python -m pip install --upgrade pip
	@source .venv/bin/activate && python -m pip install .

# Install in development mode
install-dev: check-env
	@echo "Installing OpenDrop-ML in development mode..."
	@source .venv/bin/activate && python -m pip install --upgrade pip
	@source .venv/bin/activate && python -m pip install -e .

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf opendrop/**/.checkpoints/
	@find . -name "*.os" -delete
	@find . -name "*.o" -delete
	@find . -name "*.so" -delete
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Check Python environment consistency
check-env:
	@echo "Checking Python environment..."
	@source .venv/bin/activate && python -c "import sys; print(f'Python: {sys.executable} (version {sys.version_info.major}.{sys.version_info.minor})')"
	@source .venv/bin/activate && python -m pip --version
	@echo "Checking for SUNDIALS headers..."
	@test -f /usr/include/arkode/arkode_erkstep.h && echo "✓ SUNDIALS headers found in /usr/include" || echo "✗ SUNDIALS headers not found in /usr/include"
	@test -f /usr/include/arkode/arkode_erkstep.h && echo "✓ SUNDIALS detected - build should succeed" || echo "✗ Install SUNDIALS with: sudo apt install libsundials-dev libsundials-arkode5 libsundials-nvecserial6"

# Check and install system dependencies
install-deps:
	@echo "Installing system dependencies..."
	@sudo apt update
	@sudo apt install -y libsundials-dev libsundials-arkode5 libsundials-arkode5 libsundials-nvecserial6

# Complete setup
all: setup-venv install-deps install

# Development setup
dev: setup-venv install-deps install-dev