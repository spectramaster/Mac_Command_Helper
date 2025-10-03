#!/usr/bin/env bash
set -euo pipefail

# Simple release helper for maintainers
# - Creates a tarball under dist/
# - Computes sha256
# - Generates a Homebrew formula file under dist/mcmd.rb
# - Optionally creates a GitHub release if gh CLI is available

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
DIST_DIR="$ROOT_DIR/dist"
FORMULA_OUT="$DIST_DIR/mcmd.rb"

VERSION="${1:-}"
REPO="yourusername/mac-cmd-helper"   # TODO: set your GitHub repo

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version> (e.g., 2.1.0)" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"

TARBALL="mcmd-v$VERSION.tar.gz"
TARBALL_PATH="$DIST_DIR/$TARBALL"

echo "-> Building tarball: $TARBALL_PATH"

# Prefer git archive if .git exists; otherwise tar working tree
if [ -d "$ROOT_DIR/.git" ] && command -v git >/dev/null 2>&1; then
  (cd "$ROOT_DIR" && git archive --format=tar.gz -o "$TARBALL_PATH" --prefix="mac-cmd-helper-$VERSION/" "HEAD")
else
  (cd "$ROOT_DIR" && tar --exclude=".git" --exclude="dist" -czf "$TARBALL_PATH" .)
fi

SHA256=$(shasum -a 256 "$TARBALL_PATH" | awk '{print $1}')
echo "-> sha256: $SHA256"

TARBALL_URL="https://github.com/$REPO/archive/refs/tags/v$VERSION.tar.gz"

cat > "$FORMULA_OUT" <<EOF
class Mcmd < Formula
  desc "Mac Command Helper - Terminal productivity toolkit"
  homepage "https://github.com/$REPO"
  url "$TARBALL_URL"
  sha256 "$SHA256"
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
EOF

echo "-> Wrote Homebrew formula to: $FORMULA_OUT"

if command -v gh >/dev/null 2>&1; then
  echo "-> gh detected. You can create a release with:"
  echo "   gh release create v$VERSION $TARBALL_PATH --title \"v$VERSION\" --notes-file CHANGELOG.md"
fi

cat <<MSG

Next steps:
1) Create a Git tag v$VERSION and push it (or use gh to create a release)
2) Create (or update) your tap repo: github.com/<user>/homebrew-tap
3) Commit dist/mcmd.rb to the tap under Formula/mcmd.rb
4) Users can then install via:
   brew tap <user>/tap
   brew install mcmd

MSG

