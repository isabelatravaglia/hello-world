#! /bin/bash

INSTALL_ZSH=${1:-"true"}

# ** Shell customization section **
if [ "${USERNAME}" = "root" ]; then 
    USER_RC_PATH="/root"
else
    USER_RC_PATH="/home/${USERNAME}"
fi

# .bashrc/.zshrc snippet
RC_SNIPPET="$(cat << EOF
export USER=\$(whoami)
if [[ "\${PATH}" != *"\$HOME/.local/bin"* ]]; then export PATH="\${PATH}:\$HOME/.local/bin"; fi
EOF
)"

# code shim, it fallbacks to code-insiders if code is not available
cat << 'EOF' > /usr/local/bin/code
#!/bin/sh
get_in_path_except_current() {
    which -a "$1" | grep -A1 "$0" | grep -v "$0"
}
code="$(get_in_path_except_current code)"
if [ -n "$code" ]; then
    exec "$code" "$@"
elif [ "$(command -v code-insiders)" ]; then
    exec code-insiders "$@"
else
    echo "code or code-insiders is not installed" >&2
    exit 127
fi
EOF
chmod +x /usr/local/bin/code

# Codespaces themes - partly inspired by https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/robbyrussell.zsh-theme
CODESPACES_BASH="$(cat \
<<'EOF'
__bash_prompt() {
    local userpart='`export XIT=$? \
        && [ ! -z "${GITHUB_USER}" ] && echo -n "\[\033[0;32m\]@${GITHUB_USER} " || echo -n "\[\033[0;32m\]\u " \
        && [ "$XIT" -ne "0" ] && echo -n "\[\033[1;31m\]➜" || echo -n "\[\033[0m\]➜"`'
    local gitbranch='`export BRANCH=$(git describe --contains --all HEAD 2>/dev/null); \
        if [ "${BRANCH}" != "" ]; then \
            echo -n "\[\033[0;36m\](\[\033[1;31m\]${BRANCH}" \
            && if git ls-files --error-unmatch -m --directory --no-empty-directory -o --exclude-standard ":/*" > /dev/null 2>&1; then \
                    echo -n " \[\033[1;33m\]✗"; \
            fi \
            && echo -n "\[\033[0;36m\]) "; \
        fi`'
    local lightblue='\[\033[1;34m\]'
    local removecolor='\[\033[0m\]'
    PS1="${userpart} ${lightblue}\w ${gitbranch}${removecolor}\$ "
    unset -f __bash_prompt
}
__bash_prompt
EOF
)"
CODESPACES_ZSH="$(cat \
<<'EOF'
__zsh_prompt() {
    local prompt_username
    if [ ! -z "${GITHUB_USER}" ]; then 
        prompt_username="@${GITHUB_USER}"
    else
        prompt_username="%n"
    fi
    PROMPT="%{$fg[green]%}${prompt_username} %(?:%{$reset_color%}➜ :%{$fg_bold[red]%}➜ )"
    PROMPT+='%{$fg_bold[blue]%}%~%{$reset_color%} $(git_prompt_info)%{$fg[white]%}$ %{$reset_color%}'
    unset -f __zsh_prompt
}
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[cyan]%}(%{$fg_bold[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg_bold[yellow]%}✗%{$fg_bold[cyan]%})"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[cyan]%})"
__zsh_prompt
EOF
)"

# Add notice that Oh My Bash! has been removed from images and how to provide information on how to install manually
OMB_README="$(cat \
<<'EOF'
"Oh My Bash!" has been removed from this image in favor of a simple shell prompt. If you still
wish to use it, remove "~/.oh-my-bash" and install it from: https://github.com/ohmybash/oh-my-bash
You may also want to consider "Bash-it" as an alternative: https://github.com/bash-it/bash-it
See https://github.com/microsoft/vscode-dev-containers/issues/674#issuecomment-783474956
EOF
)"
OMB_STUB="$(cat \
<<'EOF'
#!/usr/bin/env bash
cd "$(dirname $0)"
if [ -t 1 ]; then
    cat README.md
fi
EOF
)"

