PROMPTLY_ROOT=${${(%):-%x}:A:h}

source "$PROMPTLY_ROOT/async/async.zsh"
source "$PROMPTLY_ROOT/lib/git.zsh"

autoload -U colors && colors
autoload -Uz add-zsh-hook

async_init

promptly_default_prompt="%(?:%{$fg_bold[green]%}%1{❯%} :%{$fg_bold[red]%}%1{❯%} ) %{$fg[cyan]%}%c%{$reset_color%}"

function promptly_update() {
  PROMPT="$promptly_default_prompt $promptly_git_data[promptly_git_prefix]$promptly_git_data[promptly_git_branch]$promptly_git_data[promptly_git_dirty]$promptly_git_data[promptly_git_suffix]"

  zle -R && zle reset-prompt
}

function promptly_init_worker() {
  async_start_worker promptly_worker -n
  async_register_callback promptly_worker promptly_callback
}

function promptly_init_jobs() {
  typeset -Ag promptly_git_data

  local promptly_pwd="$PWD"
  async_worker_eval promptly_worker builtin cd -q $promptly_pwd

  if (promptly_git_directory); then
    async_flush_jobs promptly_worker

    promptly_git_data[promptly_git_prefix]=$GIT_PROMPT_PREFIX
    promptly_git_data[promptly_git_suffix]=$GIT_PROMPT_SUFFIX
    
    async_job promptly_worker promptly_git_branch
    async_job promptly_worker promptly_git_dirty
  else
    promptly_git_data[promptly_git_prefix]= 
    promptly_git_data[promptly_git_suffix]= 

    promptly_git_data[promptly_git_branch]= 
    promptly_git_data[promptly_git_dirty]= 
  fi;

  promptly_update
}

function promptly_callback() {
  local job_name=$1
  local job_return_code=$2
  local job_output=$3

  if (( job_return_code == 2 )) \
  || (( job_return_code == 3 )) \
  || (( job_return_code == 130 )); then
    async_stop_worker promptly_worker
    promptly_init_worker
    promptly_init_jobs
  elif (( job_return_code )); then
    promptly_init_jobs
  fi;

  promptly_git_data[$job_name]=$job_output
  promptly_update
}

function promptly_setup() {
  promptly_init_worker
  promptly_init_jobs

  add-zsh-hook precmd promptly_init_jobs

  PROMPT="$promptly_default_prompt"
}

promptly_setup
