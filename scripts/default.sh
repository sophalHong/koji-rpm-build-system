#!/bin/bash
set -eo pipefail
echo "================================================"
echo -e '\033[0;31m'
echo "Usage: SCRIPT_FILE=/path/to/file make run-script"
echo 
echo "> Run as root user:"
echo "    SCRIPT_USER=root SCRIPT_FILE=/path/to/file make run-script"
echo 
echo "> Run script with arguments:"
echo "    SCRIPT_USER=admin SCRIPT_FILE=/path/to/file SCRIPT_ARGS=\"arg1 arg2\" make run-script"
echo -e '\033[0m'
echo "================================================"
