These dotfiles are managed with [chezmoi](https://www.chezmoi.io/).

## Layout

The source lives in a bare repo with worktrees, not in chezmoi's default
`~/.local/share/chezmoi`:

- `~/code/dotfiles` is the bare repo.
- `~/code/dotfiles/main` tracks `origin/main`, and chezmoi applies from it.
  Never edit or commit in it. Only pull.
- Each change gets its own worktree and branch, such as
  `~/code/dotfiles/my-change`. Fast-forward `main` once the branch is pushed.

`~/.config/chezmoi/chezmoi.toml` points chezmoi at the `main` worktree:

```toml
sourceDir = "~/code/dotfiles/main"
```

To preview a branch before it merges, run
`chezmoi diff --source ~/code/dotfiles/<worktree>`.

## Set up a new machine

1. Install chezmoi to `~/.local/bin`:
   `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin`
2. Clone the bare repo and add the `main` worktree:

   ```bash
   git clone --bare https://github.com/ca-scribner/dotfiles.git ~/code/dotfiles
   cd ~/code/dotfiles
   git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
   git fetch origin
   git branch -D main
   git worktree add main -b main origin/main
   ```

3. Point chezmoi at it, then apply:

   ```bash
   mkdir -p ~/.config/chezmoi
   printf 'sourceDir = "~/code/dotfiles/main"\n' > ~/.config/chezmoi/chezmoi.toml
   chezmoi apply
   ```

The first apply runs `run_once_after_install.sh`, which installs `just` and
runs `just install-all`. Switch `origin` to SSH once your keys are set up:
`git -C ~/code/dotfiles remote set-url origin git@github.com:ca-scribner/dotfiles.git`.

Do not use `git-wt-init.sh` for this repo. It adds a fork remote that defaults
to `ca-scribner/dotfiles`, which is `origin` itself.

See [installing chezmoi](https://www.chezmoi.io/install/#one-line-package-install)
for other ways to install it.
