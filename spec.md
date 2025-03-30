Tool Overview
Name: repodump
Purpose: Extract and format the contents of a Git repository or normal directory for sharing with LLMs, with output to clipboard or stdout.
Key Features:

    Works with both Git repositories and normal directories.
    Skips binary files by default.
    Includes repository details (for Git repos) by default, with an opt-out option.
    Supports a .repodumpignore file for custom exclusions.
    Provides token count estimation using ttok (if available) or wc -w as a fallback.
    Outputs in Markdown by default for better LLM compatibility, with an option for plaintext.
    Optionally copies output to the clipboard.

Command Usage

repodump [options] [path/to/directory]

    If no path is provided, the tool defaults to the current directory (.).
    The directory can be either a Git repository or a normal directory.

Options

    --format=FORMAT: Set the output format.
        markdown (default): Formats output with Markdown headers and code blocks.
        text: Formats output with simple text separators.
    --no-repo-details: Exclude repository details (branch, commit, status) from the output (only applicable to Git repositories).
    --estimate-tokens: Estimate and display the token count for the included files instead of generating the full output.
    --clipboard: Copy the output directly to the system clipboard.
    --include-hidden: Include hidden files (e.g., dotfiles) when processing normal directories (hidden files are excluded by default).
    --help: Display usage information.
    --version: Display the tool’s version.

Behavior Based on Directory Type
For Git Repositories

    File Listing: Uses git ls-files to list tracked files.
    Repository Details: Included by default (unless --no-repo-details is specified).
        Current Branch: e.g., main.
        Latest Commit: Hash and message, e.g., abc123 "Initial commit".
        Status: e.g., clean or modified.
    Exclusions: Respects .repodumpignore and skips binary files.

For Normal Directories

    File Listing: Uses find to list files recursively, excluding hidden files by default (unless --include-hidden is specified).
    Repository Details: Not applicable; skipped automatically.
    Exclusions: Respects .repodumpignore and skips binary files.

File Filtering and Exclusions

    Binary Files: Automatically skipped using a null byte check (checks the first 1024 bytes for null bytes).
    .repodumpignore: A file in the directory root or ~/.config/repodump/ignore that specifies patterns to exclude (similar to .gitignore).
        Uses glob patterns (e.g., *.log, build/, *.tmp).
    Command-Line Exclusions: For simplicity in v1, we’ll rely on .repodumpignore rather than adding --exclude flags.

