autoload -U colors && colors

GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
GIT_PROMPT_SUFFIX="%{$reset_color%} "

GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}%1{✗%}"
GIT_PROMPT_CLEAN="%{$fg[blue]%})"

function __promptly_git() {
  GIT_OPTIONAL_LOCKS=0 command git "$@"
}

function promptly_git_directory() {
  if ! __promptly_git rev-parse --is-inside-work-tree &> /dev/null \
     || [[ "$(__promptly_git config 2>/dev/null)" == 1 ]]; then
    return 1
  fi

  return 0
}

function promptly_git_branch() {
  local ref
  ref=$(__promptly_git symbolic-ref --short HEAD 2> /dev/null) \
  || ref=$(__promptly_git describe --tags --exact-match HEAD 2> /dev/null) \
  || ref=$(__promptly_git rev-parse --short HEAD 2> /dev/null) \
  || return 0

  echo "${ref:gs/%/%%}"
}

function promptly_git_dirty() {
  local git_status
  if [[ "$(__promptly_git config 2> /dev/null)" != "1" ]]; then
    git_status=$(__promptly_git status --porcelain 2> /dev/null | tail -n 1)
  fi
  if [[ -n $git_status ]]; then
    echo "$GIT_PROMPT_DIRTY"
  else
    echo "$GIT_PROMPT_CLEAN"
  fi
}
