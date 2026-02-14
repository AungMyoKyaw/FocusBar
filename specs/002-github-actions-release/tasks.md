# Tasks: GitHub Actions CI/CD Pipeline for macOS

**Input**: Design documents from `/specs/002-github-actions-release/`
**Prerequisites**: plan.md (template), spec.md (user stories defined)

**Status**: ✅ COMPLETED - All workflows implemented

**Tests**: No explicit test tasks requested in specification. GitHub Actions workflows are validated through execution.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **GitHub Actions**: `.github/workflows/` at repository root
- **Project**: Existing FocusBar.xcodeproj structure

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize GitHub Actions structure and base workflow configuration

**Status**: ✅ COMPLETED

- [X] T001 Create `.github/workflows/` directory structure
- [X] T002 [P] Create build workflow at `.github/workflows/build.yml` (CI on push)
  - [X] T002a Configure push/PR triggers in `.github/workflows/build.yml`
  - [X] T002b Add macOS runner and xcodebuild in Debug mode in `.github/workflows/build.yml`
- [X] T003 Create release workflow at `.github/workflows/release.yml` (releases on tags)

**Checkpoint**: ✅ GitHub Actions directory structure ready for workflow implementation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core workflow infrastructure that MUST be complete before user story implementation

**Status**: ✅ COMPLETED

- [X] T003 Configure workflow trigger for tag pattern `v*` in `.github/workflows/release.yml`
- [X] T004 Add macOS runner configuration (`macos-latest`) in `.github/workflows/release.yml`
- [X] T005 Add Xcode version selection and build environment setup in `.github/workflows/release.yml`
- [X] T006 Configure checkout action with full history for changelog generation in `.github/workflows/release.yml`

**Checkpoint**: ✅ Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Developer Triggers Release via Git Tag (Priority: P1) 🎯 MVP

**Goal**: Enable automatic CI pipeline trigger and GitHub Release creation when a developer pushes a git tag.

**Status**: ✅ COMPLETED

**Independent Test**: Push a tag matching `v*`, verify workflow runs, check that GitHub Release is created with artifact.

### Implementation for User Story 1

- [X] T007 [US1] Add xcodebuild build step for Release configuration in `.github/workflows/release.yml`
- [X] T008 [US1] Add artifact packaging step to create `.app.zip` in `.github/workflows/release.yml`
- [X] T009 [US1] Add GitHub Release creation step using `softprops/action-gh-release` in `.github/workflows/release.yml`
- [X] T010 [US1] Configure release artifact upload to attach `.app.zip` to GitHub Release in `.github/workflows/release.yml`
- [X] T011 [US1] Add workflow failure handling to prevent release on build failure in `.github/workflows/release.yml`

**Checkpoint**: ✅ User Story 1 fully functional - pushing a tag creates a release with artifact

---

## Phase 4: User Story 2 - Build Uses Ad-Hoc Signing (Priority: P1)

**Goal**: Configure the build to use ad-hoc signing so builds can run without Apple Developer Program membership.

**Status**: ✅ COMPLETED

**Independent Test**: Verify the workflow uses ad-hoc signing identity and produces a runnable application bundle.

### Implementation for User Story 2

- [X] T012 [US2] Add ad-hoc signing configuration (`CODE_SIGN_IDENTITY=-`) to xcodebuild command in `.github/workflows/release.yml`
- [X] T013 [US2] Add codesign step to apply ad-hoc signature to the built `.app` bundle in `.github/workflows/release.yml`
- [X] T014 [US2] Add gatekeeper assessment step to verify signed app in `.github/workflows/release.yml`
- [X] T015 [US2] Add cleanup step for temporary signing artifacts in `.github/workflows/release.yml`

**Checkpoint**: ✅ Builds use ad-hoc signing and produce runnable artifacts

---

## Phase 5: User Story 3 - Release Notes Generated Automatically (Priority: P2)

**Goal**: Automatically generate release notes from commit messages since the last tag.

**Status**: ✅ COMPLETED

**Independent Test**: Verify the created GitHub Release body contains commit message summaries.

### Implementation for User Story 3

- [X] T016 [US3] Add step to generate changelog from git log between tags in `.github/workflows/release.yml`
- [X] T017 [US3] Configure `softprops/action-gh-release` to use generated changelog as release body in `.github/workflows/release.yml`
- [X] T018 [US3] Add fallback for first release (no previous tag) in `.github/workflows/release.yml`

**Checkpoint**: ✅ All user stories complete - releases include auto-generated notes

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and documentation

**Status**: ✅ COMPLETED

- [X] T019 [P] Add workflow badge to README.md for build status visibility
- [X] T020 [P] Document release process in README.md or CONTRIBUTING.md
- [X] T021 Add workflow concurrency configuration to prevent duplicate runs in `.github/workflows/release.yml`
- [X] T022 Add workflow permissions configuration (contents: write) in `.github/workflows/release.yml`

---

## Implementation Verification

### Release Workflow Features (`.github/workflows/release.yml`)

| Feature | Status | Implementation |
|---------|--------|----------------|
| Tag trigger (`v*`) | ✅ | Line 3-6 |
| macOS runner | ✅ | Line 17 |
| Xcode setup | ✅ | Lines 25-29 |
| Release build | ✅ | Lines 31-39 |
| Ad-hoc signing | ✅ | Lines 37-39, 41-53 |
| Gatekeeper check | ✅ | Lines 55-60 |
| Artifact (.app.zip) | ✅ | Lines 62-71 |
| Changelog generation | ✅ | Lines 73-92 |
| GitHub Release | ✅ | Lines 94-102 |
| Draft/Prerelease | ✅ | Lines 99-100 |
| Cleanup | ✅ | Lines 104-108 |
| Concurrency | ✅ | Lines 11-13 |
| Permissions | ✅ | Lines 8-9 |

---

## Notes

**Two Workflows**:
- `build.yml`: Runs on every push and PR → verifies build passes (no release)
- `release.yml`: Runs only on tag push (`v*`) → creates GitHub Release with artifact

**How to Test**:
- Test build workflow: `git push origin main`
- Test release workflow: `git tag v0.0.1-test && git push origin v0.0.1-test`
