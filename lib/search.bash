#!/usr/bin/env bash
#
# Search by Konstantin Gredeskoul «github.com/kigster»
#
# This function returns list of aliases, plugins and completions in bash-it,
# whose name or description matches one of the search terms provided as arguments.
#
# Usage:
#    ❯ bash-it search [-|@]term1 [-|@]term2 ... \
#       [ --enable   | -e ] \
#       [ --disable  | -d ] \
#       [ --no-color | -c ] \
#       [ --refresh  | -r ] \
#       [ --help     | -h ]
#
#    Single dash, as in "-chruby", indicates a negative search term.
#    Double dash indicates a command that is to be applied to the search result.
#    At the moment only --help, --enable and --disable are supported.
#    An '@' sign indicates an exact (not partial) match.
#
# Examples:
#    ❯ bash-it search ruby rbenv rvm gem rake
#          aliases:  bundler
#          plugins:  chruby chruby-auto ruby rbenv rvm ruby
#      completions:  rvm gem rake
#
#    ❯ bash-it search ruby rbenv rvm gem rake -chruby
#          aliases:  bundler
#          plugins:  ruby rbenv rvm ruby
#      completions:  rvm gem rake
#
# Examples of enabling or disabling results of the search:
#
#    ❯ bash-it search ruby
#          aliases:  bundler
#          plugins:  chruby chruby-auto ruby
#
#    ❯ bash-it search ruby -chruby --enable
#          aliases:  bundler
#          plugins:  ruby
#
# Examples of using exact match:
#
#    ❯ bash-it search @git @ruby
#          aliases:  git
#          plugins:  git ruby
#      completions:  git
#

