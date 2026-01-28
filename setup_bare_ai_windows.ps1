# setup_bare_ai_windows.ps1

# --- Configuration ---
$USER_PROFILE = $env:USERPROFILE
$BARE_AI_DIR = Join-Path $USER_PROFILE ".bare-ai"
$GEMINI_CLI_CMD = "gemini" # Command name for Gemini CLI

# --- Helper Functions for Output ---
function Write-ColoredOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Green", "Yellow", "Red", "NC")] # NC for No Color
        [string]$Color
    )
    $colorMap = @{
        "Green" = "Green";
        "Yellow" = "Yellow";
        "Red" = "Red";
        "NC" = "Gray" # Default to Gray for No Color
    }
    $consoleColor = $colorMap[$Color]
    # Temporarily change console color, then restore it
    $originalBgColor = $Host.UI.RawUI.BackgroundColor
    $originalFgColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $consoleColor
    Write-Host $Message
    $Host.UI.RawUI.ForegroundColor = $originalFgColor # Restore original foreground color
    $Host.UI.RawUI.BackgroundColor = $originalBgColor # Restore original background color
}

# --- Gemini CLI Check and Installation Instructions ---
Write-ColoredOutput -Message "Checking for Gemini CLI..." -Color Yellow
if (-not (Get-Command $GEMINI_CLI_CMD -ErrorAction SilentlyContinue)) {
    Write-ColoredOutput -Message "Gemini CLI not found." -Color Red
    Write-ColoredOutput -Message "Attempting to provide installation instructions for Gemini CLI and its dependencies (Python/Node.js)." -Color Yellow

    # Instructions for Python (pip)
    Write-ColoredOutput -Message "1. Install Python: If you don't have Python installed, download it from python.org and ensure 'Add Python to PATH' is checked during installation." -Color Yellow
    Write-ColoredOutput -Message "   After installation, open a NEW PowerShell window and run: `pip install google-generativeai`" -Color Yellow

    # Instructions for Node.js (npm)
    Write-ColoredOutput -Message "2. Install Node.js: If you don't have Node.js and npm installed, download them from nodejs.org." -Color Yellow
    Write-ColoredOutput -Message "   After installation, open a NEW PowerShell window and run: `npm install -g @google/gemini-cli`" -Color Yellow

    Write-ColoredOutput -Message "If the above commands fail, please refer to the official Gemini CLI documentation for manual installation steps." -Color Yellow
    Write-ColoredOutput -Message "After installation, please close and re-open this PowerShell window and re-run this script." -Color Red
    exit 1
} else {
    Write-ColoredOutput -Message "Gemini CLI found." -Color Green
}

# --- Create Directory Structure ---
Write-ColoredOutput -Message "Creating BARE-AI configuration directory: $BARE_AI_DIR..." -Color Yellow
try {
    New-Item -ItemType Directory -Force -Path $BARE_AI_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $BARE_AI_DIR "diary") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $BARE_AI_DIR "logs") | Out-Null
    Write-ColoredOutput -Message "BARE-AI directories created successfully." -Color Green
} catch {
    Write-ColoredOutput -Message "Error creating BARE-AI directories: $($_.Exception.Message)" -Color Red
    exit 1
}

# --- Create constitution.md ---
$TODAY = Get-Date -Format "yyyy-MM-dd"
$CONSTITUTION_CONTENT = @"
MISSION: You are an autonomous Linux Agent for "Self-Healing" pipelines. RULES: > 1. Use sudo DEBIAN_FRONTEND=noninteractive for updates to prevent UI hangs. 2. Always verify JSON/file integrity before reporting success. 3. Log all actions to ~/.bare-ai/diary/{{DATE}}.md.
"@
# Note: The original script replaces {{DATE}} when the 'bare' command is run, not during setup.
# The template above will be used by the 'bare' command later.

Write-ColoredOutput -Message "Creating $BARE_AI_DIR\constitution.md..." -Color Yellow
try {
    $CONSTITUTION_CONTENT | Set-Content -Path (Join-Path $BARE_AI_DIR "constitution.md") -Encoding UTF8
    Write-ColoredOutput -Message "Constitution file created successfully." -Color Green
} catch {
    Write-ColoredOutput -Message "Error creating constitution.md: $($_.Exception.Message)" -Color Red
    exit 1
}

# --- Create README.md ---
$README_CONTENT = @"
# BARE-AI Setup and Configuration

This directory (`$BARE_AI_DIR`) stores the persistent configuration and memory for the BARE-AI agent.

## Directory Structure

