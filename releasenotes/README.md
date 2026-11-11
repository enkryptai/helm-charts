# Release note fragments

Each pull request adds one file under `releasenotes/unreleased/` instead of editing `RELEASENOTES.md`. Two pull requests never edit the same file, so release notes stop causing merge conflicts.

## In a pull request

Add `releasenotes/unreleased/<your-branch-name>.md`, with every `/` in the branch name written as `-`. Write one bullet per change, prefixed with the chart it affects, and link the pull request:

```markdown
- **platform-stack:** the Argo executor moves from v3.6.14 to v4.0.15 to match the controller ([#175](https://github.com/enkryptai/helm-charts/pull/175)).
```

A change that needs an action on upgrade says so in the bullet.

## In a release pull request

Bump the chart versions, then run:

```bash
utils/release-notes.sh "2026-11-12: On-prem fixes (enkryptai-stack 1.2.2, platform-stack 1.3.0)"
```

The script adds a section with that heading above the newest release in `RELEASENOTES.md`, puts every fragment's bullets in it, and deletes the fragments. Review the section and edit it like any other text before you commit.
