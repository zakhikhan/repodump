class Repodump < Formula
    desc "Extract and format directory contents for LLMs"
    homepage "https://github.com/zakhikhan/repodump"
    url "https://github.com/zakhikhan/repodump/archive/refs/tags/v0.1-alpha.tar.gz"
    sha256 "compute-this-after-tagging"
    license "MIT"
  
    def install
      bin.install "repodump"
    end
  
    test do
      system "#{bin}/repodump", "--version"
    end
  end
  test do
    # Test the --help flag
    assert_match "Usage:", shell_output("#{bin}/repodump --help 2>&1")
  
    # Create test files in the temporary testpath directory
    (testpath/"file1.txt").write "Hello"
    (testpath/"file2.txt").write "World"
  
    # Test default behavior
    output = shell_output("#{bin}/repodump #{testpath}")
    assert_includes output, "Hello"
    assert_includes output, "World"
  
    # Test the --estimate-tokens flag
    token_output = shell_output("#{bin}/repodump --estimate-tokens #{testpath}")
    assert_match /Estimated token count: \d+/, token_output
  end