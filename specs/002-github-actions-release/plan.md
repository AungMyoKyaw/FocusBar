# Implementation Plan: GitHub Actions CI/CD Pipeline for macOS

**Branch**: `002-github-actions-release` | **Date**: 2026-02-14 | **Spec**: `/specs/002-github-actions-release/spec.md`
**Input**: Feature specification from `/specs/002-github-actions-release/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement GitHub Actions CI/CD pipeline for FocusBar macOS app that builds with ad-hoc signing and creates GitHub Releases automatically when git tags matching `v*` are pushed. The pipeline runs on macOS GitHub runners, uses xcodebuild for compilation, and integrates with softprops/action-gh-release for automated release creation with auto-generated changelog.

## Technical Context

**Language/Version**: Swift 5.9+ (existing FocusBar codebase)  
**Primary Dependencies**: GitHub Actions, xcodebuild, softprops/action-gh-release, create-dmg (for .dmg creation)  
**Storage**: N/A (CI/CD infrastructure - no persistent data)  
**Testing**: Workflow validation through execution (no traditional unit tests)  
**Target Platform**: macOS 13.0+ (FocusBar minimum), GitHub Actions macOS-latest runner  
**Project Type**: Native macOS menu bar application (FocusBar.xcodeproj)  
**Performance Goals**: Build + release completion within 15 minutes (SC-002)  
**Constraints**: Ad-hoc signing required (no Apple Developer Program membership needed)  
**Scale/Scope**: 2 workflow files (.github/workflows/build.yml, .github/workflows/release.yml), ~200 lines total YAML

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

This is a CI/CD infrastructure feature. The project constitution (if any) applies to the FocusBar application code, not to CI/CD workflow definitions. No gates apply.

- **Gate 1**: N/A - Not a library or application feature
- **Gate 2**: N/A - No CLI interface for this feature
- **Gate 3**: N/A - No code implementation (YAML workflows only)

**Result**: PASS (no constitutional gates apply to CI/CD infrastructure)

## Project Structure

### Documentation (this feature)

```
specs/002-github-actions-release/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (this command)
├── spec.md             # Feature specification
├── tasks.md            # Phase 2 output (/speckit.tasks command)
└── checklists/          # Quality verification checklists
```

### Source Code (repository root)

```
FocusBar/
├── .github/
│   └── workflows/
│       ├── build.yml   # CI on push/PR - validates build
│       └── release.yml # CD on tag push - creates GitHub Release
├── FocusBar.xcodeproj/ # Existing project
├── FocusBar/           # Source code
└── [other existing files]
```

**Structure Decision**: GitHub Actions workflows are infrastructure-as-code stored in `.github/workflows/`. No changes to application source structure required.

## Complexity Tracking

> **Not applicable**: This is a CI/CD infrastructure feature with no architectural complexity. No complexity violations to justify.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |

---

## Phase 0: Research

This feature requires no research - GitHub Actions for macOS builds is a well-established pattern. Key decisions documented below.

### Decision 1: Build Tool

- **Decision**: Use `xcodebuild` command-line tool
- **Rationale**: Native Xcode build tool, no additional dependencies required
- **Alternatives considered**: Swift Package Manager (not suitable for .app bundle builds)

### Decision 2: Release Action

- **Decision**: Use `softprops/action-gh-release`
- **Rationale**: Most popular GitHub Action for releases, supports artifact upload, handles changelog
- **Alternatives considered**: `actions/create-release` (less features), manual API calls (more complex)

### Decision 3: Artifact Format

- **Decision**: Use `.app.zip` (zip of .app bundle)
- **Rationale**: Simpler than .dmg, preserves app permissions, no additional tools required
- **Alternatives considered**: .dmg (requires create-dmg, more complex), .ipa (iOS-only)

### Decision 4: Signing Strategy

- **Decision**: Ad-hoc signing with `CODE_SIGN_IDENTITY=-`
- **Rationale**: Works without Apple Developer Program, allows local testing
- **Alternatives considered**: No signing (blocked by Gatekeeper), full signing (requires certificate)

---

## Phase 1: Design

### Data Model

N/A - This is an infrastructure feature with no persistent data models.

### Key Entities

| Entity | Description |
|--------|-------------|
| Git Tag | Version identifier (format: v1.0.0) |
| Workflow | GitHub Actions workflow definition (YAML) |
| Build Artifact | Compiled .app bundle |
| GitHub Release | Published release with artifact |

### Workflow Configuration

| Trigger | Event | Pattern |
|---------|-------|---------|
| Build | push, pull_request | - |
| Release | push (tag) | refs/tags/v* |

### Concurrency

| Workflow | Group Key | Behavior |
|----------|-----------|----------|
| build | ${{ github.ref }} | Cancel in-progress on new push |
| release | ${{ github.ref }} | Allow (tags are immutable) |

---

## Phase 2: Tasks

Generate tasks via `/speckit.tasks` command.

---

## Generated Artifacts

- `plan.md` (this file)
- `research.md` (this section)
