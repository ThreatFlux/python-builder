#!/bin/bash
set -euo pipefail

# Ensure we're in the repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Check for virtual environment
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install requirements if needed
if ! pip show requests pyyaml > /dev/null 2>&1; then
    echo "Installing requirements..."
    pip install requests pyyaml
fi

# Make the Python script executable
chmod +x update-actions.py

# Run the update script
./update-actions.py

# Deactivate virtual environment
deactivate