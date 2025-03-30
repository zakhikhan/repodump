class Repodump < Formula
    desc "Extract and format directory contents for LLMs"
    homepage "https://github.com/zakhikhan/repodump"
    url "https://github.com/zakhikhan/repodump/archive/refs/tags/v1.0.0.tar.gz"
    sha256 "compute-this-after-tagging"
    license "MIT"
  
    def install
      bin.install "repodump"
    end
  
    test do
      system "#{bin}/repodump", "--version"
    end
  end