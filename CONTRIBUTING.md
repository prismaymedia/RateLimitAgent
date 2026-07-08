# Contributing to RateLimitAgent

First off, thanks for taking the time to contribute! 🎉

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

- **Check existing issues** — search [GitHub Issues](https://github.com/prismaymedia/RateLimitAgent/issues) first
- **Use a clear title** and describe the steps to reproduce
- Include your **macOS version** and **build method** (source build / pre-built)
- Attach **screenshots** if the bug is visual

### Suggesting Enhancements

- Open a [GitHub Issue](https://github.com/prismaymedia/RateLimitAgent/issues/new) with the label `enhancement`
- Explain **what you want** and **why** — use cases help a lot
- If you have a rough design or mockup, include it

### Pull Requests

1. **Fork** the repo and create your branch from `main`
2. **Follow the existing code style** — use `swift-format` if possible
3. **Test your changes** — build with `bash create-app.sh`
4. **Update the README** if your change affects usage
5. **Write a good commit message** following [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat: add support for multiple models`
   - `fix: handle missing Retry-After header`
   - `docs: update README with build instructions`
6. Open the PR and reference any related issues

### Development Setup

```bash
git clone https://github.com/prismaymedia/RateLimitAgent.git
cd RateLimitAgent
bash create-app.sh
open build/RateLimitAgent.app
```

## Project Priorities

- **Simplicity** — this should remain a single-purpose utility. One job, done well.
- **Battery life** — be mindful of polling frequency. 30s is a good default.
- **Accessibility** — VoiceOver-friendly labels on all UI elements.
- **Performance** — no framework dependencies beyond SwiftUI + Foundation.

## Ideas Welcome

If you have an idea but aren't sure how to implement it, open an issue with the `discussion` label. All skill levels welcome!
