# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) and
[aqua](https://aquaproj.github.io/). Works on macOS, traditional Linux,
containers, and Fedora Atomic (immutable) hosts.

## Install

One command, no prerequisites beyond `curl` or `wget`:

```sh
sh -c "$(curl -fsLS https://gitlab.com/BigGold1310/dotfiles/-/raw/main/install.sh?ref_type=heads)"
```

What this does:

1. Bootstraps a temporary `chezmoi` binary into `/tmp` (not left on `PATH`,
   gone after reboot).
2. Installs [aqua](https://aquaproj.github.io/), which chezmoi's scripts use
   to install and manage the actual tool versions (including the real,
   permanent `chezmoi` binary).
3. Runs `chezmoi init --apply` against this repo, cloning it into
   `~/.local/share/chezmoi` and applying all the dotfiles to your home
   directory.

You'll be prompted for any values chezmoi's templates need (name, email,
etc.) the first time it runs.

### Running from a local checkout

If you've already cloned this repo and want to apply it from the local copy
instead of letting chezmoi clone it again:

```sh
git clone https://gitlab.com/BigGold1310/dotfiles.git
cd dotfiles
./install.sh
```

Run it as `./install.sh` (not `sh install.sh`) so the script can detect it's
sitting inside a real checkout and use that as the source directory.

## Update

Once installed, `chezmoi` and `aqua` are both on your `PATH`. To pull the
latest changes and re-apply:

```sh
chezmoi update
```

This does a `git pull` in the source directory and re-applies any changed
files. If you just want to see what would change first, without applying:

```sh
chezmoi diff
```

then apply when you're happy:

```sh
chezmoi apply
```

### Editing dotfiles

To edit a managed file (this opens it in `$EDITOR` and re-applies on save):

```sh
chezmoi edit ~/.bashrc
```

Or edit the source files directly in `~/.local/share/chezmoi`, then run
`chezmoi diff` / `chezmoi apply` as above.
