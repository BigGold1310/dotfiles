#!/bin/sh

# -e: exit on error
# -u: exit on unset variables
set -eu

DOTFILES_REPO="https://gitlab.com/BigGold1310/dotfiles.git"

# Bootstrap chezmoi into /tmp — not in PATH, auto-evicted on reboot.
# After chezmoi apply runs, aqua installs the canonical chezmoi binary.
if ! chezmoi="$(command -v chezmoi)"; then
	chezmoi="/tmp/chezmoi"
	echo "Installing chezmoi to '${chezmoi}' (bootstrap)" >&2
	if command -v curl >/dev/null; then
		chezmoi_install_script="$(curl -fsSL get.chezmoi.io)"
	elif command -v wget >/dev/null; then
		chezmoi_install_script="$(wget -qO- get.chezmoi.io)"
	else
		echo "To install chezmoi, you must have curl or wget installed." >&2
		exit 1
	fi
	sh -c "${chezmoi_install_script}" -- -b "/tmp"
	unset chezmoi_install_script
fi

if ! command -v aqua >/dev/null 2>&1; then
	echo "Installing aqua..." >&2
	aqua_installer_version="v4.0.2"
	aqua_installer_checksum="98b883756cdd0a6807a8c7623404bfc3bc169275ad9064dc23a6e24ad398f43d"
	aqua_installer_tmp="$(mktemp)"
	if command -v curl >/dev/null; then
		curl -sSfL -o "${aqua_installer_tmp}" \
			"https://raw.githubusercontent.com/aquaproj/aqua-installer/${aqua_installer_version}/aqua-installer"
	elif command -v wget >/dev/null; then
		wget -qO "${aqua_installer_tmp}" \
			"https://raw.githubusercontent.com/aquaproj/aqua-installer/${aqua_installer_version}/aqua-installer"
	else
		echo "To install aqua, you must have curl or wget installed." >&2
		rm -f "${aqua_installer_tmp}"
		exit 1
	fi
	if command -v sha256sum >/dev/null 2>&1; then
		echo "${aqua_installer_checksum}  ${aqua_installer_tmp}" | sha256sum -c -
	elif command -v shasum >/dev/null 2>&1; then
		echo "${aqua_installer_checksum}  ${aqua_installer_tmp}" | shasum -a 256 -c -
	else
		echo "Warning: cannot verify aqua-installer checksum (no sha256sum or shasum found)" >&2
	fi
	chmod +x "${aqua_installer_tmp}"
	"${aqua_installer_tmp}"
	rm -f "${aqua_installer_tmp}"
fi

AQUA_BIN="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/aquaproj-aqua}/bin"
case ":${PATH}:" in
	*":${AQUA_BIN}:"*) ;;
	*) export PATH="${AQUA_BIN}:${PATH}" ;;
esac

# Figure out whether we're running from a real local checkout of the
# dotfiles repo (e.g. `./install.sh` after `git clone`), or whether we
# were bootstrapped via `sh -c "$(curl ...)"`. In the latter case $0 is
# just the shell's own name ("sh"), NOT a path to this script — trying
# to derive a source directory from it is meaningless (this is what
# previously pointed chezmoi at /usr/bin and broke on Fedora Atomic's
# read-only /usr).
script_dir=""
if [ -n "${CHEZMOI_SOURCE_DIR:-}" ]; then
	# Explicit escape hatch, e.g. for container builds that COPY the
	# repo in without its .git directory.
	script_dir="${CHEZMOI_SOURCE_DIR}"
else
	case "$0" in
		*/*)
			if candidate_dir="$(cd -P -- "$(dirname -- "$0")" 2>/dev/null && pwd -P)" \
				&& [ -f "${candidate_dir}/$(basename -- "$0")" ] \
				&& git -C "${candidate_dir}" rev-parse --show-toplevel >/dev/null 2>&1; then
				script_dir="$(git -C "${candidate_dir}" rev-parse --show-toplevel)"
			fi
			;;
	esac
fi

if [ -n "${script_dir}" ]; then
	echo "Using local checkout at '${script_dir}' as chezmoi source" >&2
	set -- init --apply --source="${script_dir}" --no-tty
else
	echo "No local checkout found; letting chezmoi clone ${DOTFILES_REPO}" >&2
	set -- init --apply --no-tty "${DOTFILES_REPO}"
fi

echo "Running 'chezmoi $*'" >&2
exec "$chezmoi" "$@"