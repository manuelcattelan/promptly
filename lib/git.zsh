autoload -U colors && colors

# Prompt's prefix and suffix format whenever git information is available.
GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
GIT_PROMPT_SUFFIX="%{$reset_color%} "

# Git status' icons.
GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}%1{✗%}"
GIT_PROMPT_CLEAN="%{$fg[blue]%})"

#
# Promptly's git commands are read-only and should not interfere with other
# processes. As such, we wrap the git command in a local function instead of
# exporting the variable directly in order to avoid interfering with
# manually-run git commands by the user.
#
function __promptly_git() {
    GIT_OPTIONAL_LOCKS=0 command git "$@"
}

#
# Check whether the user is currently inside a git repository.
#
function promptly_git_directory() {
    if ! __promptly_git rev-parse --is-inside-work-tree &> /dev/null \
       || [[ "$(__promptly_git config 2>/dev/null)" == 1 ]]; then
        return 1
    fi;
    return 0
}

#
# Return the current repository's branch name, if available.
#
function promptly_git_branch() {
    local ref
    ref=$(__promptly_git symbolic-ref --short HEAD 2> /dev/null) \
        || ref=$(__promptly_git describe --tags --exact-match HEAD 2> /dev/null) \
        || ref=$(__promptly_git rev-parse --short HEAD 2> /dev/null) \
        || return 0
    echo "${ref:gs/%/%%}"
}

#
# Return the icon corresponding to the current repository's status (dirty/clean).
#
function promptly_git_status() {
    local git_status
    if [[ "$(__promptly_git config 2> /dev/null)" != "1" ]]; then
        git_status=$(__promptly_git status --porcelain 2> /dev/null | tail -n 1)
    fi;
    if [[ -n $git_status ]]; then
        echo "$GIT_PROMPT_DIRTY"
    else
        echo "$GIT_PROMPT_CLEAN"
    fi;
}
