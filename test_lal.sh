#!/bin/bash

# Test LAL client with our local API server
# This helps verify that our solution works end-to-end

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Override the LAL API URL to our local server
export LAL_API_URL="http://localhost:5001"

echo -e "${BLUE}Testing LAL client with local API server...${NC}"
echo ""

# Test regular command
echo -e "${YELLOW}Testing regular command: git status${NC}"
bash ./lal_cloud.sh "git status"
echo ""

# Test content generation command 
echo -e "${YELLOW}Testing content generation: write me an essay about rice${NC}"
bash ./lal_cloud.sh "write me an essay about rice"
echo ""

# Test script generation command
echo -e "${YELLOW}Testing script generation: create a bash script that renames files${NC}"
bash ./lal_cloud.sh "create a bash script that renames files"
echo "" 