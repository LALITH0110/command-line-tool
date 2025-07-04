#!/bin/bash

# BOO - Natural Language to Shell Commands (Curl Version)
# Avoids all Python dependency and SSL issues

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default config path
CONFIG_DIR="$HOME/.config/boo"
CONFIG_FILE="$CONFIG_DIR/config"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR" 2>/dev/null

# Set default OS if not configured
LAL_OS="macos"

# Default Ollama model
OLLAMA_MODEL="mistral"

# Load config if exists
if [ -f "$CONFIG_FILE" ]; then
    # Load the OS setting directly
    LAL_OS_CONFIG=$(grep "^LAL_OS=" "$CONFIG_FILE" | cut -d'"' -f2)
    if [ -n "$LAL_OS_CONFIG" ]; then
        LAL_OS="$LAL_OS_CONFIG"
    fi
    
    # Load the Ollama model setting if exists
    OLLAMA_MODEL_CONFIG=$(grep "^OLLAMA_MODEL=" "$CONFIG_FILE" | cut -d'"' -f2)
    if [ -n "$OLLAMA_MODEL_CONFIG" ]; then
        OLLAMA_MODEL="$OLLAMA_MODEL_CONFIG"
    fi
fi

show_help() {
    echo "🚀 BOO - Natural Language to Shell Commands"
    echo ""
    echo "Convert natural language descriptions into shell commands using AI."
    echo ""
    echo "💡 Usage:"
    echo "  boo \"your command description\""
    echo ""
    echo "🌟 Examples:"
    echo "  boo \"git push\"                           # Git operations"
    echo "  boo \"what's running on port 8000\"        # Process monitoring"
    echo "  boo \"find large files\"                   # File operations"
    echo "  boo \"list all docker containers\"         # Docker management"
    echo "  boo \"compress this folder\"               # Archive operations"
    echo "  boo \"show disk usage\"                    # System information"
    echo "  boo \"kill process on port 3000\"          # Process management"
    echo "  boo \"check network connections\"          # Network diagnostics"
    echo ""
    echo "⚡ Quick Execution:"
    echo "  boo \"list files\" -e                      # Execute immediately"
    echo "  boo \"git status\" --execute               # Same as -e"
    echo ""
    echo "🔧 Options:"
    echo "  -e, --execute    Execute the command immediately (with confirmation)"
    echo "  -c, --copy       Copy the command to clipboard"
    echo "  --os             Change your operating system setting (Windows/macOS/Linux)"
    echo "  --model          Change the Ollama model (default: $OLLAMA_MODEL)"
    echo "  --cheat          Get common command snippets for a technology"
    echo "                   Example: boo --cheat nginx"
    echo "  --help, -h       Show this detailed help"
    echo ""
    echo "💡 Tips:"
    echo "  • Be specific: 'list files with details' vs 'list files'"
    echo "  • Mention tools: 'docker containers' vs 'containers'"
    echo "  • Always review commands before using -e flag"
    echo "  • BOO works from any directory"
    echo "  • BOO uses free local Ollama models (offline capable)"
}

set_os_config() {
    echo ""
    echo "🖥️  Operating System Configuration"
    echo ""
    echo "Select your operating system:"
    echo "1) macOS (default)"
    echo "2) Linux"
    echo "3) Windows"
    echo ""
    read -p "Enter your choice [1-3]: " os_choice
    
    case $os_choice in
        1|"")
            LAL_OS="macos"
            echo "Setting OS to macOS"
            ;;
        2)
            LAL_OS="linux"
            echo "Setting OS to Linux"
            ;;
        3)
            LAL_OS="windows"
            echo "Setting OS to Windows"
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Using macOS as default.${NC}"
            LAL_OS="macos"
            ;;
    esac
    
    # Save the OS setting
    mkdir -p "$CONFIG_DIR" 2>/dev/null
    # Preserve OLLAMA_MODEL if it exists
    if grep -q "^OLLAMA_MODEL=" "$CONFIG_FILE" 2>/dev/null; then
        OLLAMA_MODEL_VALUE=$(grep "^OLLAMA_MODEL=" "$CONFIG_FILE" | cut -d'"' -f2)
        echo "LAL_OS=\"$LAL_OS\"" > "$CONFIG_FILE"
        echo "OLLAMA_MODEL=\"$OLLAMA_MODEL_VALUE\"" >> "$CONFIG_FILE"
    else
        echo "LAL_OS=\"$LAL_OS\"" > "$CONFIG_FILE"
        echo "OLLAMA_MODEL=\"$OLLAMA_MODEL\"" >> "$CONFIG_FILE"
    fi
    
    echo -e "${GREEN}✅ OS setting saved to $CONFIG_FILE${NC}"
    echo -e "${GREEN}✅ Selected OS: $LAL_OS${NC}"
    echo ""
}

