#!/bin/bash

# LAL (Language Assisted Launcher) Installer Script
# Installs LAL - Natural Language to Shell Commands

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define the installation directory
INSTALL_DIR="/usr/local/bin"
CLOUD_VERSION=true

# ASCII art logo
echo -e "${BLUE}"
echo "    __    ___    __ "
echo "   / /   /   |  / / "
echo "  / /   / /| | / /  "
echo " / /___/ ___ |/ /___"
echo "/_____/_/  |_/_____/"
echo -e "${NC}"
echo -e "${GREEN}Natural Language → Shell Commands${NC}"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ] && [ -w "$INSTALL_DIR" != "true" ]; then
    echo -e "${YELLOW}⚠️  This installer needs to write to $INSTALL_DIR${NC}"
    echo "Please run with sudo:"
    echo -e "${BLUE}sudo $0${NC}"
    exit 1
fi

# Check for curl and jq
echo -e "${YELLOW}Checking dependencies...${NC}"
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl is not installed. Please install curl first.${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq is not installed. Installing jq...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y jq
    elif command -v brew &> /dev/null; then
        brew install jq
    elif command -v yum &> /dev/null; then
        yum install -y jq
    else
        echo -e "${RED}❌ Couldn't install jq automatically. Please install jq manually.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Dependencies satisfied${NC}"

# Download the LAL script
echo -e "${YELLOW}Downloading LAL...${NC}"
curl -s -o "$INSTALL_DIR/lal" https://raw.githubusercontent.com/yourusername/lal/main/lal_cloud.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to download LAL. Check your internet connection.${NC}"
    exit 1
fi

# Make executable
chmod +x "$INSTALL_DIR/lal"

echo -e "${GREEN}✓ LAL installed successfully at $INSTALL_DIR/lal${NC}"

# Test the installation
echo -e "${YELLOW}Testing installation...${NC}"
if command -v lal &> /dev/null; then
    echo -e "${GREEN}✓ LAL is now available in your PATH${NC}"
    LAL_VERSION=$(lal --help | head -n 1)
    echo -e "${BLUE}$LAL_VERSION${NC}"
else
    echo -e "${RED}⚠️  LAL is installed but not in your PATH.${NC}"
    echo -e "You may need to add ${BLUE}$INSTALL_DIR${NC} to your PATH."
    echo "Example: export PATH=\"$INSTALL_DIR:\$PATH\""
fi

# Installation complete
echo ""
echo -e "${GREEN}🚀 Installation complete!${NC}"
echo -e "${YELLOW}Try it out:${NC}"
echo -e "${BLUE}lal \"list files with details\"${NC}"
echo -e "${BLUE}lal \"find large files\"${NC}"
echo -e "${BLUE}lal \"git status\" -e${NC}"
echo ""
echo -e "${GREEN}💡 For help, run:${NC} lal --help"

exit 0 