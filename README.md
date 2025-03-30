# repodump

`repodump` is a command-line tool that extracts and formats the contents of a Git repository or a normal directory, making it easy to share with large language models (LLMs) or other applications. It outputs the contents to stdout in a structured format, which you can pipe into your preferred copy command for seamless integration into your workflow.

## Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
- [Usage](#usage)
- [Including and Excluding Files](#including-and-excluding-files)
- [Output Format](#output-format)
- [Token Estimation](#token-estimation)
- [Exclusions](#exclusions)
- [Copying Output](#copying-output)
- [Advanced Options](#advanced-options)
- [Debugging](#debugging)
- [License](#license)

## Introduction
`repodump` is designed to help you quickly dump the contents of a directory or Git repository into a format that's easy to copy and paste—ideal for sharing code with LLMs or collaborators. It skips binary files by default and allows you to exclude specific files or directories using a `.repodumpignore` file or command-line flags.

Following the Unix philosophy, `repodump` focuses on generating formatted output and leaves copying to other specialized tools. By piping its output to your preferred copy command, you can customize it to your platform and preferences.

## Installation
To install `repodump`, download the script and make it executable:

```bash
curl -fsSL https://github.com/zakhikhan/repodump/raw/main/repodump -o repodump
chmod +x repodump
sudo mv repodump /usr/local/bin/
```

Future Homebrew support is planned:
```bash
brew install repodump
```

## Usage
Run repodump with a path to a Git repository or directory:

```bash
repodump /path/to/directory
```

If no path is provided, it defaults to the current directory (`.`).

### Examples

- Dump the current directory:
  ```bash
  repodump
  ```

- Dump a specific directory:
  ```bash
  repodump ~/projects/my-repo
  ```

- Estimate token count for the output:
  ```bash
  repodump --estimate-tokens
  ```

- Preview which files would be included without generating full output:
  ```bash
  repodump --dry-run
  ```

- Enable detailed debug output:
  ```bash
  repodump --debug
  ```

## Including and Excluding Files
repodump offers command-line flags to include or exclude specific files or directories, giving you precise control over the output.

- `--include=PATTERN`: Include files matching the specified pattern (e.g., `--include="*.py"` to include only Python files).
- `--exclude=PATTERN`: Exclude files matching the specified pattern (e.g., `--exclude="*.log"` to exclude log files).

You can use these flags multiple times to specify multiple patterns. For example:

```bash
repodump --include="src/*.py" --exclude="tests/*"
```

This command includes only Python files in the src directory and excludes all files in the tests directory.

## Output Format
By default, repodump outputs in Markdown, using headers and code blocks for clarity—perfect for LLMs. You can switch to plaintext if desired:

- Markdown (default):
  ```bash
  repodump --format=markdown
  ```

- Plaintext:
  ```bash
  repodump --format=text
  ```

For Git repositories, it includes branch and commit details by default. Use `--no-repo-details` to omit them.

## Token Estimation
To estimate the token count (useful for LLM input limits), use:

```bash
repodump --estimate-tokens
```

This uses ttok for accuracy (if installed) or falls back to wc -w with a warning. Install ttok for better precision:

```bash
pip install ttok
```

or

```bash
brew install simonw/llm/ttok
```

## Exclusions
repodump automatically skips binary files to ensure only text-based content is included. You can also define custom exclusions using a .repodumpignore file or command-line flags.

- **.repodumpignore**: If present in the directory root or `~/.config/repodump/ignore`, this file lists patterns to exclude (similar to .gitignore). For example:
  ```
  *.log
  build/
  *.tmp
  ```

- **Default Exclusions**: If .repodumpignore is not found, repodump will ignore files listed in .gitignore (if present) by default. This ensures compatibility with Git's exclusion patterns when no custom ignore file is provided.

- **Command-Line Exclusions**: Use the `--exclude` flag to specify additional patterns on the fly.

Combining these options allows you to tailor the output to your needs.

## Copying Output
repodump sends its output to stdout, letting you pipe it to your preferred copy command. This approach gives you flexibility to adapt it to your platform or workflow.

### Platform-Specific Copy Commands

- **macOS**:
  ```bash
  repodump | pbcopy
  ```

- **Linux (X11)**:
  ```bash
  repodump | xclip -selection clipboard
  ```

- **Linux (Wayland)**:
  ```bash
  repodump | wl-copy
  ```

- **Windows (WSL or Git Bash)**:
  ```bash
  repodump | clip.exe
  ```

- **Termux (Android)**:
  ```bash
  repodump | termux-clipboard-set
  ```

You can also redirect to a file (`> output.md`) or use tools like tee to both save and copy.

## Advanced Options
The `--clipboard` flag attempts to copy directly to the clipboard using common tools, but piping to a copy command is recommended for full control:

```bash
repodump --clipboard
```

## Debugging
repodump provides several options for debugging and previewing output:

- **Dry Run**: Preview which files would be included without generating the full output:
  ```bash
  repodump --dry-run
  ```
  This shows a summary of which files would be processed, their sizes, and detected languages.

- **Debug Mode**: Enable verbose output to troubleshoot pattern matching and file processing:
  ```bash
  repodump --debug
  ```
  Debug output is sent to stderr and won't affect the main output format.

- **Shebang Detection**: For files without extensions, repodump will examine the shebang line (e.g., `#!/bin/bash`) to detect the language and apply the appropriate syntax highlighting in the output.

## License
repodump is licensed under the MIT License. See LICENSE for details.