set_model_config() {
    echo ""
    echo "🤖 Ollama Model Configuration"
    echo ""
    echo "Current model: $OLLAMA_MODEL"
    echo ""
    echo "Common models:"
    echo "1) mistral (default, good balance)"
    echo "2) llama3 (high quality)"
    echo "3) gemma (fast)"
    echo "4) phi3 (small and efficient)"
    echo "5) codellama (code-focused)"
    echo "6) Custom (specify your own)"
    echo ""
    read -p "Enter your choice [1-6]: " model_choice
    
    case $model_choice in
        1|"")
            OLLAMA_MODEL="mistral"
            ;;
        2)
            OLLAMA_MODEL="llama3"
            ;;
        3)
            OLLAMA_MODEL="gemma"
            ;;
        4)
            OLLAMA_MODEL="phi3"
            ;;
        5)
            OLLAMA_MODEL="codellama"
            ;;
        6)
            echo "Available models on your system:"
            curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | sort
            echo ""
            read -p "Enter model name: " custom_model
            if [ -n "$custom_model" ]; then
                OLLAMA_MODEL="$custom_model"
            else
                echo -e "${YELLOW}Invalid model. Using mistral as default.${NC}"
                OLLAMA_MODEL="mistral"
            fi
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Using mistral as default.${NC}"
            OLLAMA_MODEL="mistral"
            ;;
    esac
    
    # Save the model setting
    mkdir -p "$CONFIG_DIR" 2>/dev/null
    # Preserve LAL_OS if it exists
    if grep -q "^LAL_OS=" "$CONFIG_FILE" 2>/dev/null; then
        LAL_OS_VALUE=$(grep "^LAL_OS=" "$CONFIG_FILE" | cut -d'"' -f2)
        echo "LAL_OS=\"$LAL_OS_VALUE\"" > "$CONFIG_FILE"
        echo "OLLAMA_MODEL=\"$OLLAMA_MODEL\"" >> "$CONFIG_FILE"
    else
        echo "OLLAMA_MODEL=\"$OLLAMA_MODEL\"" > "$CONFIG_FILE"
        echo "LAL_OS=\"$LAL_OS\"" >> "$CONFIG_FILE"
    fi
    
    echo -e "${GREEN}✅ Model setting saved to $CONFIG_FILE${NC}"
    echo -e "${GREEN}✅ Selected model: $OLLAMA_MODEL${NC}"
    echo ""
}

show_config() {
    echo "🔧 BOO Configuration & Setup Guide"
    echo ""
    echo "📊 Current Configuration:"
    echo "  Ollama Model: $OLLAMA_MODEL"
    
    # Check if Ollama is installed
    if command -v ollama >/dev/null 2>&1; then
        echo "  Ollama Installation: ✅ Installed"
    else
        echo "  Ollama Installation: ❌ Not found"
    fi
    
    # Check if Ollama is running
    if curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
        echo "  Ollama Status: ✅ Running"
    else
        echo "  Ollama Status: ❌ Not running"
    fi
    
    # Show OS configuration
    echo "  Operating System: $LAL_OS"
    
    echo ""
    
    if ! command -v ollama >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Ollama not found. Install it from https://ollama.com${NC}"
        echo ""
    fi
    
    echo "🚀 Setup Guide:"
    echo ""
    echo "1️⃣  Install Ollama (free, local AI):"
    echo "      • Visit: https://ollama.com"
    echo "      • Download and install for your OS"
    echo "      • Run 'ollama serve' to start the server"
    echo "      • Pull models with 'ollama pull mistral' etc."
    echo ""
    echo "2️⃣  Configure BOO:"
    echo "      boo --os      # Set your operating system"
    echo "      boo --model   # Change AI model"
    echo ""
    echo "3️⃣  Test Installation:"
    echo "      boo \"list files\""
    echo ""
    echo "💡 Notes:"
    echo "   • BOO uses Ollama by default (free, offline capable)"
    echo "   • No API keys or credits needed"
    echo "   • Models run locally on your computer"
    
    # Ask if user wants to configure
    echo ""
    read -p "Do you want to configure your settings now? [y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "1) Set operating system"
        echo "2) Change AI model"
        echo "3) Both"
        echo ""
        read -p "Enter your choice [1-3]: " config_choice
        case $config_choice in
            1)
                set_os_config
                ;;
            2)
                set_model_config
                ;;
            3)
                set_os_config
                set_model_config
                ;;
            *)
                echo -e "${YELLOW}No changes made.${NC}"
                ;;
        esac
    fi
}

