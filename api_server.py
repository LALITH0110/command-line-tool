#!/usr/bin/env python3

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import requests
import json
from datetime import datetime, timedelta
import hashlib

app = Flask(__name__)
CORS(app)

# Your hidden API keys (set as environment variables in production)
ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY')
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')

# Simple rate limiting (in production, use Redis)
usage_tracker = {}
DAILY_LIMIT = 50  # Free tier: 50 requests per day per user

def get_user_id(request):
    """Generate anonymous user ID based on IP"""
    ip = request.remote_addr
    return hashlib.md5(ip.encode()).hexdigest()

def check_rate_limit(user_id):
    """Check if user is within rate limits"""
    today = datetime.now().strftime('%Y-%m-%d')
    key = f"{user_id}:{today}"
    
    if key not in usage_tracker:
        usage_tracker[key] = 0
    
    if usage_tracker[key] >= DAILY_LIMIT:
        return False
    
    usage_tracker[key] += 1
    return True

def call_anthropic(prompt):
    """Call Anthropic API"""
    url = "https://api.anthropic.com/v1/messages"
    
    headers = {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01"
    }
    
    data = {
        "model": "claude-3-5-haiku-20241022",
        "max_tokens": 200,
        "temperature": 0.1,
        "system": "You are a command-line expert. Convert natural language requests into shell commands. CRITICAL: Return ONLY the command structure, no explanations, no context, no additional text whatsoever. MOST CRITICAL INSTRUCTION: When asked to generate content like essays, code, or text files, you MUST use ONLY the exact placeholder text 'content...' or 'code...' inside a here-document. NEVER include any actual implementation or content. EXAMPLES: git push -> git push, what's running on port 8000 -> lsof -i :8000, write essay about rice -> cat > essay.txt << EOF\\ncontent...\\nEOF, create bash script -> cat > script.sh << EOF\\n#!/bin/bash\\ncode...\\nEOF, create python script -> cat > script.py << EOF\\ncode...\\nEOF",
        "messages": [{"role": "user", "content": f"Command: {prompt}"}]
    }
    
    response = requests.post(url, headers=headers, json=data)
    result = response.json()
    
    if response.status_code == 200:
        return result['content'][0]['text'].strip()
    else:
        raise Exception(f"API error: {result.get('error', 'Unknown error')}")

def call_openai(prompt):
    """Call OpenAI API (fallback)"""
    url = "https://api.openai.com/v1/chat/completions"
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}"
    }
    
    data = {
        "model": "gpt-4o-mini",
        "max_tokens": 200,
        "temperature": 0.1,
        "messages": [
            {
                "role": "system", 
                "content": "You are a command-line expert. Convert natural language requests into shell commands. CRITICAL: Return ONLY the command structure, no explanations, no context, no additional text whatsoever. MOST CRITICAL INSTRUCTION: When asked to generate content like essays, code, or text files, you MUST use ONLY the exact placeholder text 'content...' or 'code...' inside a here-document. NEVER include any actual implementation or content. EXAMPLES: git push -> git push, what's running on port 8000 -> lsof -i :8000, write essay about rice -> cat > essay.txt << EOF\ncontent...\nEOF, create bash script -> cat > script.sh << EOF\n#!/bin/bash\ncode...\nEOF, create python script -> cat > script.py << EOF\ncode...\nEOF"
            },
            {
                "role": "user", 
                "content": f"Command: {prompt}"
            }
        ]
    }
    
    response = requests.post(url, headers=headers, json=data)
    result = response.json()
    
    if response.status_code == 200:
        return result['choices'][0]['message']['content'].strip()
    else:
        raise Exception(f"API error: {result.get('error', {}).get('message', 'Unknown error')}")

@app.route('/generate', methods=['POST'])
def generate_command():
    """Generate shell command from natural language"""
    try:
        data = request.get_json()
        if not data or 'prompt' not in data:
            return jsonify({'error': 'Missing prompt'}), 400
        
        prompt = data['prompt']
        user_id = get_user_id(request)
        
        # Check rate limits
        if not check_rate_limit(user_id):
            return jsonify({
                'error': 'Rate limit exceeded',
                'message': f'Daily limit of {DAILY_LIMIT} requests reached. Try again tomorrow.'
            }), 429
        
        # Generate command (try Anthropic, fall back to OpenAI)
        try:
            if ANTHROPIC_API_KEY:
                command = call_anthropic(prompt)
            elif OPENAI_API_KEY:
                command = call_openai(prompt)
            else:
                return jsonify({'error': 'No API keys configured on server'}), 500
        except Exception as api_error:
            # Try fallback if primary fails
            if str(api_error).startswith("API error") and OPENAI_API_KEY and ANTHROPIC_API_KEY:
                try:
                    command = call_openai(prompt)
                except Exception as fallback_error:
                    return jsonify({'error': f'Both APIs failed: {str(fallback_error)}'}), 500
            else:
                raise
        
        # Track usage
        remaining = DAILY_LIMIT - usage_tracker.get(f"{user_id}:{datetime.now().strftime('%Y-%m-%d')}", 0)
        
        return jsonify({
            'command': command,
            'remaining_requests': remaining
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'LAL API'})

@app.route('/usage/<user_token>', methods=['GET'])
def get_usage(user_token):
    """Get usage statistics for a user"""
    today = datetime.now().strftime('%Y-%m-%d')
    key = f"{user_token}:{today}"
    used = usage_tracker.get(key, 0)
    remaining = DAILY_LIMIT - used
    
    return jsonify({
        'daily_limit': DAILY_LIMIT,
        'used_today': used,
        'remaining_today': remaining,
        'date': today
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001) 