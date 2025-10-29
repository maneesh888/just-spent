#!/bin/bash

# ============================================================================
# Just Spent - Install Git Hooks and Setup Local CI
# ============================================================================
# Sets up the local CI environment and installs git hooks
#
# Usage:
#   ./scripts/install-hooks.sh
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Just Spent - Local CI Setup                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
  echo "❌ Error: Not a git repository"
  exit 1
fi

echo "📍 Project root: $PROJECT_ROOT"
echo ""

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x "$PROJECT_ROOT/local-ci.sh"
chmod +x "$SCRIPT_DIR/generate-report.sh"
chmod +x "$SCRIPT_DIR/pre-commit.template"
echo "✅ Scripts are now executable"
echo ""

# Install pre-commit hook
echo "🪝 Installing pre-commit hook..."
if [ -f "$PROJECT_ROOT/.git/hooks/pre-commit" ]; then
  echo -e "${YELLOW}⚠️  Pre-commit hook already exists${NC}"
  echo -n "   Overwrite? [y/N] "
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "   Skipped pre-commit hook installation"
  else
    cp "$SCRIPT_DIR/pre-commit.template" "$PROJECT_ROOT/.git/hooks/pre-commit"
    chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
    echo "✅ Pre-commit hook installed (overwritten)"
  fi
else
  cp "$SCRIPT_DIR/pre-commit.template" "$PROJECT_ROOT/.git/hooks/pre-commit"
  chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
  echo "✅ Pre-commit hook installed"
fi
echo ""

# Create results directory
echo "📁 Creating results directory..."
mkdir -p "$PROJECT_ROOT/.ci-results"
echo "✅ Results directory created: .ci-results/"
echo ""

# Add .ci-results to .gitignore if not already there
if ! grep -q ".ci-results" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
  echo "📝 Adding .ci-results to .gitignore..."
  echo "" >> "$PROJECT_ROOT/.gitignore"
  echo "# Local CI results" >> "$PROJECT_ROOT/.gitignore"
  echo ".ci-results/" >> "$PROJECT_ROOT/.gitignore"
  echo "✅ Updated .gitignore"
else
  echo "✅ .gitignore already contains .ci-results"
fi
echo ""

# Validate environment
echo "🔍 Validating environment..."
VALIDATION_ERRORS=0

# Check Xcode
if command -v xcodebuild &> /dev/null; then
  XCODE_VERSION=$(xcodebuild -version | head -n 1)
  echo "✅ Xcode: $XCODE_VERSION"
else
  echo "❌ Xcode not found"
  VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Check Java
if command -v java &> /dev/null; then
  JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
  echo "✅ Java: $JAVA_VERSION"
else
  echo "❌ Java not found"
  VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Check Android SDK
if [ -d "$HOME/Library/Android/sdk" ] || [ -n "$ANDROID_HOME" ]; then
  echo "✅ Android SDK: Found"
else
  echo "⚠️  Android SDK not found (optional)"
fi

# Check simulators
echo "📱 Available iOS Simulators:"
xcrun simctl list devices | grep "iPhone" | head -n 3
echo ""

echo ""
if [ $VALIDATION_ERRORS -gt 0 ]; then
  echo -e "${YELLOW}⚠️  Setup completed with warnings${NC}"
  echo "   Please install missing dependencies"
else
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                                                            ║${NC}"
  echo -e "${GREEN}║     ✅ Local CI Setup Complete!                           ║${NC}"
  echo -e "${GREEN}║                                                            ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
fi
echo ""

echo "📚 Next steps:"
echo ""
echo "  1. Run full CI check:"
echo "     ./local-ci.sh --all"
echo ""
echo "  2. Run quick check (build + unit tests only):"
echo "     ./local-ci.sh --all --quick"
echo ""
echo "  3. Run platform-specific checks:"
echo "     ./local-ci.sh --ios"
echo "     ./local-ci.sh --android"
echo ""
echo "  4. Pre-commit hook will run automatically before each commit"
echo "     To bypass: git commit --no-verify"
echo ""
echo "  5. Read full documentation:"
echo "     cat LOCAL-CI.md"
echo ""