# Check if Ollama is installed and running
check_ollama() {
    # Check if Ollama is installed
    if ! command -v ollama >/dev/null 2>&1 && ! curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
        echo -e "${YELLOW}Ollama not detected. You may need to install it from https://ollama.com${NC}"
        echo -e "${YELLOW}or ensure the Ollama server is running with 'ollama serve'${NC}"
        return 1
    fi
    
    # Try to ping Ollama server
    if ! curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
        echo -e "${YELLOW}Ollama server not responding. Start it with 'ollama serve'${NC}"
        return 1
    fi
    
    return 0
}

# Call Ollama API
call_ollama() {
    local prompt="$1"
    local system_prompt="You are a command-line expert. Convert natural language requests into shell commands for $LAL_OS operating system. CRITICAL INSTRUCTIONS: 1) Return ONLY the command, no explanations. 2) If the request is a question (e.g. 'What is X?') or not asking for a command, return ONLY the word 'null'. 3) Only convert requests for actions into commands. Examples: git push -> git push, what's running on port 8000 -> lsof -i :8000, list all files -> ls -la, what is git -> null, tell me about linux -> null. For requests about writing essays or generating text, use a heredoc syntax to save the text to a file, but DO NOT include the full text content - just show the command structure. For example: 'write an essay about rice' -> cat > essay.txt << EOF\nEssay text would go here\nEOF"
    
    # Add Windows-specific guidance if needed
    if [ "$LAL_OS" = "windows" ]; then
        system_prompt="You are a command-line expert for Windows. Convert natural language requests into Windows CMD or PowerShell commands. CRITICAL INSTRUCTIONS: 1) Return ONLY the command, no explanations. 2) If the request is a question (e.g. 'What is X?') or not asking for a command, return ONLY the word 'null'. 3) Only convert requests for actions into commands. Examples: list files -> dir, create folder -> mkdir foldername, find text -> findstr \"text\" file.txt, what is windows -> null, explain powershell -> null."
    fi
    
    # First check if Ollama is available
    check_ollama
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Call Ollama API
    local response=$(curl -s --max-time 15 http://localhost:11434/api/generate -d '{
        "model": "'"$OLLAMA_MODEL"'",
        "prompt": "'"System: $system_prompt\n\nUser: Convert this to a command: $prompt"'",
        "stream": false
    }')
    
    # Handle curl errors
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to connect to Ollama API${NC}" >&2
        echo "null"
        return 1
    fi
    
    # Extract response
    local command=$(echo "$response" | grep -o '"response":"[^"]*"' | cut -d'"' -f4)
    
    # Clean up response (remove markdown formatting if present)
    command=$(echo "$command" | sed -e 's/^```[a-z]*$//' -e 's/^```$//' -e 's/^`//' -e 's/`$//')
    
    # Check if response is null or a question answer
    if [ -z "$command" ] || [ "$command" = "null" ] || echo "$command" | grep -q "^null" || echo "$command" | grep -qiE "I can't|cannot|sorry|not able|question|what is"; then
        echo "null"
        return 1
    else
        # Return the command
        echo "$command"
        return 0
    fi
}

