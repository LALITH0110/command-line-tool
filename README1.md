# LAL - Natural Language to Shell Commands 🚀

Convert natural language into shell commands using AI - without needing API keys!

## Usage

```bash
lal "find large files in current directory"
```

Output:
```
🤔 Thinking...

find . -type f -size +100M
```

## Features

- **Simple**: Just type what you want to do in natural language
- **Fast**: Get shell commands instantly
- **No API Keys**: Powered by LAL Cloud (free tier included)
- **Execute**: Optional -e flag to run commands immediately
- **Universal**: Works on any Unix-like system (macOS, Linux)

## Installation

### Homebrew (recommended for macOS)

```bash
brew install yourusername/tap/lal
```

### Direct Install (Linux/macOS)

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/lal/main/install.sh | bash
```

### Manual Install

```bash
# Clone the repository
git clone https://github.com/yourusername/lal.git
cd lal

# Make executable
chmod +x lal_cloud.sh

# Link to your PATH
sudo ln -sf "$(pwd)/lal_cloud.sh" /usr/local/bin/lal
```

## Examples

- **Git operations**: `lal "git push and create upstream branch"`
- **Docker management**: `lal "stop all docker containers"`
- **File operations**: `lal "find files modified in last 7 days"`
- **Process monitoring**: `lal "what's using port 3000"`
- **System information**: `lal "show memory and cpu usage"`
- **Network diagnostics**: `lal "check if port 22 is open"`
- **Text processing**: `lal "count lines in all python files"`

## Options

- `-e, --execute`: Execute command immediately (with confirmation)
- `--usage`: Check your daily usage statistics
- `--help`: Show detailed help

## Deploying Your Own LAL API Server

If you want to run your own LAL API service:

### 1. Quick Deploy on Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/fSgafU)

### 2. Quick Deploy on Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fyourusername%2Flal)

### 3. Manual Deployment

```bash
# Clone the repository
git clone https://github.com/yourusername/lal.git
cd lal

# Install requirements
pip install -r api_requirements.txt

# Set environment variables
export ANTHROPIC_API_KEY=your_api_key_here
export OPENAI_API_KEY=your_api_key_here

# Start server
gunicorn -w 4 -b 0.0.0.0:5000 api_server:app
```

## Self-hosting Configuration

If you're running your own LAL API server, configure clients:

```bash
# Set your API endpoint
export LAL_API_URL=https://your-lal-api.com

# Install LAL client
curl -sSL https://raw.githubusercontent.com/yourusername/lal/main/install.sh | bash
```

## Privacy and Usage Limits

- Free tier: 50 commands per day per IP address
- No user data is stored beyond daily usage statistics
- API requests are anonymized using IP hashing
- Commands are not logged or stored after processing

## License

MIT 