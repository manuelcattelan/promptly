PROMPTLY_ROOT=${${(%):-%x}:A:h}

source "$PROMPTLY_ROOT/async/async.zsh"
source "$PROMPTLY_ROOT/lib/git.zsh"

autoload -U colors && colors
autoload -Uz add-zsh-hook

# Initialize async library
async_init

# Default prompt format
promptly_default_prompt="%(?:%{$fg_bold[green]%}%1{❯%} :%{$fg_bold[red]%}%1{❯%} ) %{$fg[cyan]%}%c%{$reset_color%}"

#
# Update prompt format with most recent data and reset it to show changes.
#
function promptly_update() {
    local git_prefix=$promptly_git_data[promptly_git_prefix]
    local git_suffix=$promptly_git_data[promptly_git_suffix]

    local git_branch=$promptly_git_data[promptly_git_branch]
    local git_status=$promptly_git_data[promptly_git_status]

    PROMPT="$promptly_default_prompt"
    PROMPT+=" $git_prefix$git_branch$git_status$git_suffix"

    zle -R && zle reset-prompt
}

#
# Initialize async worker and register callback function.
#
function promptly_init_worker() {
    async_start_worker promptly_worker -n
    async_register_callback promptly_worker promptly_callback
}

#
# Initialize jobs responsible for retrieving git information.
#
function promptly_init_jobs() {
    typeset -Ag promptly_git_data

    local promptly_pwd="$PWD"
    async_worker_eval promptly_worker builtin cd -q $promptly_pwd

    # If user is inside a git repository:
    #   - flush current jobs
    #   - setup prompt's prefix and suffix for git information
    #   - start jobs for retrieving git information
    if (promptly_git_directory); then
        async_flush_jobs promptly_worker

        promptly_git_data[promptly_git_prefix]=$GIT_PROMPT_PREFIX
        promptly_git_data[promptly_git_suffix]=$GIT_PROMPT_SUFFIX

        async_job promptly_worker promptly_git_branch
        async_job promptly_worker promptly_git_status
    # Else, reset prompt's git data to remove it from prompt.
    else
        promptly_git_data[promptly_git_prefix]= 
        promptly_git_data[promptly_git_suffix]= 

        promptly_git_data[promptly_git_branch]= 
        promptly_git_data[promptly_git_status]= 
    fi;

    promptly_update
}

#
# Callback function to be ran whenever a job finishes it's execution.
#
function promptly_callback() {
    local job_name=$1
    local job_return_code=$2
    local job_output=$3

    # If job did not run successfully, stop current worker and configure
    # async library from scratch.
    if (( job_return_code == 2 )) || (( job_return_code == 3 )) || (( job_return_code == 130 )); then
        async_stop_worker promptly_worker

        promptly_init_worker
        promptly_init_jobs
    elif (( job_return_code )); then
        promptly_init_jobs
    fi;

    # Store job's output and update prompt with new data.
    promptly_git_data[$job_name]=$job_output
    promptly_update
}

#
# Setup prompt by configuring async library and prompt format.
#
function promptly_setup() {
    promptly_init_worker
    promptly_init_jobs

    # Add promptly_init_jobs to functions to be executed before printing prompt.
    add-zsh-hook precmd promptly_init_jobs

    # Initialize prompt with default configuration while async jobs are executed.
    PROMPT="$promptly_default_prompt"
}

promptly_setup