call_anthropic() {
    local prompt="$1"
    local system_prompt="You are a command-line expert. Convert natural language requests into shell commands for $LAL_OS operating system. CRITICAL INSTRUCTIONS: 1) Return ONLY the command, no explanations. 2) If the request is a question (e.g. 'What is X?') or not asking for a command, return ONLY the word 'null'. 3) Only convert requests for actions into commands. Examples: git push -> git push, what's running on port 8000 -> lsof -i :8000, list all files -> ls -la, what is git -> null, tell me about linux -> null. For requests about writing essays or generating text, use a heredoc syntax to save the text to a file, but DO NOT include the full text content - just show the command structure. For example: 'write an essay about rice' -> cat > essay.txt << EOF\\nEssay text would go here\\nEOF"
    
    # Add Windows-specific guidance if needed
    if [ "$LAL_OS" = "windows" ]; then
        system_prompt="You are a command-line expert for Windows. Convert natural language requests into Windows CMD or PowerShell commands. CRITICAL INSTRUCTIONS: 1) Return ONLY the command, no explanations. 2) If the request is a question (e.g. 'What is X?') or not asking for a command, return ONLY the word 'null'. 3) Only convert requests for actions into commands. Examples: list files -> dir, create folder -> mkdir foldername, find text -> findstr \"text\" file.txt, what is windows -> null, explain powershell -> null."
    fi

    # Escape quotes in system prompt for JSON
    system_prompt_escaped=$(echo "$system_prompt" | sed 's/"/\\"/g')

    # Add timeout to prevent hanging
    local response=$(curl -s --max-time 10 https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"claude-3-5-haiku-20241022\",
            \"max_tokens\": 200,
            \"temperature\": 0.1,
            \"system\": \"$system_prompt_escaped\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Command: $prompt\"}]
        }")
    
    # Handle curl errors (timeout, connection issues)
    if [ $? -ne 0 ]; then
        echo -e "${RED}API connection error or timeout${NC}" >&2
        echo "null"
        return 1
    fi
    
    # Debug API response if it contains error
    if echo "$response" | grep -q "\"error\""; then
        echo "API Error: $(echo "$response" | jq -r '.error.message' 2>/dev/null)" >&2
        echo "null"
        return 1
    fi
    
    # Extract command from JSON response using jq
    local command=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)
    
    # Check if response is null or a question answer
    if [ -z "$command" ] || [ "$command" = "null" ]; then
        echo "null"
        return 1
    elif [[ "$command" == "null" ]]; then
        echo "null"
        return 1
    else
        # Return the command
        echo "$command"
        return 0
    fi
}

call_openai() {
    local prompt="$1"
    local system_prompt="You are a command-line expert. Convert natural language requests into shell commands for $LAL_OS operating system. CRITICAL INSTRUCTIONS: 1) Return ONLY the command, no explanations. 2) If the request is a question (e.g. 'What is X?') or not asking for a command, return ONLY the word 'null'. 3) Only convert requests for actions into commands. Examples: git push -> git push, what's running on port 8000 -> lsof -i :8000, list all files -> ls -la, what is git -> null, tell me about linux -> null. For requests about writing essays or generating text, use a heredoc syntax to save the text to a file, but DO NOT include the full text content - just show the command structure. For example: 'write an essay about rice' -> cat > essay.txt << EOF\\nEssay text would go here\\nEOF"
    
    # Add Windows-specific guidance if needed
    if [ "$LAL_OS" = "windows" ]; then
        system_prompt="You are a command-line expert for Windows. Convert natural language requests into Windows CMD or PowerShell commands. CRITICAL INSTRUCTIONS: 1) Return ONLY the command, no explanations. 2) If the request is a question (e.g. 'What is X?') or not asking for a command, return ONLY the word 'null'. 3) Only convert requests for actions into commands. Examples: list files -> dir, create folder -> mkdir foldername, find text -> findstr \"text\" file.txt, what is windows -> null, explain powershell -> null."
    fi

    # Escape quotes in system prompt for JSON
    system_prompt_escaped=$(echo "$system_prompt" | sed 's/"/\\"/g')

    # Add timeout to prevent hanging
    local response=$(curl -s --max-time 10 https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"gpt-4o-mini\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"$system_prompt_escaped\"},
                {\"role\": \"user\", \"content\": \"Command: $prompt\"}
            ],
            \"max_tokens\": 200,
            \"temperature\": 0.1
        }")
    
    # Handle curl errors (timeout, connection issues)
    if [ $? -ne 0 ]; then
        echo -e "${RED}API connection error or timeout${NC}" >&2
        echo "null"
        return 1
    fi
    
    # Debug API response if it contains error
    if echo "$response" | grep -q "\"error\""; then
        echo "API Error: $(echo "$response" | jq -r '.error.message' 2>/dev/null)" >&2
        echo "null"
        return 1
    fi
    
    # Extract command from JSON response using jq
    local command=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    
    # Check if response is null or a question answer
    if [ -z "$command" ] || [ "$command" = "null" ]; then
        echo "null"
        return 1
    elif [[ "$command" == "null" ]]; then
        echo "null" 
        return 1
    else
        # Return the command
        echo "$command"
        return 0
    fi
}

