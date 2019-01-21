#! /bin/sh

set -eu +x

# remove the generated main.tf file so it isn't commited
# with the project
trap 'rm -f main.tf' EXIT

# Always prefer our registered version of terraform rather than
# using the systems terraform installation
export PATH="$(pwd)/.tfenv/bin:${PATH}"

## initialise loads all the required tooling that isn't part of
## a systems package manager and will fail if the required application
## that would be installed by a package manager are missing
__initialise() {
	for systemutil in "go" "git"; do
		if ! command -v "${systemutil}" >/dev/null 2>/dev/null; then
			echo >&2 "[ERROR] required system util ${systemutil} is not installed"
			exit 1
		fi
	done
	if ! command -v "tfenv" >/dev/null 2>/dev/null; then
		git clone https://github.com/kamatama41/tfenv.git .tfenv
	fi
	if ! command -v "vortex" >/dev/null 2>/dev/null; then
		go get -v "github.com/AlexsJones/vortex"
	fi
	tfenv install
}

## prepare template loads to the correct template
## and creates the terraform file ready to plan.
__prepare_template() {
	if [ $# -lt 2 ]; then
		echo >&2 "[ERROR] function requires <platform> <project-folder>"
		exit 1
	fi
	provider=""
	case $1 in
	"azure") provider="azure" ;;
	"aws" | "amazon") provider="aws" ;;
	"gcp" | "google") provider="gcp" ;;
	\?)
		echo >&2 "[ERROR] Unknown provider ${1}"
		exit 1
		;;
	esac
	vortex --verbose --varpath "${2}" \
		--filter ".*tf" \
		--template "templates/${provider}" \
		--output "." \
		--validator "text" \
		--validate
	vortex --verbose --varpath "${2}" \
		--filter ".*tf" \
		--template "templates/${provider}" \
		--output "."
	terraform init
	terraform validate
	terraform plan --state="${provider}/${2}" --out="${provider}/${2}"
}

__initialise
__prepare_template "$@"
