#!/bin/bash

# git-flow make-less installer for *nix systems, by Rick Osborne
# Based on the git-flow core Makefile:
# http://github.com/nvie/gitflow/blob/master/Makefile

# Licensed under the same restrictions as git-flow:
# http://github.com/nvie/gitflow/blob/develop/LICENSE
usage() {
	echo "Usage: gitflow-installer.sh [prefix] [repo_name] [repo_home] [command] [branch] [tag]"
	echo "Arguments:"
	echo "   prefix=/usr/local"
	echo "   repo_name=gitflow"
	echo "   repo_home=https://github.com/petervanderdoes/gitflow-avh.git"
	echo "   command=install[install|uninstall|help]"
	echo "   branch=stable[stable|develop|version]"
	echo "   tag=[only if branch=version]"
	exit 1
}

PREFIX=${1:-"/usr/local"}
REPO_NAME=${2:-"gitflow"}
REPO_HOME=${3:-"https://github.com/petervanderdoes/gitflow-avh.git"}
COMMAND=${4:-"install"}
BRANCH=${5:-"stable"}
TAG=${6:-""}

EXEC_PREFIX="$PREFIX"
BINDIR="$EXEC_PREFIX/bin"
DATAROOTDIR="$PREFIX/share"
DOCDIR="$DATAROOTDIR/doc/gitflow"

EXEC_FILES="git-flow"
SCRIPT_FILES="git-flow-init git-flow-feature git-flow-bugfix git-flow-hotfix git-flow-release git-flow-support git-flow-version gitflow-common gitflow-shFlags git-flow-config"
HOOK_FILES="$REPO_NAME/hooks/*"

if [ "$(id -u)" -ne 0 ]; then
	echo -e 'Script must be run a root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
fi

echo "### git-flow no-make installer ###"

case "$4" in
uninstall)
	echo "Uninstalling git-flow from $PREFIX"
	if [ -d "$BINDIR" ]; then
		for script_file in $SCRIPT_FILES $EXEC_FILES; do
			echo "rm -vf $BINDIR/$script_file"
			rm -vf "$BINDIR/$script_file"
		done
		rm -rf "$DOCDIR"
	else
		echo "The '$BINDIR' directory was not found."
	fi
	exit
	;;
help)
	usage
	exit
	;;
install)
	if [ -z $5 ]; then
		usage
		exit
	fi
	echo "Installing git-flow to $BINDIR"
	if [ -d "$REPO_NAME" -a -d "$REPO_NAME/.git" ]; then
		echo "Using existing repo: $REPO_NAME"
	else
		echo "Cloning repo from GitHub to $REPO_NAME"
		git config --global url."https://".insteadOf git://
		git clone "$REPO_HOME" "$REPO_NAME"
	fi
	cd "$REPO_NAME"
	git pull
	cd "$OLDPWD"
	case "$5" in
	stable)
		cd "$REPO_NAME"
		git checkout master
		cd "$OLDPWD"
		;;
	develop)
		cd "$REPO_NAME"
		git checkout develop
		cd "$OLDPWD"
		;;
	version)
		cd "$REPO_NAME"
		git checkout tags/$6
		cd "$OLDPWD"
		;;
	*)
		usage
		exit
		;;
	esac
	install -v -d -m 0755 "$PREFIX/bin"
	install -v -d -m 0755 "$DOCDIR/hooks"
	for exec_file in $EXEC_FILES; do
		install -v -m 0755 "$REPO_NAME/$exec_file" "$BINDIR"
	done
	for script_file in $SCRIPT_FILES; do
		install -v -m 0644 "$REPO_NAME/$script_file" "$BINDIR"
	done
	for hook_file in $HOOK_FILES; do
		install -v -m 0644 "$hook_file" "$DOCDIR/hooks"
	done
	exit
	;;
*)
	usage
	exit
	;;
esac
