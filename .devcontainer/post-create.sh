#!/usr/bin/env bash

set -euo pipefail

sudo apt-get update

# Install agent package manager dependencies.
apm install --frozen
