class Mcmd < Formula
  desc "Mac Command Helper - Terminal productivity toolkit"
  homepage "https://github.com/yourusername/mac-cmd-helper"
  url "https://github.com/yourusername/mac-cmd-helper/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "PUT_SHA256_HERE"
  license "MIT"

  depends_on "jq"

  def install
    bin.install "mac-cmd-helper-v2.sh" => "mcmd"
    prefix.install Dir["README*.md", "CHEATSHEET*.md", "QUICKSTART*.md", "UPGRADE_GUIDE.md", "INDEX.md", "FAQ.md", "PROJECT_SUMMARY_V2.md"]
  end

  test do
    assert_match "Mac Command Helper v", shell_output("#{bin}/mcmd version")
  end
end

