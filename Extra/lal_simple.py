#!/usr/bin/env python3

import os
import sys
import json
import ssl
import urllib.request
import urllib.parse
from typing import Optional

def make_anthropic_request(prompt: str, api_key: str) -> str:
    """Make direct API call to Anthropic without using their library"""
    
    url = "https://api.anthropic.com/v1/messages"
    
    system_prompt = """You are a command-line expert. Convert natural language requests into appropriate shell commands.

Rules:
- Only return the command, no explanations
- Use common Unix/Linux/macOS commands
- Be precise and safe
- If the request is unclear, return the most likely intended command
- For dangerous commands, prefer safer alternatives

Examples:
- "git push" → git push
- "what's running on port 8000" → lsof -i :8000
- "list all files" → ls -la
- "find large files" → find . -size +100M -type f
"""
    
    data = {
        "model": "claude-3-5-haiku-20241022",
        "max_tokens": 200,
        "temperature": 0.1,
        "system": system_prompt,
        "messages": [
            {"role": "user", "content": f"Command: {prompt}"}
        ]
    }
    
    headers = {
        "Content-Type": "application/json",
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01"
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode('utf-8'),
        headers=headers
    )
    
    try:
        # Create SSL context for macOS compatibility
        ssl_context = ssl.create_default_context()
        with urllib.request.urlopen(req, context=ssl_context) as response:
            result = json.loads(response.read().decode('utf-8'))
            return result['content'][0]['text'].strip()
    except Exception as e:
        raise Exception(f"API error: {str(e)}")

def make_openai_request(prompt: str, api_key: str) -> str:
    """Make direct API call to OpenAI without using their library"""
    
    url = "https://api.openai.com/v1/chat/completions"
    
    system_prompt = """You are a command-line expert. Convert natural language requests into appropriate shell commands.

Rules:
- Only return the command, no explanations
- Use common Unix/Linux/macOS commands
- Be precise and safe
- If the request is unclear, return the most likely intended command
- For dangerous commands, prefer safer alternatives

Examples:
- "git push" → git push
- "what's running on port 8000" → lsof -i :8000
- "list all files" → ls -la
- "find large files" → find . -size +100M -type f
"""
    
    data = {
        "model": "gpt-4o-mini",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Command: {prompt}"}
        ],
        "max_tokens": 200,
        "temperature": 0.1
    }
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode('utf-8'),
        headers=headers
    )
    
    try:
        # Create SSL context for macOS compatibility
        ssl_context = ssl.create_default_context()
        with urllib.request.urlopen(req, context=ssl_context) as response:
            result = json.loads(response.read().decode('utf-8'))
            return result['choices'][0]['message']['content'].strip()
    except Exception as e:
        raise Exception(f"API error: {str(e)}")

def print_colored(text: str, color: str = "green"):
    """Simple colored output"""
    colors = {
        "green": "\033[92m",
        "red": "\033[91m",
        "yellow": "\033[93m",
        "blue": "\033[94m",
        "reset": "\033[0m"
    }
    print(f"{colors.get(color, '')}{text}{colors['reset']}")

def main():
    if len(sys.argv) < 2:
        print("💡 Usage: python3 lal_simple.py \"your command description\"")
        print("\nExamples:")
        print("  python3 lal_simple.py \"git push\"")
        print("  python3 lal_simple.py \"what's running on port 8000\"")
        print("  python3 lal_simple.py \"find large files\"")
        return
    
    if sys.argv[1] == "--config":
        anthropic_key = os.getenv('ANTHROPIC_API_KEY')
        openai_key = os.getenv('OPENAI_API_KEY')
        
        print("🔧 LAL Simple Configuration\n")
        print("Current configuration:")
        print(f"  OpenAI API Key: {'✅ Set' if openai_key else '❌ Not set'}")
        print(f"  Anthropic API Key: {'✅ Set' if anthropic_key else '❌ Not set'}")
        
        if not openai_key and not anthropic_key:
            print_colored("\n⚠️  No API keys found. You need at least one to use LAL.", "yellow")
        return
    
    prompt = sys.argv[1]
    execute = "--execute" in sys.argv or "-e" in sys.argv
    provider = None
    
    # Check for provider flag
    if "--provider" in sys.argv:
        idx = sys.argv.index("--provider")
        if idx + 1 < len(sys.argv):
            provider = sys.argv[idx + 1]
    
    # Get API keys
    anthropic_key = os.getenv('ANTHROPIC_API_KEY')
    openai_key = os.getenv('OPENAI_API_KEY')
    
    if not anthropic_key and not openai_key:
        print_colored("❌ No API keys found. Set ANTHROPIC_API_KEY or OPENAI_API_KEY", "red")
        return
    
    try:
        # Choose provider
        if provider == "openai":
            if not openai_key:
                print_colored("❌ OpenAI API key not set", "red")
                return
            command = make_openai_request(prompt, openai_key)
        elif provider == "anthropic":
            if not anthropic_key:
                print_colored("❌ Anthropic API key not set", "red")
                return
            command = make_anthropic_request(prompt, anthropic_key)
        else:
            # Auto-select (prefer Anthropic)
            if anthropic_key:
                command = make_anthropic_request(prompt, anthropic_key)
            else:
                command = make_openai_request(prompt, openai_key)
        
        # Display result
        print("╭─" + "─" * 50 + " Generated Command " + "─" * 50 + "─╮")
        print_colored(f"│ {command:<100} │", "green")
        print("╰─" + "─" * 100 + "─╯")
        
        if execute:
            response = input("\nExecute this command? [y/n]: ")
            if response.lower() == 'y':
                print(f"\nExecuting: {command}")
                os.system(command)
        else:
            print_colored("\n💡 Use --execute or -e flag to execute immediately", "blue")
            
    except Exception as e:
        print_colored(f"❌ Error: {str(e)}", "red")

if __name__ == '__main__':
    main() 