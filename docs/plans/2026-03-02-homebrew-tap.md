# Homebrew Tap Formula Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `doo` installable via `brew install buckleypaul/tap/doo` by publishing a tagged release on GitHub and adding a build-from-source formula to the existing `buckleypaul/homebrew-tap` tap.

**Architecture:** Tag the current doo repo state as v0.1.0, push a GitHub release so Homebrew has a canonical source tarball, then write a Swift SPM formula in the existing tap repo that downloads the tarball and runs `swift build -c release`.

**Tech Stack:** Homebrew Ruby formula DSL, Swift Package Manager, GitHub Releases, `gh` CLI.

---

### Task 1: Commit README and CLAUDE.md to the doo repo

**Files:**
- Modify: `README.md` (already written — just needs committing)
- Create: `CLAUDE.md` (already written — just needs committing)

**Step 1: Stage the files**

```bash
cd /Users/paulbuckley/projects/doo
git add README.md CLAUDE.md
```

**Step 2: Commit**

```bash
git commit -m "docs: add README and CLAUDE.md"
```

Expected: commit succeeds, working tree clean.

---

### Task 2: Tag v0.1.0 and push to GitHub

**Step 1: Create the tag**

```bash
cd /Users/paulbuckley/projects/doo
git tag v0.1.0
```

**Step 2: Push commits and tag**

```bash
git push origin main
git push origin v0.1.0
```

Expected: tag appears at `https://github.com/buckleypaul/doo/releases/tag/v0.1.0`.

---

### Task 3: Create the GitHub release

**Step 1: Create release with gh CLI**

```bash
gh release create v0.1.0 \
  --repo buckleypaul/doo \
  --title "v0.1.0" \
  --notes "Initial release."
```

Expected: release URL printed, source tarball available at:
`https://github.com/buckleypaul/doo/archive/refs/tags/v0.1.0.tar.gz`

---

### Task 4: Compute the tarball sha256

**Step 1: Download the tarball and hash it**

```bash
curl -sL https://github.com/buckleypaul/doo/archive/refs/tags/v0.1.0.tar.gz \
  | shasum -a 256
```

Expected: a 64-character hex string. Copy this — it goes in the formula as `sha256`.

---

### Task 5: Write the Homebrew formula

**Files:**
- Create: `/opt/homebrew/Library/Taps/buckleypaul/homebrew-tap/Formula/doo.rb`

**Step 1: Write the formula** — substitute the real sha256 from Task 4.

```ruby
class Doo < Formula
  desc "Minimal local-first todo app for macOS"
  homepage "https://github.com/buckleypaul/doo"
  url "https://github.com/buckleypaul/doo/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  license "MIT"

  depends_on :macos => :sequoia

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/Doo" => "doo"
  end

  test do
    assert_predicate bin/"doo", :executable?
  end
end
```

**Notes:**
- `depends_on :macos => :sequoia` — enforces macOS 15+ requirement matching `Package.swift`.
- `--disable-sandbox` — disables Swift PM's own plugin sandbox; required in Homebrew's build environment.
- Binary is installed as `doo` (lowercase) following CLI naming convention.
- `swift` is provided by Xcode Command Line Tools; no extra `depends_on` needed.

---

### Task 6: Audit the formula locally

**Step 1: Run Homebrew's formula audit**

```bash
brew audit --new-formula /opt/homebrew/Library/Taps/buckleypaul/homebrew-tap/Formula/doo.rb
```

Expected: no errors (warnings about `test do` block asserting executability are acceptable for GUI apps).

---

### Task 7: Install and smoke-test locally

**Step 1: Install from the local formula**

```bash
brew install --build-from-source buckleypaul/tap/doo
```

Expected: Swift build completes, binary installed to Homebrew prefix.

**Step 2: Verify the binary runs**

```bash
which doo
doo &   # launches the GUI app
sleep 2
pkill -f Doo
```

Expected: `doo` found in PATH, app launches without crashing.

**Step 3: Run brew test**

```bash
brew test buckleypaul/tap/doo
```

Expected: PASS.

---

### Task 8: Commit and push the formula to the tap

**Step 1: Stage and commit**

```bash
cd /opt/homebrew/Library/Taps/buckleypaul/homebrew-tap
git add Formula/doo.rb
git commit -m "feat: add doo formula v0.1.0"
```

**Step 2: Push to GitHub**

```bash
git push origin main
```

Expected: formula visible at `https://github.com/buckleypaul/homebrew-tap/blob/main/Formula/doo.rb`.

---

### Task 9: Verify end-to-end install from remote tap

**Step 1: Uninstall the local build**

```bash
brew uninstall doo
```

**Step 2: Update tap and reinstall from remote**

```bash
brew update
brew install buckleypaul/tap/doo
```

Expected: Homebrew downloads the tarball from GitHub, builds with Swift, installs binary.

**Step 3: Confirm**

```bash
brew info buckleypaul/tap/doo
```

Expected: shows version `0.1.0`, install path, homepage.

---

## Verification checklist

- [ ] `git tag v0.1.0` exists on `buckleypaul/doo`
- [ ] GitHub release exists with source tarball
- [ ] `sha256` in formula matches `shasum -a 256` of tarball
- [ ] `brew audit` passes
- [ ] `brew test buckleypaul/tap/doo` passes
- [ ] `brew install buckleypaul/tap/doo` succeeds from remote tap
