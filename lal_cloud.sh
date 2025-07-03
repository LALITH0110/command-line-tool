#!/bin/bash

# LAL - Natural Language to Shell Commands (Cloud Version)
# No API keys required - uses LAL cloud service

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# LAL API endpoint (replace with your actual domain)
LAL_API_URL="${LAL_API_URL:-https://lal-api.yourdomain.com}"

show_help() {
    echo "🚀 LAL - Natural Language to Shell Commands"
    echo ""
    echo "Convert natural language descriptions into shell commands using AI."
    echo "🌟 No API keys required - powered by LAL Cloud!"
    echo ""
    echo "💡 Usage:"
    echo "  lal \"your command description\""
    echo ""
    echo "🌟 Examples:"
    echo "  lal \"git push\"                           # Git operations"
    echo "  lal \"what's running on port 8000\"        # Process monitoring"
    echo "  lal \"find large files\"                   # File operations"
    echo "  lal \"list all docker containers\"         # Docker management"
    echo "  lal \"compress this folder\"               # Archive operations"
    echo "  lal \"show disk usage\"                    # System information"
    echo "  lal \"kill process on port 3000\"          # Process management"
    echo "  lal \"check network connections\"          # Network diagnostics"
    echo ""
    echo "⚡ Quick Execution:"
    echo "  lal \"list files\" -e                      # Execute immediately"
    echo "  lal \"git status\" --execute               # Same as -e"
    echo ""
    echo "🔧 Options:"
    echo "  -e, --execute    Execute the command immediately (with confirmation)"
    echo "  --usage          Show your daily usage statistics"
    echo "  --help, -h       Show this detailed help"
    echo ""
    echo "💡 Tips:"
    echo "  • Be specific: 'list files with details' vs 'list files'"
    echo "  • Mention tools: 'docker containers' vs 'containers'"
    echo "  • Always review commands before using -e flag"
    echo "  • LAL works from any directory"
    echo "  • Free tier: 50 commands per day per user"
}

show_usage() {
    echo "📊 LAL Usage Statistics"
    echo ""
    
    # Get user ID (anonymous, based on IP)
    user_id=$(echo -n "$(curl -s ipinfo.io/ip 2>/dev/null || echo 'unknown')" | md5sum | cut -d' ' -f1)
    
    # Call usage API
    usage_response=$(curl -s "${LAL_API_URL}/usage/${user_id}" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$usage_response" ]; then
        echo "$usage_response" | jq -r '"📅 Date: " + .date'
        echo "$usage_response" | jq -r '"🎯 Daily Limit: " + (.daily_limit | tostring) + " commands"'
        echo "$usage_response" | jq -r '"✅ Used Today: " + (.used_today | tostring) + " commands"'
        echo "$usage_response" | jq -r '"⏳ Remaining: " + (.remaining_today | tostring) + " commands"'
        
        remaining=$(echo "$usage_response" | jq -r '.remaining_today')
        if [ "$remaining" -lt 10 ]; then
            echo ""
            echo -e "${YELLOW}⚠️  You're running low on daily requests!${NC}"
        fi
    else
        echo -e "${RED}❌ Unable to fetch usage statistics${NC}"
        echo "Check your internet connection or try again later."
    fi
}

call_lal_api() {
    local prompt="$1"
    
    # Prepare the API request
    local json_payload=$(jq -n --arg prompt "$prompt" '{prompt: $prompt}')
    
    # Call the LAL API
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "${LAL_API_URL}/generate" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Network connection failed"
        return 1
    fi
    
    # Check if response contains an error
    local error=$(echo "$response" | jq -r '.error // empty' 2>/dev/null)
    if [ -n "$error" ]; then
        if [[ "$error" == "Rate limit exceeded" ]]; then
            echo "RATE_LIMIT"
            echo "$response" | jq -r '.message // "Daily limit reached"'
        else
            echo "ERROR: $error"
        fi
        return 1
    fi
    
    # Extract the command
    local command=$(echo "$response" | jq -r '.command // empty' 2>/dev/null)
    local remaining=$(echo "$response" | jq -r '.remaining_requests // 0' 2>/dev/null)
    
    if [ -n "$command" ] && [ "$command" != "null" ]; then
        echo "$command"
        
        # Show remaining requests if low
        if [ "$remaining" -lt 10 ] && [ "$remaining" -gt 0 ]; then
            echo "REMAINING: $remaining" >&2
        fi
        return 0
    else
        echo "ERROR: Invalid response from LAL service"
        return 1
    fi
}

# Main script
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

case "$1" in
    --help|-h)
        show_help
        exit 0
        ;;
    --usage)
        show_usage
        exit 0
        ;;
esac

# Check for execute flag
EXECUTE=false
PROMPT=""
for arg in "$@"; do
    case $arg in
        -e|--execute)
            EXECUTE=true
            ;;
        *)
            if [ -z "$PROMPT" ]; then
                PROMPT="$arg"
            fi
            ;;
    esac
done

if [ -z "$PROMPT" ]; then
    echo -e "${YELLOW}💡 Usage: lal \"your command description\"${NC}"
    echo ""
    echo "Examples:"
    echo "  lal \"git push\""
    echo "  lal \"what's running on port 8000\""
    echo "  lal \"find large files\""
    echo ""
    echo "More help:"
    echo "  lal --help    (for detailed help)"
    echo "  lal --usage   (check your daily usage)"
    exit 1
fi

# Check internet connection
if ! curl -s --connect-timeout 5 "${LAL_API_URL}/health" >/dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to LAL service${NC}"
    echo "Please check your internet connection and try again."
    echo ""
    echo "Service URL: $LAL_API_URL"
    exit 1
fi

# Generate command
echo -e "${YELLOW}🤔 Thinking...${NC}"

RESULT=$(call_lal_api "$PROMPT")
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    # Check for remaining requests warning
    if echo "$RESULT" | grep -q "REMAINING:"; then
        COMMAND=$(echo "$RESULT" | head -n1)
        REMAINING=$(echo "$RESULT" | grep "REMAINING:" | cut -d' ' -f2)
        echo -e "${YELLOW}⚠️  Only $REMAINING requests remaining today${NC}" >&2
    else
        COMMAND="$RESULT"
    fi
    
    # Display result
    echo ""
    echo -e "${GREEN}${COMMAND}${NC}"
    
    # Execute if requested
    if [ "$EXECUTE" = true ]; then
        echo ""
        read -p "Execute this command? [y/n]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Executing: $COMMAND${NC}"
            eval "$COMMAND"
        fi
    else
        echo ""
        echo -e "${BLUE}💡 Use -e flag to execute immediately${NC}"
    fi
    
else
    # Handle errors
    if [[ "$RESULT" == "RATE_LIMIT"* ]]; then
        echo -e "${RED}🚫 Daily limit reached${NC}"
        echo ""
        echo "You've used all 50 free commands for today."
        echo "Reset time: Tomorrow at midnight UTC"
        echo ""
        echo "Check usage: lal --usage"
    else
        echo -e "${RED}❌ $RESULT${NC}"
        echo ""
        echo "If this persists, please check:"
        echo "• Your internet connection"
        echo "• LAL service status"
    fi
    exit 1
fi 