# AGENTS.md

## Repository Purpose
- This repository manages personal dotfiles bootstrap behavior for shell and Git settings.
- The primary execution path is [install.sh](install.sh).

## Key Files
- [install.sh](install.sh): POSIX shell installer that symlinks supported config files into `$HOME`.
- [.gitconfig](.gitconfig): Git user settings and aliases to be linked into `$HOME`.

## Agent Working Rules
- Keep installer logic POSIX `sh` compatible. Do not introduce Bash-only features.
- Prefer additive and non-destructive changes. Preserve existing symlink behavior.
- Only link files when they exist in the repo (current script pattern).
- Use forward-compatible shell commands available in minimal Linux containers.

## Validation Commands
Run these after changes:

```sh
# Lint-like syntax check
sh -n install.sh

# Validate installer in an isolated HOME
tmp_home="$(mktemp -d)"
HOME="$tmp_home" sh ./install.sh
ls -la "$tmp_home"
rm -rf "$tmp_home"

# Validate active user setup
sh ./install.sh
ls -la "$HOME/.gitconfig"
git config --global --get user.name
git config --global --get user.email
git config --global --get alias.lg
```

## Common Pitfalls
- Running with `bash` assumptions in containers that only provide `sh`.
- Assuming `.bashrc`, `.zshrc`, or PowerShell profile paths always exist.
- Breaking idempotency: installer should be safe to run multiple times.

## Change Scope Guidance
- If adding new managed dotfiles, update [install.sh](install.sh) and keep the same conditional-link pattern.
- If changing Git defaults, update [.gitconfig](.gitconfig) and re-run validation commands above.