# Add RC snippet and custom bash prompt
if [ "${RC_SNIPPET_ALREADY_ADDED}" != "true" ]; then
    echo "${RC_SNIPPET}" >> /etc/bash.bashrc
    echo "${CODESPACES_BASH}" >> "${USER_RC_PATH}/.bashrc"
    if [ "${USERNAME}" != "root" ]; then
        echo "${CODESPACES_BASH}" >> "/root/.bashrc"
    fi
    chown ${USERNAME}:${USERNAME} "${USER_RC_PATH}/.bashrc"
    RC_SNIPPET_ALREADY_ADDED="true"
fi

# Add stub for Oh My Bash!
if [ ! -d "${USER_RC_PATH}/.oh-my-bash}" ] && [ "${INSTALL_OH_MYS}" = "true" ]; then
    mkdir -p "${USER_RC_PATH}/.oh-my-bash" "/root/.oh-my-bash"
    echo "${OMB_README}" >> "${USER_RC_PATH}/.oh-my-bash/README.md"
    echo "${OMB_STUB}" >> "${USER_RC_PATH}/.oh-my-bash/oh-my-bash.sh"
    chmod +x "${USER_RC_PATH}/.oh-my-bash/oh-my-bash.sh"
    if [ "${USERNAME}" != "root" ]; then
        echo "${OMB_README}" >> "/root/.oh-my-bash/README.md"
        echo "${OMB_STUB}" >> "/root/.oh-my-bash/oh-my-bash.sh"
        chmod +x "/root/.oh-my-bash/oh-my-bash.sh"
    fi
    chown -R "${USERNAME}:${USERNAME}" "${USER_RC_PATH}/.oh-my-bash"
fi

# Optionally install and configure zsh and Oh My Zsh!
if [ "${INSTALL_ZSH}" = "true" ]; then
    if ! type zsh > /dev/null 2>&1; then
        apt-get-update-if-needed
        apt-get install -y zsh
    fi
    if [ "${ZSH_ALREADY_INSTALLED}" != "true" ]; then
        echo "${RC_SNIPPET}" >> /etc/zsh/zshrc
        ZSH_ALREADY_INSTALLED="true"
    fi

    # Adapted, simplified inline Oh My Zsh! install steps that adds, defaults to a codespaces theme.
    # See https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh for offical script.
    OH_MY_INSTALL_DIR="${USER_RC_PATH}/.oh-my-zsh"
    if [ ! -d "${OH_MY_INSTALL_DIR}" ] && [ "${INSTALL_OH_MYS}" = "true" ]; then
        TEMPLATE_PATH="${OH_MY_INSTALL_DIR}/templates/zshrc.zsh-template"
        USER_RC_FILE="${USER_RC_PATH}/.zshrc"
        umask g-w,o-w
        mkdir -p ${OH_MY_INSTALL_DIR}
        git clone --depth=1 \
            -c core.eol=lf \
            -c core.autocrlf=false \
            -c fsck.zeroPaddedFilemode=ignore \
            -c fetch.fsck.zeroPaddedFilemode=ignore \
            -c receive.fsck.zeroPaddedFilemode=ignore \
            "https://github.com/ohmyzsh/ohmyzsh" "${OH_MY_INSTALL_DIR}" 2>&1
        echo -e "$(cat "${TEMPLATE_PATH}")\nDISABLE_AUTO_UPDATE=true\nDISABLE_UPDATE_PROMPT=true" > ${USER_RC_FILE}
        sed -i -e 's/ZSH_THEME=.*/ZSH_THEME="codespaces"/g' ${USER_RC_FILE}
        mkdir -p ${OH_MY_INSTALL_DIR}/custom/themes
        echo "${CODESPACES_ZSH}" > "${OH_MY_INSTALL_DIR}/custom/themes/codespaces.zsh-theme"
        # Shrink git while still enabling updates
        cd "${OH_MY_INSTALL_DIR}"
        git repack -a -d -f --depth=1 --window=1
        # Copy to non-root user if one is specified
        if [ "${USERNAME}" != "root" ]; then
            cp -rf "${USER_RC_FILE}" "${OH_MY_INSTALL_DIR}" /root
            chown -R ${USERNAME}:${USERNAME} "${USER_RC_PATH}"
        fi
    fi
fi