# Copy text to clipboard based on OS
copy_to_clipboard() {
    local text="$1"
    
    case "$LAL_OS" in
        macos)
            echo "$text" | pbcopy
            return $?
            ;;
        linux)
            # Try different clipboard commands
            if command -v xclip >/dev/null 2>&1; then
                echo "$text" | xclip -selection clipboard
                return $?
            elif command -v xsel >/dev/null 2>&1; then
                echo "$text" | xsel -ib
                return $?
            elif command -v wl-copy >/dev/null 2>&1; then
                echo "$text" | wl-copy
                return $?
            else
                echo -e "${YELLOW}Clipboard utilities not found. Install xclip, xsel, or wl-copy.${NC}" >&2
                return 1
            fi
            ;;
        windows)
            # For Windows users using WSL or Git Bash
            if command -v clip.exe >/dev/null 2>&1; then
                echo "$text" | clip.exe
                return $?
            else
                echo -e "${YELLOW}Windows clipboard access not available.${NC}" >&2
                return 1
            fi
            ;;
        *)
            echo -e "${YELLOW}Clipboard not supported for this OS.${NC}" >&2
            return 1
            ;;
    esac
}

# Check if a command is potentially dangerous
is_dangerous_command() {
    local cmd="$1"
    
    # Simple substring checks for common dangerous commands
    if [[ "$cmd" == *"rm "* || "$cmd" == "rm" || 
          "$cmd" == *"sudo "* || 
          "$cmd" == *"kill "* || "$cmd" == *"killall "* ||
          "$cmd" == *"pkill "* || "$cmd" == *"dd "* ||
          "$cmd" == *"mkfs"* || "$cmd" == *"fdisk"* ||
          "$cmd" == *"chmod "* || "$cmd" == *"chown "* ||
          "$cmd" == *"rmdir "* || "$cmd" == "rmdir" ||
          "$cmd" == *"mv / "* || "$cmd" == *"mv /* "* ||
          "$cmd" == *"> /etc/"* || "$cmd" == *"> /dev/"* ||
          "$cmd" == *"> /sys/"* || "$cmd" == *"> /proc/"* ||
          "$cmd" == *"format"* || "$cmd" == *"wipe"* ||
          "$cmd" == *"delete"* || "$cmd" == *"destroy"* ]]; then
        return 0 # True, command is dangerous
    fi
    
    # Windows-specific dangerous commands
    if [ "$LAL_OS" = "windows" ]; then
        if [[ "$cmd" == *"del "* || "$cmd" == *"rd "* ||
              "$cmd" == *"rmdir "* || "$cmd" == *"format "* ||
              "$cmd" == *"taskkill "* || "$cmd" == *"Remove-Item"* ]]; then
            return 0 # True, command is dangerous
        fi
    fi
    
    # Check for potentially dangerous command piped to something
    if [[ "$cmd" == *"rm "*"|"* || 
          "$cmd" == *"dd "*"|"* || 
          "$cmd" == *"sudo "*"|"* ]]; then
        return 0 # True, command is dangerous
    fi
    
    return 1 # False, command is not dangerous
}

