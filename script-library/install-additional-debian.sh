#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/master/script-library/docs/common.md
#
# Syntax: ./install-additional-debian.sh [packages]

PACKAGES=${1:-""}

set -e

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Function to call apt-get if needed
apt-get-update-if-needed()
{
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update
    else
        echo "Skipping apt-get update."
    fi
}

if [ "${PACKAGES}" != "" ]; then
    apt-get-update-if-needed

    echo "Debian packages are installed: ${PACKAGES}"
    apt-get -y install --no-install-recommends ${PACKAGES} 2> >( grep -v 'debconf: delaying package configuration, since apt-utils is not installed' >&2 )
    echo "Done!"
fi