- **`$BARE_AI_DIR\`**: The root directory for BARE-AI's configuration.
    - **`constitution.md`**: Contains the core identity, mission, and operational rules for the BARE-AI agent.
    - **`diary\`**: A subdirectory to store daily logs for each session. The filename format is `YYYY-MM-DD.md`.
    - **`logs\`**: Stores session transcripts for error recovery purposes.

## Gemini CLI and API Key Setup

1.  **Gemini CLI Installation:** This script checks for the `$GEMINI_CLI_CMD` command. If it's not found, it provides instructions to install it using `pip` (for `google-generativeai`) or `npm` (for `@google/gemini-cli`). Ensure Python and Node.js are installed and in your system's PATH.
    *   Install Python: Download from python.org, ensure 'Add Python to PATH' is checked. Then run: `pip install google-generativeai` in a new PowerShell window.
    *   Install Node.js: Download from nodejs.org. Then run: `npm install -g @google/gemini-cli` in a new PowerShell window.
    If automatic installation fails, consult the official Gemini CLI documentation.

2.  **API Key:** The Gemini CLI requires an API key for authentication. You need to set this as an environment variable.
    Add the following line to your PowerShell profile script (e.g., `$PROFILE`), replacing `YOUR_GEMINI_API_KEY` with your actual key:
    ```powershell
    $env:GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
    ```
    After adding this, run `$PROFILE` or restart PowerShell. You can check if it's set by running `echo $env:GEMINI_API_KEY`.

## BARE-AI Agent Command

To make the BARE-AI agent command available, you can create a PowerShell profile script or a custom batch file.

**Option 1: Using a PowerShell Profile Script (Recommended)**
1.  Find your PowerShell profile path by running: `$PROFILE`
2.  If the file doesn't exist, create it: `New-Item -Path $PROFILE -ItemType File -Force`
3.  Edit the profile script: `notepad $PROFILE`
4.  Add the following function to your `$PROFILE` file:

    ```powershell
    # BARE-AI Agent Function
    function bare {
        $TODAY = Get-Date -Format "yyyy-MM-dd"
        $BARE_AI_DIR = Join-Path $env:USERPROFILE ".bare-ai"
        $CONSTITUTION = Join-Path $BARE_AI_DIR "constitution.md"
        $DIARY = Join-Path $BARE_AI_DIR "diary\$TODAY.md"

        # Ensure diary directory exists for the session
        if (-not (Test-Path (Split-Path $DIARY))) {
            New-Item -ItemType Directory -Force -Path (Split-Path $DIARY) | Out-Null
        }
        # Ensure diary file exists
        if (-not (Test-Path $DIARY)) {
            New-Item -ItemType File -Path $DIARY | Out-Null
        }

        # Safety check: Ensure constitution.md exists before proceeding
        if (-not (Test-Path $CONSTITUTION)) {
            Write-Error "Error: Constitution file not found at $CONSTITUTION. Exiting."
            return
        }

        # Initialize Gemini with Mission + Current Diary Context
        # Fetch constitution content and replace the {{DATE}} placeholder.
        $constitutionContent = Get-Content $CONSTITUTION -Raw
        $constitutionContent = $constitutionContent -replace '\{\{DATE\}\}', $TODAY # Using regex for {}

        # Pass the modified constitution content to Gemini
        # Ensure GEMINI_API_KEY is set before running this command.
        # Use '&' to execute external commands like 'gemini'
        & $GEMINI_CLI_CMD -m gemini-2.5-flash-lite -i $constitutionContent
    }
    # Ensure the GEMINI_API_KEY environment variable is set.
    # $env:GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
    "@

    Write-ColoredOutput -Message "Added BARE-AI function to your PowerShell profile: $PROFILE" -Color Green
    Write-ColoredOutput -Message "Please restart PowerShell or run `. $PROFILE` to activate the 'bare' command." -Color Yellow

"@

Write-ColoredOutput -Message "Creating $BARE_AI_DIR\README.md..." -Color Yellow
try {
    $README_CONTENT | Set-Content -Path (Join-Path $BARE_AI_DIR "README.md") -Encoding UTF8
    Write-ColoredOutput -Message "README file created successfully." -Color Green
} catch {
    Write-ColoredOutput -Message "Error creating README.md: $($_.Exception.Message)" -Color Red
    exit 1
}

# --- Instructions for making 'bare' command available ---
Write-ColoredOutput -Message "--------------------------------------------------" -Color NC
Write-ColoredOutput -Message "BARE-AI setup script finished." -Color Green
Write-ColoredOutput -Message "Please follow the instructions in '$BARE_AI_DIR\README.md' for:" -Color Yellow
Write-ColoredOutput -Message "  1. Gemini CLI installation (if not already done)." -Color Yellow
Write-ColoredOutput -Message "  2. Setting your Gemini API Key environment variable." -Color Yellow
Write-ColoredOutput -Message "  3. Activating the 'bare' command by adding the function to your PowerShell profile." -Color Yellow
Write-ColoredOutput -Message "--------------------------------------------------" -Color NC
