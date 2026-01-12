# Archive - Historical Documentation

## Purpose

This directory contains **historical documentation** that has been archived to reduce clutter in the main repository while preserving context for future reference.

## ⚠️ Important Notice

**DO NOT use archived documentation for current development!**

- These files are **outdated** and may contain information that no longer reflects the current codebase
- Always refer to **active documentation** in the root, `docs/`, `ios/`, or `android/` directories
- Archive is for **historical context only**

## 📁 Directory Structure

```
archive/
├── summaries/              # Session summaries and completion reports
├── implementation-guides/  # Completed feature implementation guides
├── test-reports/           # Historical test reports and analyses
├── android/                # Android-specific archived documentation
└── ios/                    # iOS-specific archived documentation
```

## 🔍 When to Reference Archive

**✅ Good Reasons:**
- Understanding why a design decision was made
- Researching how a specific bug was originally fixed
- Reviewing implementation approach for similar future features
- Onboarding new team members who want full historical context

**❌ Bad Reasons:**
- Finding current test status → Use `TEST_STATUS_FINAL.md`
- Learning current architecture → Use `ARCHITECTURE_OVERVIEW.md`
- Understanding current features → Use active spec files
- Finding implementation guides → Use current documentation

## 📋 Archived Categories

### 1. Summaries (`summaries/`)
**What**: Session summaries, feature completion reports, implementation summaries

**When archived**: After feature is complete and stable for 30+ days

**Examples**:
- `SESSION_SUMMARY.md` - Cross-platform test status (January 2025)
- `AUTO_RECORDING_IMPLEMENTATION_SUMMARY.md` - Auto-recording feature summary
- `REFACTORING_SUMMARY.md` - October 2024 architecture refactoring

### 2. Implementation Guides (`implementation-guides/`)
**What**: Step-by-step implementation guides for completed features

**When archived**: After feature is stable and fully documented in specs

**Examples**:
- `CURRENCY_IMPLEMENTATION_GUIDE.md` - Multi-currency implementation
- `PARALLEL-CI-IMPLEMENTATION.md` - Parallel CI execution guide
- `iOS-UI-TEST-IMPLEMENTATION-TRACKING.md` - UI test implementation tracking

### 3. Test Reports (`test-reports/`)
**What**: Historical test failure analyses, fix plans, and summaries

**When archived**: After tests are stable for 30+ days

**Examples**:
- `test-summary-report.md` - Historical test summary
- `test-fix-plan.md` - Test fix planning document
- `UI-TEST-FAILURES-ANALYSIS.md` - UI test failure analysis

### 4. Platform-Specific (`android/`, `ios/`)
**What**: Platform-specific historical documentation

**When archived**: After issues resolved or features complete

**Examples**:
- `android/CURRENCY_FIX_SUMMARY.md` - Currency bug fixes for Android
- `ios/UI_TEST_FAILURES.md` - iOS UI test failures analysis

## 🗂️ Full Archive Inventory

See **`DOCUMENTATION_CLEANUP_SUMMARY.md`** in the root directory for:
- Complete list of archived files
- Reason each file was archived
- Archive date and location
- Active documentation alternatives

## 📝 Archival Policy

### Files Get Archived When:
1. **Session Summaries**: 30 days after session completion
2. **Implementation Guides**: 60 days after feature is stable
3. **Test Reports**: 30 days after all tests passing
4. **Troubleshooting Guides**: 90 days after issues resolved

### Files Get Removed When:
- After 1+ year in archive with no references
- Confirmed no historical value
- Requires formal review and approval

## 🚀 Active Documentation

For current, up-to-date information, see:

### Core Docs (Root)
- `CLAUDE.md` - Main project memory
- `just-spent-master-plan.md` - Project roadmap
- `TESTING-GUIDE.md` - Testing guide
- `LOCAL-CI.md` - CI/CD documentation

### Platform Docs
- `ios/TEST_STATUS_FINAL.md` - Current iOS test status
- `android/TEST_STATUS_FINAL.md` - Current Android test status
- `ios/ARCHITECTURE.md` - iOS architecture
- `android/README.md` - Android project info

### Reference Docs
- `docs/GIT-WORKFLOW-RULES.md` - Git workflow
- `docs/REUSABLE-COMPONENTS.md` - UI components
- `ui-design-spec.md` - UI/UX specifications
- `data-models-spec.md` - Data models

## 🔄 Maintenance

**Quarterly Review**: Every 3 months, review root/docs/platform directories for archival candidates

**Archival Process**:
1. Identify outdated documentation
2. Move to appropriate archive subdirectory
3. Update `DOCUMENTATION_CLEANUP_SUMMARY.md`
4. Commit with descriptive message

---

**Last Cleanup**: January 2025
**Files Archived**: 21
**Archive Status**: Active and maintained

**For questions or to request restoration of archived docs, see `DOCUMENTATION_CLEANUP_SUMMARY.md`**