_bash-it-search () {
  _about 'searches for given terms amongst bash-it plugins, aliases and completions'
  _param '1: term1'
  _param '2: [ term2 ]...'
  _example '$ _bash-it-search @git ruby -rvm rake bundler'

  [[ -z "$(type _bash-it-array-contains-element 2>/dev/null)" ]] && source "${BASH_IT}/lib/utilities.bash"

  local component
  export BASH_IT_SEARCH_USE_COLOR=true
  export BASH_IT_GREP=${BASH_IT_GREP:-$(which egrep)}
  declare -a BASH_IT_COMPONENTS=(aliases plugins completions)

  if [[ -z "$*" ]] ; then
    _bash-it-search-help
    return 0
  fi

  local -a args=()
  for word in $@; do
    if [[ ${word} == "--help" || ${word} == "-h" ]]; then
      _bash-it-search-help
      return 0
    elif [[ ${word} == "--refresh" || ${word} == "-r" ]]; then
      _bash-it-clean-component-cache
    elif [[ ${word} == "--no-color" || ${word} == '-c' ]]; then
      export BASH_IT_SEARCH_USE_COLOR=false
    else
      args=(${args[@]} ${word})
    fi
  done

  if [[ ${#args} -gt 0 ]]; then
    for component in "${BASH_IT_COMPONENTS[@]}" ; do
      _bash-it-search-component "${component}" "${args[@]}"
    done
  fi

  return 0
}

_bash-it-is-partial-match () {
  local component="$1"
  local term="$2"

  _bash-it-component-help "${component}" | $(_bash-it-grep) -E -i -q -- "${term}"
}

_bash-it-component-term-matches-negation () {
  local match="$1"; shift
  local negative

  for negative in "$@"; do
    [[ "${match}" =~ "${negative}" ]] && return 0
  done

  return 1
}

_bash-it-search-component () {
  local component="$1"

  shift

  _about 'searches for given terms amongst a given component'
  _param '1: component type, one of: [ aliases | plugins | completions ]'
  _param '2: term1 term2 @term3'
  _param '3: [-]term4 [-]term5 ...'
  _example '$ _bash-it-search-component aliases @git rake bundler -chruby'

  # if one of the search terms is --enable or --disable, we will apply this action to the matches further down.
  local component_singular action action_func
  local -a search_commands=(enable disable)

  for search_command in "${search_commands[@]}"; do
    if $(_bash-it-array-contains-element "--${search_command}" "$@"); then
      component_singular=${component}
      # handle aliases -> alias and plugins -> plugin
      component_singular=${component_singular/es/}
      component_singular=${component_singular/ns/n}

      action="${search_command}"
      action_func="_${action}-${component_singular}"
      break
    fi
  done

   # passed on the command line
  local -a terms=($@)

  unset exact_terms
  unset partial_terms
  unset negative_terms

  # terms that should be included only if they match exactly
  local -a exact_terms=()
  # terms that should be included if they match partially
  local -a partial_terms=()
  # negated partial terms that should be excluded
  local -a negative_terms=()

  unset component_list
  local -a component_list=( $(_bash-it-component-list "${component}") )
  local term

  for term in "${terms[@]}"; do
    local search_term="${term:1}"

    if [[ "${term:0:2}" == "--" ]] ; then
      continue
    elif [[ "${term:0:1}" == "-"  ]] ; then
      negative_terms=(${negative_terms[@]} "${search_term}")
    elif [[ "${term:0:1}" == "@"  ]] ; then
      if $(_bash-it-array-contains-element "${search_term}" "${component_list[@]}"); then
        exact_terms=(${exact_terms[@]} "${search_term}")
      fi
    else
      partial_terms=(${partial_terms[@]} $(_bash-it-component-list-matching "${component}" "${term}") )
    fi
  done

  local -a total_matches=( $(_bash-it-array-dedup ${exact_terms[@]} ${partial_terms[@]}) )

  unset matches
  declare -a matches=()
  for match in ${total_matches[@]}; do
    local include_match=true

    if  [[ ${#negative_terms[@]} -gt 0 ]]; then
      ( _bash-it-component-term-matches-negation "${match}" "${negative_terms[@]}" ) && include_match=false
    fi
    ( ${include_match} ) && matches=(${matches[@]} "${match}")
  done
  _bash-it-search-result "${component}" "${action}" "${action_func}" "${matches[@]}"
  unset matches final_matches terms
}

_bash-it-search-result () {
  local component="$1"; shift
  local action="$1"; shift
  local action_func="$1"; shift
  local -a matches=($@)
  local color_component color_enable color_disable color_off

  color_sep=':'

  ( ${BASH_IT_SEARCH_USE_COLOR} ) && {
    color_component='\e[1;34m'
    color_enable='\e[1;32m'
    suffix_enable=''
    suffix_disable=''
    color_disable='\e[0;0m'
    color_off='\e[0;0m'
  }

  ( ${BASH_IT_SEARCH_USE_COLOR} ) || {
    color_component=''
    suffix_enable=' ✓ ︎'
    suffix_disable='  '
    color_enable=''
    color_disable=''
    color_off=''
  }

  local match
  local modified=0

  if [[ "${#matches[@]}" -gt 0 ]] ; then
    printf "${color_component}%13s${color_sep} ${color_off}" "${component}"

    for match in "${matches[@]}"; do
      local enabled=0

      ( _bash-it-component-item-is-enabled "${component}" "${match}" ) && enabled=1

      local match_color compatible_action suffix opposite_suffix

      (( ${enabled} )) && {
        match_color=${color_enable}
        suffix=${suffix_enable}
        opposite_suffix=${suffix_disable}
        compatible_action="disable"
      }

      (( ${enabled} )) || {
        match_color=${color_disable}
        suffix=${suffix_disable}
        opposite_suffix=${suffix_enable}
        compatible_action="enable"
      }

      local m="${match}${suffix}"
      local len
      len=${#m}

      printf " ${match_color}${match}${suffix}"
      if [[ "${action}" == "${compatible_action}" ]]; then
        if [[ ${action} == "enable" && ${BASH_IT_SEARCH_USE_COLOR} == false ]]; then
          _bash-it-flash-term ${len} "${match}${suffix}"
        else
          _bash-it-erase-term ${len}
        fi
        modified=1
        result=$(${action_func} ${match})
        local temp="color_${compatible_action}"

        match_color=${!temp}
        _bash-it-rewind ${len}
        printf "${match_color}${match}${opposite_suffix}"
      fi

      printf "${color_off}"
    done

    [[ ${modified} -gt 0 ]] && _bash-it-clean-component-cache ${component}
    printf "\n"
  fi
}

_bash-it-rewind () {
  local len="$1"

  printf "\033[${len}D"
}

_bash-it-flash-term () {
  local len="$1"
  local match="$2"
  local delay=0.1
  local color

  for color in ${text_black} ${BLUE} ${bold_yellow} ${bold_red} ${GREEN} ; do
    sleep ${delay}
    _bash-it-rewind "${len}"
    printf "${color}${match}"
  done
}

_bash-it-erase-term () {
  local len="$1"
  _bash-it-rewind ${len}
  for a in {0..30}; do
    [[ ${a} -gt ${len} ]] && break
    printf "%.*s" $a " "
    sleep 0.05
  done
}

_bash-it-search-help () {
  printf "${NC}
${YELLOW}USAGE${NC}

   bash-it search [-|@]term1 [-|@]term2 ... \\
     [ --enable   | -e ] \\
     [ --disable  | -d ] \\
     [ --no-color | -c ] \\
     [ --refresh  | -r ] \\
     [ --help     | -h ]

${YELLOW}DESCRIPTION${NC}

   Use ${GREEN}search${NC} bash-it command to search for a list of terms or term negations
   across all components: aliases, completions and plugins. Components that are
   enabled are shown in green (or with a check box if --no-color option is used).

   In addition to simply finding the right component, you can use the results
   of the search to enable or disable all components that the search returns.

   When search is used to enable/disable components it becomes clear that
   you must be able to perform not just a partial match, but an exact match,
   as well as be able to exclude some components.

      * To exclude a component (or all components matching a substring) use
        a search term with minus as a prefix, eg '-flow'

      * To perform an exact match, use character '@' in front of the term,
        eg. '@git' would only match aliases, plugins and completions named 'git'.

${YELLOW}FLAGS${NC}
   --enable   | -e    ${MAGENTA}Enable all matching componenents.${NC}
   --disable  | -d    ${MAGENTA}Disable all matching componenents.${NC}
   --help     | -h    ${MAGENTA}Print this help.${NC}
   --refresh  | -r    ${MAGENTA}Force a refresh of the search cache.${NC}
   --no-color | -c    ${MAGENTA}Disable color output and use monochrome text.${NC}

${YELLOW}EXAMPLES${NC}

   For example, ${GREEN}bash-it search git${NC} would match any alias, completion
   or plugin that has the word 'git' in either the module name or
   it's description. You should see something like this when you run this
   command:

         ${GREEN}❯ bash-it search git${BLUE}
               ${YELLOW}aliases:  ${GREEN}git ${NC}gitsvn
               ${YELLOW}plugins:  ${NC}autojump ${GREEN}git ${NC}git-subrepo jgitflow jump
           ${YELLOW}completions:  ${GREEN}git ${NC}git_flow git_flow_avh${NC}

   You can exclude some terms by prefixing a term with a minus, eg:

         ${GREEN}❯ bash-it search git -flow -svn${BLUE}
               ${YELLOW}aliases:  ${NC}git
               ${YELLOW}plugins:  ${NC}autojump git git-subrepo jump
           ${YELLOW}completions:  ${NC}git${NC}

   Finally, if you prefix a term with '@' symbol, that indicates an exact
   match. Note, that we also pass the '--enable' flag, which would ensure
   that all matches are automatically enabled. The example is below:

         ${GREEN}❯ bash-it search @git --enable${BLUE}
               ${YELLOW}aliases:  ${NC}git
               ${YELLOW}plugins:  ${NC}git
           ${YELLOW}completions:  ${NC}git${NC}

${YELLOW}SUMMARY${NC}

   Take advantage of the search functionality to discover what Bash-It can do
   for you. Try searching for partial term matches, mix and match with the
   negative terms, or specify an exact matches of any number of terms. Once
   you created the search command that returns ONLY the modules you need,
   simply append '--enable' or '--disable' at the end to activate/deactivate
   each module.

"
}