# Get cheat sheet for a technology
get_cheat_sheet() {
    local topic="$1"
    
    # Use Ollama for cheat sheet generation
    local system_prompt="You are a command-line expert. Generate a concise cheat sheet with the most useful command examples for the specified technology. Format as a list of commands with VERY brief explanations (max 1 line per command). Include only the most important/common commands. Limit to 10-15 commands maximum."
    
    echo -e "${YELLOW}Generating cheat sheet for ${GREEN}$topic${YELLOW}...${NC}"
    
    # First try Ollama
    check_ollama
    if [ $? -eq 0 ]; then
        # Call Ollama API
        local response=$(curl -s --max-time 15 http://localhost:11434/api/generate -d '{
            "model": "'"$OLLAMA_MODEL"'",
            "prompt": "'"System: $system_prompt\n\nUser: Generate a cheat sheet for: $topic"'",
            "stream": false
        }')
        
        # Handle curl errors
        if [ $? -eq 0 ]; then
            # Extract cheat sheet content
            local cheat_content=$(echo "$response" | grep -o '"response":".*' | sed 's/"response":"\(.*\)","done".*/\1/' | sed 's/\\n/\n/g' | sed 's/\\\\/\\/g')
            
            if [ -n "$cheat_content" ]; then
                echo ""
                echo -e "${BLUE}📋 CHEAT SHEET: ${GREEN}$topic${NC}"
                echo -e "${BLUE}=====================================${NC}"
                echo "$cheat_content"
                echo -e "${BLUE}=====================================${NC}"
                return 0
            fi
        fi
    fi
    
    # Fall back to Anthropic if available
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        local system_prompt_escaped=$(echo "$system_prompt" | sed 's/"/\\"/g')
        
        local response=$(curl -s --max-time 15 https://api.anthropic.com/v1/messages \
            -H "Content-Type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "{
                \"model\": \"claude-3-5-haiku-20241022\",
                \"max_tokens\": 1000,
                \"temperature\": 0.1,
                \"system\": \"$system_prompt_escaped\",
                \"messages\": [{\"role\": \"user\", \"content\": \"Generate a cheat sheet for: $topic\"}]
            }")
        
        # Handle curl errors
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Failed to connect to API${NC}"
            return 1
        fi
        
        # Check for API errors
        if echo "$response" | grep -q "\"error\""; then
            echo -e "${RED}API Error: $(echo "$response" | jq -r '.error.message' 2>/dev/null)${NC}"
            return 1
        fi
        
        # Extract and print cheat sheet
        local cheat_content=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)
        if [ -z "$cheat_content" ]; then
            echo -e "${RED}Error: Failed to generate cheat sheet${NC}"
            return 1
        fi
        
        echo ""
        echo -e "${BLUE}📋 CHEAT SHEET: ${GREEN}$topic${NC}"
        echo -e "${BLUE}=====================================${NC}"
        echo "$cheat_content"
        echo -e "${BLUE}=====================================${NC}"
        return 0
    fi
    
    # Fall back to OpenAI if available
    if [ -n "$OPENAI_API_KEY" ]; then
        local system_prompt_escaped=$(echo "$system_prompt" | sed 's/"/\\"/g')
        
        local response=$(curl -s --max-time 15 https://api.openai.com/v1/chat/completions \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $OPENAI_API_KEY" \
            -d "{
                \"model\": \"gpt-4o-mini\",
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"$system_prompt_escaped\"},
                    {\"role\": \"user\", \"content\": \"Generate a cheat sheet for: $topic\"}
                ],
                \"max_tokens\": 1000,
                \"temperature\": 0.1
            }")
        
        # Extract and print cheat sheet
        local cheat_content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
        if [ -z "$cheat_content" ]; then
            echo -e "${RED}Error: Failed to generate cheat sheet${NC}"
            return 1
        fi
        
        echo ""
        echo -e "${BLUE}📋 CHEAT SHEET: ${GREEN}$topic${NC}"
        echo -e "${BLUE}=====================================${NC}"
        echo "$cheat_content"
        echo -e "${BLUE}=====================================${NC}"
        return 0
    fi
    
    echo -e "${RED}Error: No AI services available for cheat sheet generation${NC}"
    return 1
}

# Main script
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Process special flags first
case "$1" in
    --help|-h)
        show_help
        exit 0
        ;;
    --config)
        show_config
        exit 0
        ;;
    --os)
        set_os_config
        exit 0
        ;;
    --model)
        set_model_config
        exit 0
        ;;
    --cheat)
        if [ -z "$2" ]; then
            echo -e "${YELLOW}Usage: boo --cheat TOPIC${NC}"
            echo -e "Example: boo --cheat nginx"
            exit 1
        fi
        get_cheat_sheet "$2"
        exit $?
        ;;
    -*)
        echo -e "${RED}❌ Unknown option: $1${NC}"
        echo "Run 'boo --help' for usage information"
        exit 1
        ;;
esac

# Check for execute flag
EXECUTE=false
COPY=false
PROMPT=""

