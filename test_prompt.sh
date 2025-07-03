#!/bin/bash

# Test script for LAL API server prompt behavior
# This helps verify that content generation prompts use placeholders

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Check if API keys are available
if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: No API keys found in environment"
    echo "Please set ANTHROPIC_API_KEY or OPENAI_API_KEY"
    exit 1
fi

# Define test cases
TEST_CASES=(
    "git push"
    "what's running on port 8000"
    "list all files with details"
    "write me an 100 word essay about rice as staple food"
    "create a python script that calculates fibonacci"
    "make a bash script to rename all jpg files"
)

# Text formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Updated system prompt
SYSTEM_PROMPT="You are a command-line expert. Convert natural language requests into shell commands. CRITICAL: Return ONLY the command structure, no explanations, no context, no additional text whatsoever. MOST CRITICAL INSTRUCTION: When asked to generate content like essays, code, or text files, you MUST use ONLY the exact placeholder text 'content...' or 'code...' inside a here-document. NEVER include any actual implementation or content. EXAMPLES: git push -> git push, what's running on port 8000 -> lsof -i :8000, write essay about rice -> cat > essay.txt << EOF\\ncontent...\\nEOF, create bash script -> cat > script.sh << EOF\\n#!/bin/bash\\ncode...\\nEOF, create python script -> cat > script.py << EOF\\ncode...\\nEOF"

# Test against Anthropic API
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo -e "${BLUE}Testing Anthropic API responses...${NC}"
    echo ""
    
    for test_case in "${TEST_CASES[@]}"; do
        echo -e "🔍 Testing: ${test_case}"
        
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d '{
                "model": "claude-3-5-haiku-20241022",
                "max_tokens": 200,
                "temperature": 0.1,
                "system": "'"$SYSTEM_PROMPT"'",
                "messages": [{"role": "user", "content": "Command: '"$test_case"'"}]
            }' \
            "https://api.anthropic.com/v1/messages")
        
        content=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)
        
        if [ $? -eq 0 ] && [ -n "$content" ] && [ "$content" != "null" ]; then
            echo -e "${GREEN}✓ Response:${NC} $content"
            
            # For content generation tests, check if it's using placeholders and EOF
            if [[ "$test_case" == *"essay"* ]] || [[ "$test_case" == *"script"* ]]; then
                if [[ "$content" == *"EOF"* ]] && ( [[ "$content" == *"content..."* ]] || [[ "$content" == *"code..."* ]] ); then
                    echo -e "${GREEN}✓ Using here-document with placeholders correctly${NC}"
                else
                    echo -e "${RED}✗ Not using here-document with placeholders${NC}"
                fi
            fi
        else
            echo -e "${RED}✗ Error:${NC} $(echo "$response" | jq -r '.error.message' 2>/dev/null || echo "Failed to parse response")"
        fi
        echo ""
    done
fi

# Test against OpenAI API (if available)
if [ -n "$OPENAI_API_KEY" ]; then
    echo -e "${BLUE}Testing OpenAI API responses...${NC}"
    echo ""
    
    # Convert system prompt for OpenAI (fix escaping)
    OPENAI_SYSTEM_PROMPT=$(echo "$SYSTEM_PROMPT" | sed 's/\\n/\\\\n/g')
    
    for test_case in "${TEST_CASES[@]}"; do
        echo -e "🔍 Testing: ${test_case}"
        
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $OPENAI_API_KEY" \
            -d '{
                "model": "gpt-4o-mini",
                "max_tokens": 200,
                "temperature": 0.1,
                "messages": [
                    {
                        "role": "system",
                        "content": "'"$OPENAI_SYSTEM_PROMPT"'"
                    },
                    {
                        "role": "user",
                        "content": "Command: '"$test_case"'"
                    }
                ]
            }' \
            "https://api.openai.com/v1/chat/completions")
        
        content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
        
        if [ $? -eq 0 ] && [ -n "$content" ] && [ "$content" != "null" ]; then
            echo -e "${GREEN}✓ Response:${NC} $content"
            
            # For content generation tests, check if it's using placeholders and EOF
            if [[ "$test_case" == *"essay"* ]] || [[ "$test_case" == *"script"* ]]; then
                if [[ "$content" == *"EOF"* ]] && ( [[ "$content" == *"content..."* ]] || [[ "$content" == *"code..."* ]] ); then
                    echo -e "${GREEN}✓ Using here-document with placeholders correctly${NC}"
                else
                    echo -e "${RED}✗ Not using here-document with placeholders${NC}"
                fi
            fi
        else
            echo -e "${RED}✗ Error:${NC} $(echo "$response" | jq -r '.error.message' 2>/dev/null || echo "Failed to parse response")"
        fi
        echo ""
    done
fi

echo "Test completed!" 