Output Formatting
Markdown Format (Default)

    Repository details (if included) are formatted as a Markdown section.
    Each file is presented with a header (## FILE: path/to/file.ext) and its content inside a code block with language hinting (e.g., `````python`).
    Example:

    ### Repository Details
    - **Branch:** main
    - **Latest Commit:** abc123 "Initial commit"
    - **Status:** clean

    ## FILE: src/main.py
    ```python
    print("Hello, world!")

Text Format

    Repository details (if included) are presented with simple text separators.
    Each file is preceded by a header (FILE: path/to/file.ext) and separators.
    Example:
    ```
    REPOSITORY DETAILS
    Branch: main
    Latest Commit: abc123 "Initial commit"
    Status: clean
    FILE: src/main.py
    print("Hello, world!")

Token Count Estimation

    Option: --estimate-tokens
    Behavior: Instead of generating the full output, the tool estimates the token count for all included text files.
    Method:
        If ttok is installed, it is used for accurate token counting (e.g., cat file | ttok).
        If ttok is not installed, it falls back to wc -w (word count) and displays a warning suggesting the installation of ttok for better accuracy.
    Output Example:

    Estimated token count: 1250
    (Note: For more accurate token counting, install `ttok`.)

Clipboard Integration

    Option: --clipboard
    Behavior: Copies the generated output directly to the system clipboard.
    Implementation:
        macOS: Uses pbcopy.
        Linux: Uses xclip -selection clipboard or wl-copy (for Wayland), detecting which is available.
        Falls back to stdout with a warning if no clipboard command is found.

Configuration File

    File Name: .repodump
    Locations: Looked for in the directory root or ~/.config/repodump/config.
    Format: Key-value pairs (e.g., FORMAT="text", EXCLUDE="*.log|*.tmp").
    Purpose: Allows users to set default behaviors (e.g., default format, exclusions).
    Override: Command-line options take precedence over config file settings.

Implementation Details
Script Structure
The bash script will follow this high-level structure:

    Default Settings
    bash

    FORMAT="markdown"
    INCLUDE_REPO_DETAILS=true  # For Git repos
    ESTIMATE_TOKENS=false
    USE_CLIPBOARD=false
    INCLUDE_HIDDEN=false
    VERSION="1.0.0"

    Function Definitions
        is_git_repo(): Checks for the presence of a .git directory.
        bash

        is_git_repo() {
            [ -d "$1/.git" ] && return 0 || return 1
        }

        list_files(): Lists files using git ls-files for Git repos or find for normal directories.
        bash

        list_files() {
            local dir="$1"
            local include_hidden="$2"
            if is_git_repo "$dir"; then
                git -C "$dir" ls-files
            elif [ "$include_hidden" = true ]; then
                find "$dir" -type f
            else
                find "$dir" -type f ! -path '*/\.*'
            fi
        }

        is_binary(): Checks if a file is binary by looking for null bytes.
        bash

        is_binary() {
            head -c 1024 "$1" | grep -q $'\0' && return 0 || return 1
        }

        read_ignore_file(): Reads and parses .repodumpignore.
        bash

        read_ignore_file() {
            local file="$1"
            while IFS= read -r pattern; do
                [[ -n "$pattern" && ! "$pattern" =~ ^# ]] && IGNORE_PATTERNS+=("$pattern")
            done < "$file"
        }

        format_output(): Generates the formatted output based on the specified format.
        estimate_tokens(): Estimates token count using ttok or wc -w.
        bash

        estimate_tokens() {
            local files=("$@")
            local total=0
            if command -v ttok >/dev/null 2>&1; then
                for file in "${files[@]}"; do
                    count=$(cat "$file" | ttok)
                    total=$((total + count))
                done
            else
                for file in "${files[@]}"; do
                    count=$(wc -w < "$file")
                    total=$((total + count))
                done
                echo "(Note: For more accurate token counting, install 'ttok'.)" >&2
            fi
            echo "Estimated token count: $total"
        }

        copy_to_clipboard(): Copies output to the clipboard using the appropriate command.
        bash

        copy_to_clipboard() {
            if command -v pbcopy >/dev/null 2>&1; then
                echo "$1" | pbcopy
            elif command -v xclip >/dev/null 2>&1; then
                echo "$1" | xclip -selection clipboard
            elif command -v wl-copy >/dev/null 2>&1; then
                echo "$1" | wl-copy
            else
                echo "Warning: No clipboard command found. Outputting to stdout instead." >&2
                echo "$1"
            fi
        }

    Option Parsing
        Use a while loop with case to parse command-line options and set variables.
    Directory Handling
        Default to current directory if no path is provided.
        Validate directory existence and accessibility.
    File Processing
        List files based on directory type.
        Filter out binary files and files matching ignore patterns.
        Handle token estimation or output generation.
    Output Handling
        Copy to clipboard if requested, otherwise print to stdout.

Key Implementation Notes

    File Listing for Normal Directories: Use find . -type f ! -path '*/\.*' to exclude hidden files by default, or find . -type f if --include-hidden is set.
    Binary File Detection: Use head -c 1024 "$file" | grep -q $'\0' for efficiency.
    Token Estimation: Sum counts from ttok or wc -w across all files.
    Error Handling: Check for invalid directories, missing dependencies, and provide clear error messages.
    Special Characters: Use proper quoting in bash to handle filenames with spaces or special characters.

Open-Source and Homebrew Preparation
Repository Setup

    Create a GitHub repository (e.g., github.com/yourusername/repodump).
    Include the bash script, a README.md, and an MIT license.

Documentation

    README.md:
        Purpose, installation, usage examples, and configuration details.
        Instructions for installing ttok (e.g., brew install ttok or equivalent).

Versioning

    Define VERSION="1.0.0" in the script.
    Support --version to display it.

Testing

    Test with Git repositories and normal directories.
    Verify options like --estimate-tokens, --clipboard, and --format.

Homebrew Formula

    Create repodump.rb:
    ruby

    class Repodump < Formula
      desc "Extract and format directory contents for LLMs"
      homepage "https://github.com/yourusername/repodump"
      url "https://github.com/yourusername/repodump/archive/refs/tags/v1.0.0.tar.gz"
      sha256 "compute-this-after-tagging"
      license "MIT"

      def install
        bin.install "repodump"
      end

      test do
        system "#{bin}/repodump", "--version"
      end
    end

    Tag the release and submit to Homebrew/homebrew-core.

Final Specification Summary

    Tool Name: repodump
    Version: 1.0.0
    Purpose: Share directory or Git repository contents with LLMs.
    Usage: repodump [options] [path/to/directory]
    Key Features:
        Supports Git repositories and normal directories.
        Skips binary files.
        Includes repository details by default (for Git repos).
        Uses .repodumpignore for exclusions.
        Estimates tokens with ttok or wc -w.
        Outputs in Markdown by default, with clipboard support.
    License: MIT

This specification provides a detailed roadmap for implementing repodump. Let me know if you’d like me to proceed with coding the script or if any adjustments are needed!