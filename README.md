# repodump

`repodump` is a command-line tool that extracts and formats the contents of a Git repository as markdown, making it easy to share with large language models (LLMs) or other applications. It works on both **Git repositories** and **regular directories**, automatically adapting its behavior. It outputs the contents to stdout in a structured format, which you can pipe into your preferred copy command for seamless integration into your workflow.

## Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
- [Usage](#usage)
- [Including and Excluding Files](#including-and-excluding-files)
- [Output Format](#output-format)
- [Token Estimation](#token-estimation)
- [Exclusions](#exclusions)
- [Copying Output](#copying-output)
- [Debugging](#debugging)
- [License](#license)

## Introduction
`repodump` is designed to help you quickly dump the contents of a directory or Git repository into a format that's easy to copy and paste—ideal for sharing code with LLMs or collaborators. It skips binary files by default and automatically respects your `.gitignore` files, so you don't have to worry about including unnecessary files. For more granular control, you can also use a `.repodumpignore` file or command-line flags to further customize what gets included.

**Key Features**:
- Works seamlessly with both Git repositories and standard directories.
- Automatically detects and skips binary files.
- Respects `.gitignore` rules by default.
- Supports `.repodumpignore` and command-line flags for custom inclusions/exclusions.
- Provides Markdown or plain text output formats.
- Includes language detection (via extension and shebang) for Markdown code blocks.
- Offers token estimation using `ttok` or `wc`.
- Provides dry-run and debug modes for testing and troubleshooting.

Following the Unix philosophy, `repodump` focuses on generating formatted output and leaves copying to other specialized tools. By piping its output to your preferred copy command, you can customize it to your platform and preferences.

## Installation
To install `repodump`, download the script and make it executable:

```bash
curl -fsSL https://github.com/zakhikhan/repodump/raw/main/repodump -o repodump
chmod +x repodump
sudo mv repodump /usr/local/bin/
```

Future Homebrew support is planned

## Usage
Run repodump with a path to a Git repository or directory:

```bash
repodump /path/to/directory | pbcopy
```

If no path is provided, it defaults to the current directory (`.`).

### Command-Line Options

- `--format=FORMAT`: Set output format: `markdown` (default) or `text`.
- `--no-repo-details`: Exclude repository details (branch, commit, status) when run in a Git repo.
- `--estimate-tokens`: Estimate token count instead of generating full output.
- `--include-hidden`: Include hidden files (starting with `.`) in non-Git directories.
- `--include=PATTERN`: Include only files matching the glob pattern (can be used multiple times). If used, only matching files are considered.
- `--exclude=PATTERN`: Exclude files matching the glob pattern (can be used multiple times).
- `--debug`: Enable detailed debug output to stderr.
- `--dry-run`: Show which files would be included without generating full output.
- `--help`: Display the help message.
- `--version`: Display version information.

### Examples

- Dump the current directory (respecting `.gitignore`):
  ```bash
  repodump
  ```

- Dump a specific directory:
  ```bash
  repodump ~/projects/my-repo
  ```

- Dump a non-Git directory, including hidden files:
  ```bash
  repodump /path/to/non-git-dir --include-hidden
  ```

- Include only JavaScript and CSS files, excluding the `vendor` directory:
  ```bash
  repodump --include='*.js' --include='*.css' --exclude='vendor/*'
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
repodump offers several ways to control which files are included in the output, applied in this order:

1.  **File Listing**: Based on whether it's a Git repo (`git ls-files`) or a standard directory (`find`). Hidden files in standard directories are ignored unless `--include-hidden` is used.
2.  **Include Patterns (`--include=PATTERN`)**: If one or more `--include` patterns are provided, only files matching at least one of these patterns are considered for inclusion. Files not matching any include pattern are skipped at this stage.
3.  **Exclude Patterns (`.gitignore`, `.repodumpignore`, `--exclude=PATTERN`)**: Files matching exclude patterns are removed. See the [Exclusions](#exclusions) section for details on precedence.
4.  **Binary File Check**: Files detected as binary are skipped.

This allows for flexible control over the final set of files included in the dump.

## Output Format
By default, repodump outputs in Markdown, using headers and code blocks for clarity—perfect for LLMs. It attempts to add language hints to the Markdown code blocks based first on the file extension and then by checking the shebang line (e.g., `#!/bin/bash`) for files without recognized extensions.

You can switch to plaintext if desired:

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

This uses [ttok](https://github.com/simonw/ttok) for accuracy (if installed) or falls back to `wc -w` with a warning. Install ttok for better precision:

```bash
pip install ttok
```

or

```bash
brew install simonw/llm/ttok
```

## Exclusions
repodump automatically skips binary files and uses multiple sources for exclusion patterns, applied in a specific order:

1.  **Default `.gitignore` Behavior**: For Git repositories, `git ls-files` automatically respects `.gitignore` rules. For regular directories with a `.gitignore` file, repodump reads and applies those patterns by default *if* no `.repodumpignore` file is found in the same directory.

2.  **Global Ignore File (`~/.config/repodump/ignore`)**: If this file exists, its patterns are added to the exclusion list. This allows for user-wide exclusions.

3.  **Local `.repodumpignore` File**: If present in the target directory, its patterns are added. The presence of this file prevents the automatic loading of `.gitignore` in non-Git directories.

4.  **Command-Line Exclusions (`--exclude=PATTERN`)**: Patterns specified via the `--exclude` flag are added last, allowing for on-the-fly overrides.

This layered approach ensures that repodump works intelligently out of the box while still giving you the flexibility to customize its behavior for your specific needs.

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

You can also redirect to a file (`> output.md`) or use tools like `tee` to both save and copy.

## Debugging
repodump provides several options for debugging and previewing output:

- **Dry Run (`--dry-run`)**: Preview which files would be included without generating the full output. This shows a summary of included files, their sizes, and detected languages.
  ```bash
  repodump --dry-run
  ```

- **Debug Mode (`--debug`)**: Enable verbose output sent to stderr to troubleshoot pattern matching, file detection, and other internal processes. This won't affect the main stdout output.
  ```bash
  repodump --debug
  ```

## License
repodump is licensed under the MIT License. See LICENSE for details.