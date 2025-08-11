#!/bin/bash
# Test runner script for OpenTelemetry configuration

cd "$(dirname "$0")"

echo "Installing test dependencies..."
pip install -r requirements.txt

echo "Running OpenTelemetry configuration tests..."
python -m pytest test_otel_config.py -v

echo "Tests completed."