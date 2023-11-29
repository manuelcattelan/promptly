# Load color variables
autoload -U colors && colors

# Initialize async library
source $(dirname "$0")/async.zsh
async_init

# Define prompt variables
GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
GIT_PROMPT_SUFFIX="%{$reset_color%} "
GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}%1{✗%}"
GIT_PROMPT_CLEAN="%{$fg[blue]%})"

function __git_prompt_git() {
  GIT_OPTIONAL_LOCKS=0 command git "$@"
}

function git_prompt_job(){
  # If current working directory is not a git work tree, return.
  # Else, retrieve git information to display inside prompt.
  if ! __git_prompt_git rev-parse --is-inside-work-tree &> /dev/null \
     || [[ "$(__git_prompt_git config 2>/dev/null)" == 1 ]]; then
    return 0
  fi 

  local ref
  ref=$(__git_prompt_git symbolic-ref --short HEAD 2> /dev/null) \
  || ref=$(__git_prompt_git describe --tags --exact-match HEAD 2> /dev/null) \
  || ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null) \
  || return 0

  local git_status
  local git_status_icon
  if [[ "$(__git_prompt_git config 2>/dev/null)" != "1" ]]; then
    git_status=$(__git_prompt_git status --porcelain 2> /dev/null | tail -n 1)
  fi
  if [[ -n $git_status ]]; then
    git_status_icon="$GIT_PROMPT_DIRTY"
  else
    git_status_icon="$GIT_PROMPT_CLEAN"
  fi

  echo "${GIT_PROMPT_PREFIX}${ref:gs/%/%%}${git_status_icon}${GIT_PROMPT_SUFFIX}"
}

# Initialize a new worker (with notify option)
async_start_worker git_prompt_worker -n

# Create a callback function to process results
function git_prompt_callback() {
  PROMPT="%(?:%{$fg_bold[green]%}%1{❯%} :%{$fg_bold[red]%}%1{❯%} )%{$fg[cyan]%}%c%{$reset_color%}"
  PROMPT+=" $3"

  # Reset prompt with updated info
  zle reset-prompt
}

# Give the worker some tasks to perform
async_job git_prompt_worker git_prompt_job

# Register callback function for the workers completed jobs
async_register_callback git_prompt_worker git_prompt_callback