# Check if the first argument looks like a command
if [[ $# -gt 0 && "$1" != -* ]]; then
    PROMPT="$1"
    
    # If we received multiple arguments and there are no flags, it's likely the user forgot quotes
    if [[ $# -gt 1 && ! "$*" =~ "-e" && ! "$*" =~ "--execute" && ! "$*" =~ "-c" && ! "$*" =~ "--copy" ]]; then
        echo -e "${RED}❌ Error: Multi-word prompts must be enclosed in quotes${NC}"
        echo -e "  ${RED}✗ boo $PROMPT ${*:2}${NC}"
        echo -e "  ${GREEN}✓ boo \"$PROMPT ${*:2}\"${NC}"
        echo ""
        echo -e "${YELLOW}This requirement ensures your entire prompt is processed correctly.${NC}"
        exit 1
    fi
fi

# Process remaining args
for arg in "${@:2}"; do
    case $arg in
        -e|--execute)
            EXECUTE=true
            ;;
        -c|--copy)
            COPY=true
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $arg${NC}"
            echo "Run 'boo --help' for usage information"
            exit 1
            ;;
        *)
            # Ignore additional words if they're likely part of an unquoted prompt
            ;;
    esac
done

if [ -z "$PROMPT" ]; then
    echo -e "${YELLOW}💡 Usage: boo \"your command description\"${NC}"
    echo ""
    echo "Examples:"
    echo "  boo \"git push\""
    echo "  boo \"what's running on port 8000\""
    echo "  boo \"find large files\""
    echo ""
    echo "Configuration:"
    echo "  boo --os      (to set your operating system)"
    echo "  boo --model   (to change AI model)"
    echo "  boo --help    (for detailed help)"
    exit 1
fi

# Generate command
echo -e "${YELLOW}Thinking...${NC}"

# Try Ollama first, then fall back to API services if needed
COMMAND=$(call_ollama "$PROMPT")
CMD_STATUS=$?

# If Ollama failed or returned null, try Anthropic
if [ $CMD_STATUS -ne 0 ] && [ -n "$ANTHROPIC_API_KEY" ]; then
    echo -e "${YELLOW}Trying alternative AI service...${NC}"
    COMMAND=$(call_anthropic "$PROMPT")
    CMD_STATUS=$?
fi

# If both failed, try OpenAI
if [ $CMD_STATUS -ne 0 ] && [ -n "$OPENAI_API_KEY" ]; then
    echo -e "${YELLOW}Trying another AI service...${NC}"
    COMMAND=$(call_openai "$PROMPT")
    CMD_STATUS=$?
fi

# Check if all AI services failed
if [ $CMD_STATUS -ne 0 ]; then
    echo ""
    if [ "$COMMAND" = "null" ]; then
        echo -e "${YELLOW}This appears to be a question, not a command request.${NC}"
        echo -e "${YELLOW}Try asking for a specific command action instead.${NC}"
    else
        echo -e "${RED}Failed to generate command${NC}"
        echo -e "${YELLOW}Tip: Make sure Ollama is installed and running (ollama serve)${NC}"
        echo -e "${YELLOW}Or install it from https://ollama.com${NC}"
    fi
    exit 1
fi

if [ -z "$COMMAND" ]; then
    echo ""
    echo -e "${RED}Failed to generate command${NC}"
    exit 1
fi

# Display result
echo ""
echo -e "${GREEN}${COMMAND}${NC}"

# Check if command is potentially dangerous
if is_dangerous_command "$COMMAND"; then
    echo -e "${RED}⚠️  Warning: This command is potentially destructive/dangerous.${NC}"
    echo -e "${YELLOW}Review carefully before running manually. Execution disabled.${NC}"
    EXECUTE=false
fi

# Execute if requested
if [ "$EXECUTE" = true ]; then
    echo ""
    
    # Second safety check before execution
    if is_dangerous_command "$COMMAND"; then
        echo -e "${RED}⚠️  Cannot execute: Potentially dangerous command.${NC}"
        echo -e "${RED}⚠️  For your safety, execution of this command is disabled.${NC}"
        echo -e "${YELLOW}You may copy and run it manually if you're certain it's safe.${NC}"
    else
        read -p "Execute this command? [y/n]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Executing: $COMMAND${NC}"
            eval "$COMMAND"
        fi
    fi
else
    echo ""
    echo -e "${BLUE}Use -e flag to execute immediately${NC}"
fi

# Copy to clipboard if requested
if [ "$COPY" = true ]; then
    copy_to_clipboard "$COMMAND"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Command copied to clipboard${NC}"
    else
        echo -e "${RED}❌ Failed to copy to clipboard${NC}"
    fi
fi 