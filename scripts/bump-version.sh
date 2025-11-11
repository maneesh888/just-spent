#!/bin/bash

# Just Spent - Version Bump Script
# Usage: ./scripts/bump-version.sh <version>
# Example: ./scripts/bump-version.sh 1.2.3

set -e  # Exit on error

# ============================================
# Configuration
# ============================================

VERSION=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

IOS_INFO_PLIST="$ROOT_DIR/ios/JustSpent/JustSpent/Info.plist"
ANDROID_BUILD_GRADLE="$ROOT_DIR/android/app/build.gradle"
PACKAGE_JSON="$ROOT_DIR/package.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# Functions
# ============================================

print_usage() {
  echo -e "${BLUE}Usage:${NC}"
  echo "  ./scripts/bump-version.sh <version>"
  echo ""
  echo -e "${BLUE}Examples:${NC}"
  echo "  ./scripts/bump-version.sh 1.2.3         # Release version"
  echo "  ./scripts/bump-version.sh 1.2.3-beta.1  # Beta version"
  echo "  ./scripts/bump-version.sh 1.2.3-rc.1    # Release candidate"
  echo ""
  echo -e "${BLUE}Version Format:${NC}"
  echo "  MAJOR.MINOR.PATCH[-PRERELEASE]"
  echo "  - MAJOR: Breaking changes (1.0.0 → 2.0.0)"
  echo "  - MINOR: New features (1.0.0 → 1.1.0)"
  echo "  - PATCH: Bug fixes (1.0.0 → 1.0.1)"
  echo "  - PRERELEASE: beta.1, rc.1, etc. (optional)"
}

validate_version() {
  local version=$1

  # Allow semantic versioning with optional prerelease
  if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    echo -e "${RED}Error:${NC} Invalid version format: $version"
    echo "Version must follow SemVer: MAJOR.MINOR.PATCH[-PRERELEASE]"
    echo "Examples: 1.2.3, 1.2.3-beta.1, 1.2.3-rc.1"
    return 1
  fi

  return 0
}

update_ios_version() {
  local version=$1

  echo -e "${BLUE}Updating iOS version...${NC}"

  if [ ! -f "$IOS_INFO_PLIST" ]; then
    echo -e "${YELLOW}Warning:${NC} iOS Info.plist not found at $IOS_INFO_PLIST"
    return 1
  fi

  # Update CFBundleShortVersionString (version name)
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$IOS_INFO_PLIST"

  # Auto-increment CFBundleVersion (build number) - use timestamp
  local build_number=$(date +%Y%m%d%H%M)
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$IOS_INFO_PLIST"

  echo -e "${GREEN}✅ iOS version updated:${NC} $version ($build_number)"
  return 0
}

update_android_version() {
  local version=$1

  echo -e "${BLUE}Updating Android version...${NC}"

  if [ ! -f "$ANDROID_BUILD_GRADLE" ]; then
    echo -e "${YELLOW}Warning:${NC} Android build.gradle not found at $ANDROID_BUILD_GRADLE"
    return 1
  fi

  # Update versionName
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/versionName \".*\"/versionName \"$version\"/" "$ANDROID_BUILD_GRADLE"
  else
    # Linux
    sed -i "s/versionName \".*\"/versionName \"$version\"/" "$ANDROID_BUILD_GRADLE"
  fi

  # Auto-increment versionCode (use timestamp-based code)
  local version_code=$(date +%y%m%d%H%M)

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/versionCode [0-9]*/versionCode $version_code/" "$ANDROID_BUILD_GRADLE"
  else
    sed -i "s/versionCode [0-9]*/versionCode $version_code/" "$ANDROID_BUILD_GRADLE"
  fi

  echo -e "${GREEN}✅ Android version updated:${NC} $version ($version_code)"
  return 0
}

update_package_json() {
  local version=$1

  if [ ! -f "$PACKAGE_JSON" ]; then
    echo -e "${YELLOW}Info:${NC} package.json not found, skipping"
    return 0
  fi

  echo -e "${BLUE}Updating package.json version...${NC}"

  # Use npm to update version (handles package.json correctly)
  (cd "$ROOT_DIR" && npm version "$version" --no-git-tag-version --allow-same-version 2>/dev/null || true)

  echo -e "${GREEN}✅ package.json version updated:${NC} $version"
  return 0
}

generate_changelog() {
  local version=$1

  echo -e "${BLUE}Generating changelog...${NC}"

  # Get commits since last tag
  local last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

  if [ -z "$last_tag" ]; then
    echo -e "${YELLOW}Info:${NC} No previous tag found, skipping changelog"
    return 0
  fi

  local changelog=$(git log --pretty=format:"- %s" "$last_tag..HEAD")

  if [ -z "$changelog" ]; then
    echo -e "${YELLOW}Info:${NC} No commits since $last_tag"
    return 0
  fi

  echo ""
  echo -e "${GREEN}Changelog since $last_tag:${NC}"
  echo "$changelog"
  echo ""

  return 0
}

show_summary() {
  local version=$1

  echo ""
  echo -e "${GREEN}════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}✅ Version bump completed successfully!${NC}"
  echo -e "${GREEN}════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${BLUE}Version:${NC} $version"
  echo -e "${BLUE}Changes:${NC}"
  echo "  - iOS Info.plist updated"
  echo "  - Android build.gradle updated"
  if [ -f "$PACKAGE_JSON" ]; then
    echo "  - package.json updated"
  fi
  echo ""
  echo -e "${YELLOW}📝 Next steps:${NC}"
  echo ""
  echo "  1. Review changes:"
  echo -e "     ${BLUE}git diff${NC}"
  echo ""
  echo "  2. Commit version bump:"
  echo -e "     ${BLUE}git commit -am \"chore: Bump version to $version\"${NC}"
  echo ""
  echo "  3. Create git tag:"
  echo -e "     ${BLUE}git tag -a v$version -m \"Release v$version\"${NC}"
  echo ""
  echo "  4. Push to remote:"
  echo -e "     ${BLUE}git push && git push --tags${NC}"
  echo ""
  echo "  5. GitHub Actions will automatically deploy to:"
  echo "     - iOS: TestFlight"
  echo "     - Android: Play Store (Internal Testing)"
  echo ""
  echo -e "${GREEN}════════════════════════════════════════════════${NC}"
}

# ============================================
# Main Script
# ============================================

main() {
  # Check if version argument provided
  if [ -z "$VERSION" ]; then
    echo -e "${RED}Error:${NC} Version number required"
    echo ""
    print_usage
    exit 1
  fi

  # Show help
  if [ "$VERSION" == "-h" ] || [ "$VERSION" == "--help" ]; then
    print_usage
    exit 0
  fi

  # Validate version format
  if ! validate_version "$VERSION"; then
    exit 1
  fi

  echo ""
  echo -e "${BLUE}════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}  Just Spent - Version Bump${NC}"
  echo -e "${BLUE}════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${BLUE}Target version:${NC} $VERSION"
  echo ""

  # Check if git working directory is clean
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}Warning:${NC} You have uncommitted changes"
    echo "It's recommended to commit or stash changes before bumping version"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborted."
      exit 1
    fi
    echo ""
  fi

  # Update versions
  update_ios_version "$VERSION"
  update_android_version "$VERSION"
  update_package_json "$VERSION"

  # Generate changelog
  generate_changelog "$VERSION"

  # Show summary
  show_summary "$VERSION"
}

# Run main function
main
