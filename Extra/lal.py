#!/usr/bin/env python3

import os
import sys
import click
import json
from typing import Optional
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Confirm
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

console = Console()

class AIProvider:
    """Base class for AI providers"""
    
    def generate_command(self, prompt: str) -> str:
        raise NotImplementedError

class OpenAIProvider(AIProvider):
    """OpenAI GPT provider"""
    
    def __init__(self, api_key: str, model: str = "gpt-4o-mini"):
        self.api_key = api_key
        self.model = model
        
    def generate_command(self, prompt: str) -> str:
        try:
            import openai
            client = openai.OpenAI(api_key=self.api_key)
            
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
            
            response = client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Command: {prompt}"}
                ],
                max_tokens=200,
                temperature=0.1
            )
            
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            raise Exception(f"OpenAI API error: {str(e)}")

class AnthropicProvider(AIProvider):
    """Anthropic Claude provider"""
    
    def __init__(self, api_key: str, model: str = "claude-3-5-haiku-20241022"):
        self.api_key = api_key
        self.model = model
        
    def generate_command(self, prompt: str) -> str:
        try:
            import anthropic
            client = anthropic.Anthropic(api_key=self.api_key)
            
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
            
            response = client.messages.create(
                model=self.model,
                max_tokens=200,
                temperature=0.1,
                system=system_prompt,
                messages=[
                    {"role": "user", "content": f"Command: {prompt}"}
                ]
            )
            
            return response.content[0].text.strip()
            
        except Exception as e:
            raise Exception(f"Anthropic API error: {str(e)}")

def get_ai_provider() -> AIProvider:
    """Get configured AI provider"""
    
    # Check for Anthropic first (more reliable on Apple Silicon)
    anthropic_key = os.getenv('ANTHROPIC_API_KEY')
    if anthropic_key:
        return AnthropicProvider(anthropic_key)
    
    # Check for OpenAI
    openai_key = os.getenv('OPENAI_API_KEY')
    if openai_key:
        return OpenAIProvider(openai_key)
    
    raise Exception("No AI provider configured. Set OPENAI_API_KEY or ANTHROPIC_API_KEY environment variable.")

@click.command()
@click.argument('prompt', required=False)
@click.option('--execute', '-e', is_flag=True, help='Execute the command immediately')
@click.option('--provider', '-p', type=click.Choice(['openai', 'anthropic']), help='Force specific AI provider')
@click.option('--model', '-m', help='Specify model to use')
@click.option('--config', is_flag=True, help='Configure API keys')
def main(prompt: Optional[str], execute: bool, provider: Optional[str], model: Optional[str], config: bool):
    """
    LAL - Natural Language to Shell Commands
    
    Convert natural language descriptions into shell commands using AI.
    
    Examples:
      lal "git push"
      lal "what's running on port 8000"
      lal "find large files in current directory"
    """
    
    if config:
        configure_api_keys()
        return
    
    if not prompt:
        console.print("💡 [yellow]Usage:[/] lal \"your command description\"")
        console.print("\n[dim]Examples:[/]")
        console.print("  lal \"git push\"")
        console.print("  lal \"what's running on port 8000\"")
        console.print("  lal \"find large files\"")
        console.print("\n[dim]Configuration:[/]")
        console.print("  lal --config  (to set up API keys)")
        return
    
    try:
        # Get AI provider
        if provider:
            if provider == 'openai':
                api_key = os.getenv('OPENAI_API_KEY')
                if not api_key:
                    console.print("[red]Error:[/] OPENAI_API_KEY not set")
                    return
                ai = OpenAIProvider(api_key, model or "gpt-4o-mini")
            elif provider == 'anthropic':
                api_key = os.getenv('ANTHROPIC_API_KEY')
                if not api_key:
                    console.print("[red]Error:[/] ANTHROPIC_API_KEY not set")
                    return
                ai = AnthropicProvider(api_key, model or "claude-3-5-haiku-20241022")
        else:
            ai = get_ai_provider()
        
        # Generate command
        with console.status("[yellow]Thinking...[/]"):
            command = ai.generate_command(prompt)
        
        # Display result
        console.print(Panel(
            f"[bold green]{command}[/]",
            title="Generated Command",
            border_style="green"
        ))
        
        # Execute if requested
        if execute:
            if Confirm.ask("Execute this command?"):
                console.print(f"\n[dim]Executing:[/] {command}")
                os.system(command)
        else:
            console.print("\n[dim]💡 Use -e flag to execute immediately[/]")
            
    except Exception as e:
        console.print(f"[red]Error:[/] {str(e)}")
        if "API" in str(e):
            console.print("\n[yellow]💡 Run 'lal --config' to set up your API keys[/]")

def configure_api_keys():
    """Interactive configuration of API keys"""
    console.print("[bold]🔧 LAL Configuration[/]\n")
    
    # Check current configuration
    openai_key = os.getenv('OPENAI_API_KEY')
    anthropic_key = os.getenv('ANTHROPIC_API_KEY')
    
    console.print("Current configuration:")
    console.print(f"  OpenAI API Key: {'✅ Set' if openai_key else '❌ Not set'}")
    console.print(f"  Anthropic API Key: {'✅ Set' if anthropic_key else '❌ Not set'}")
    
    console.print("\n[dim]To set up API keys, add them to your environment:[/]")
    console.print("\n[bold]For OpenAI:[/]")
    console.print("  export OPENAI_API_KEY='your-openai-api-key'")
    console.print("\n[bold]For Anthropic:[/]")
    console.print("  export ANTHROPIC_API_KEY='your-anthropic-api-key'")
    
    console.print("\n[dim]Or add them to a .env file in your home directory[/]")
    
    if not openai_key and not anthropic_key:
        console.print("\n[yellow]⚠️  No API keys found. You need at least one to use LAL.[/]")

if __name__ == '__main__':
    main() 