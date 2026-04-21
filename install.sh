#!/bin/sh

# -e: exit on error
# -u: exit on unset variables
set -eu

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
	# Verify checksum before executing
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

# Ensure aqua bin dir is in PATH for chezmoi scripts that call aqua
AQUA_BIN="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/aquaproj-aqua}/bin"
case ":${PATH}:" in
	*":${AQUA_BIN}:"*) ;;
	*) export PATH="${AQUA_BIN}:${PATH}" ;;
esac

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

set -- init --apply --source="${script_dir}" --no-tty

echo "Running 'chezmoi $*'" >&2
# exec: replace current process with chezmoi
exec "$chezmoi" "$@"
