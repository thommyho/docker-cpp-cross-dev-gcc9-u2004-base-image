FROM ubuntu:20.04

# Set username, password, uid and guid
ARG USERNAME=vscode
ARG PASSWORD=vscode
ARG CONAN_VERSION=1.49.0
ARG USER_UID=1001
ARG USER_GID=$USER_UID
ENV HOME=/home/${USERNAME}
ENV DOCKER_BUILDKIT=1

ENV CC=aarch64-linux-gnu-gcc-9 \
    CXX=aarch64-linux-gnu-g++-9 \
    CMAKE_C_COMPILER=aarch64-linux-gnu-gcc-9 \
    CMAKE_CXX_COMPILER=aarch64-linux-gnu-g++-9 \
    STRIP=aarch64-linux-gnu-strip \
    RANLIB=aarch64-linux-gnu-ranlib \
    AS=aarch64-linux-gnu-as \
    AR=aarch64-linux-gnu-ar \
    LD=aarch64-linux-gnu-ld \
    FC=aarch64-linux-gnu-gfortran-9


# Config apt package manager  
ARG UPGRADE_PACKAGES="true"
# ARG ADDITIONAL_PACKAGES="gcc-9-aarch64-linux-gnu g++-9-aarch64-linux-gnu tini python3-pip build-essential cmake cppcheck valgrind clang lldb llvm gdb"
ARG ADDITIONAL_PACKAGES="gcc-9-aarch64-linux-gnu g++-9-aarch64-linux-gnu tini python3-pip cmake"

# Config shell
ARG INSTALL_ZSH="true"

USER root

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
#git-flow-debian.sh from https://github.com/petervanderdoes/gitflow-avh
COPY script-library/common-debian.sh \
    script-library/git-lfs-debian.sh \
    script-library/git-flow-debian.sh \
    script-library/docker-in-docker-debian.sh \
    script-library/install-additional-debian.sh \
    /tmp/library-scripts/

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" \
    && if [ "$INSTALL_ZSH" = "true" ]; then usermod --shell /bin/zsh ${USERNAME}; fi \
    && bash /tmp/library-scripts/install-additional-debian.sh "${ADDITIONAL_PACKAGES}" \
    && bash /tmp/library-scripts/git-lfs-debian.sh \
    && bash /tmp/library-scripts/git-flow-debian.sh "/usr/local" "gitflow" "https://github.com/petervanderdoes/gitflow-avh.git" "install" "stable" \
    && /bin/bash /tmp/library-scripts/docker-in-docker-debian.sh \
    && sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-gcc aarch64-linux-gnu-gcc /usr/bin/aarch64-linux-gnu-gcc-9 100 \
    && sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-g++ aarch64-linux-gnu-g++ /usr/bin/aarch64-linux-gnu-g++-9 100 \
    && sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-gcov aarch64-linux-gnu-gcov /usr/bin/aarch64-linux-gnu-gcov-9 100 \
    && sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-gcov-dump aarch64-linux-gnu-gcov-dump /usr/bin/aarch64-linux-gnu-gcov-dump-9 100 \
    && sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-gcov-tool aarch64-linux-gnu-gcov-tool /usr/bin/aarch64-linux-gnu-gcov-tool-9 100 \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts \
    && pip install -q --no-cache-dir conan==${CONAN_VERSION} conan-package-tools --upgrade \
    && conan profile new default --detect \
    && conan profile update settings.arch=armv8 default
# Set up folders for vscode workspaces, extensions/pip cache
RUN mkdir -p /workspaces && chgrp ${USER_GID} /workspaces \
    && mkdir -p ${HOME}/.vscode-server \
    && chown -R ${USERNAME}:${USERNAME} ${HOME}/.vscode-server \
    && mkdir -p ${HOME}/.cache/pip \
    && chown -R ${USERNAME}:${USERNAME} ${HOME}/.cache \
    && mkdir -p /root/.cache/pip

RUN touch /root/.z /home/vscode/.z \
    && mkdir -p /root/.oh-my-zsh/custom/plugins/git-flow-completion \
    && git clone https://github.com/petervanderdoes/git-flow-completion /root/.oh-my-zsh/custom/plugins/git-flow-completion \
    && git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone https://github.com/esc/conda-zsh-completion /root/.oh-my-zsh/custom/plugins/conda-zsh-completion \
    && cp -R /root/.oh-my-zsh/custom/plugins/* ${HOME}/.oh-my-zsh/custom/plugins/ \
    && chown -R ${USERNAME}:${USERNAME} ${HOME} \
    && sed -i -r 's/^(plugins=)\(([a-z \-]+)\)/\1\(\2 git-flow-completion conda-zsh-completion zsh-autosuggestions z\)/g' ${HOME}/.zshrc \
    && sed -i -r 's/^(plugins=)\(([a-z \-]+)\)/\1\(\2 git-flow-completion conda-zsh-completion zsh-autosuggestions z\)/g' /root/.zshrc

USER ${USERNAME}

VOLUME [ "/var/lib/docker" ]
# Setting the ENTRYPOINT to docker-init.sh will configure non-root access to
# the Docker socket if "overrideCommand": false is set in devcontainer.json.
# The script will also execute CMD if you need to alter startup behaviors.
ENTRYPOINT [ "/usr/bin/tini", "--", "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]
