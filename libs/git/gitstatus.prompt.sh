# Simple Bash prompt with Git status.

# Source gitstatus.plugin.sh from $GITSTATUS_DIR or from the same directory
# in which the current script resides if the variable isn't set.
if [[ -n "${GITSTATUS_DIR:-}" ]]; then
  source "$GITSTATUS_DIR" || return
elif [[ "${BASH_SOURCE[0]}" == */* ]]; then
  source "${BASH_SOURCE[0]%/*}/gitstatus/gitstatus.plugin.sh" || return
else
  source gitstatus.plugin.sh || return
fi

# Sets GITSTATUS_PROMPT to reflect the state of the current git repository.
# The value is empty if not in a git repository. Forwards all arguments to
# gitstatus_query.
#
# Example value of GITSTATUS_PROMPT: master ⇣42⇡42 ⇠42⇢42 *42 merge ~42 +42 !42 ?42
#
#   master  current branch
#      ⇣42  local branch is 42 commits behind the remote
#      ⇡42  local branch is 42 commits ahead of the remote
#      ⇠42  local branch is 42 commits behind the push remote
#      ⇢42  local branch is 42 commits ahead of the push remote
#      *42  42 stashes
#    merge  merge in progress
#      ~42  42 merge conflicts
#      +42  42 staged changes
#      !42  42 unstaged changes
#      ?42  42 untracked files
function gitstatus_prompt_update() {
  last_exit_code=$?
  if [[ $last_exit_code == 0 ]]; then
    __rayrc_SC="\[\033[32m\]:)"
  else
    __rayrc_SC="\[\033[31m\]:("
  fi

  # PS1="\[\033[33m\]${USER}\[\033[35m\]@\h \[\033[34m\]\w\[\033[00m\] ${__rayrc_inside_docker}\n${__rayrc_SC}\[\033[00m\] "
  PS1=""
  PS1+="${VIRTUAL_ENV_PROMPT:+(${VIRTUAL_ENV_PROMPT}) }"
  PS1+="\[\033[33m\]${USER}\[\033[00m\]"
  PS1+="\[\033[1;30m\]@\[\033[00m\]"
  PS1+="\[\033[35m\]\h \[\033[34m\]\w\[\033[00m\]"
  PS1+="${__rayrc_inside_docker}\n"
  PS1+="${__rayrc_SC}\[\033[00m\] "

  GITSTATUS_PROMPT=""

  history -a

  gitstatus_query "$@" || return 1                  # error
  [[ "$VCS_STATUS_RESULT" == ok-sync ]] || return 0 # not a git repo

  local reset=$'\e[0m'             # no color
  local clean=$'\e[38;5;076m'      # green foreground
  local untracked=$'\e[38;5;014m'  # teal foreground
  local modified=$'\e[38;5;011m'   # yellow foreground
  local conflicted=$'\e[38;5;196m' # red foreground

  local p

  local where # branch name, tag or commit
  if [[ -n "$VCS_STATUS_LOCAL_BRANCH" ]]; then
    where="$VCS_STATUS_LOCAL_BRANCH"
  elif [[ -n "$VCS_STATUS_TAG" ]]; then
    p+="${reset}#"
    where="$VCS_STATUS_TAG"
  else
    p+="${reset}@"
    where="${VCS_STATUS_COMMIT:0:8}"
  fi

  ((${#where} > 32)) && where="${where:0:12}…${where: -12}" # truncate long branch names and tags
  p+="${clean}${where}"

  # ⇣42 if behind the remote.
  ((VCS_STATUS_COMMITS_BEHIND)) && p+=" ${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"
  # ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
  ((VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND)) && p+=" "
  ((VCS_STATUS_COMMITS_AHEAD)) && p+="${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"
  # ⇠42 if behind the push remote.
  ((VCS_STATUS_PUSH_COMMITS_BEHIND)) && p+=" ${clean}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
  ((VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND)) && p+=" "
  # ⇢42 if ahead of the push remote; no leading space if also behind: ⇠42⇢42.
  ((VCS_STATUS_PUSH_COMMITS_AHEAD)) && p+="${clean}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"
  # *42 if have stashes.
  ((VCS_STATUS_STASHES)) && p+=" ${clean}*${VCS_STATUS_STASHES}"
  # 'merge' if the repo is in an unusual state.
  [[ -n "$VCS_STATUS_ACTION" ]] && p+=" ${conflicted}${VCS_STATUS_ACTION}"
  # ~42 if have merge conflicts.
  ((VCS_STATUS_NUM_CONFLICTED)) && p+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
  # +42 if have staged changes.
  ((VCS_STATUS_NUM_STAGED)) && p+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
  # !42 if have unstaged changes.
  ((VCS_STATUS_NUM_UNSTAGED)) && p+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
  # ?42 if have untracked files. It's really a question mark, your font isn't broken.
  ((VCS_STATUS_NUM_UNTRACKED)) && p+=" ${untracked}?${VCS_STATUS_NUM_UNTRACKED}"

  GITSTATUS_PROMPT="${p}${reset}"

  # history -a
  # history -c
  # history -r

  # PS1="\[\033[33m\]${USER}\[\033[35m\]@\h \[\033[34m\]\w\[\033[00m\]${GITSTATUS_PROMPT:+ $GITSTATUS_PROMPT} ${__rayrc_inside_docker}\n${__rayrc_SC}\[\033[00m\] "
  PS1=""
  PS1+="${VIRTUAL_ENV_PROMPT:+(${VIRTUAL_ENV_PROMPT}) }"
  PS1+="\[\033[33m\]${USER}\[\033[00m\]"
  PS1+="\[\033[1;30m\]@\[\033[00m\]"
  PS1+="\[\033[35m\]\h \[\033[34m\]\w\[\033[00m\]"
  PS1+="${GITSTATUS_PROMPT:+ $GITSTATUS_PROMPT}"
  PS1+="${__rayrc_inside_docker}\n"
  PS1+="${__rayrc_SC}\[\033[00m\] "

}

# Start gitstatusd in the background.
gitstatus_stop && gitstatus_start -s -1 -u -1 -c -1 -d -1

# On every prompt, fetch git status and set GITSTATUS_PROMPT.
PROMPT_COMMAND=gitstatus_prompt_update

# Enable promptvars so that ${GITSTATUS_PROMPT} in PS1 is expanded.
shopt -s promptvars
