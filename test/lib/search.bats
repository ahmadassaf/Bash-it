#!/usr/bin/env bats

load ../helper

load ../../lib/composure

cite about param example group

load ../../lib/helpers
load ../../lib/search

local_setup () {
  prepare

  export OLD_PATH="$PATH"
  export PATH="/usr/bin:/bin:/usr/sbin"
}

local_teardown () {
  export PATH="$OLD_PATH"
  unset OLD_PATH
}

@test "search: plugin base" {
  export BASH_IT_SEARCH_USE_COLOR=false
  run _bash-it-search-component 'plugins' 'base'
  assert_line -n 0 '      plugins:  base ✓  '
}

@test "search: git" {
  run _bash-it-search 'git' --no-color
  assert_line -n 0 '      aliases:  git   gitsvn  '
  assert_line -n 1 -p '      plugins:'

  for plugin in "autojump" "git" "gitstatus" "git-subrepo" "jgitflow" "jump"
  do
    echo $plugin
    assert_line -n 1 -p $plugin
  done
  assert_line -n 2 '  completions:  git ✓ ︎ git_extras   git_flow   git_flow_avh  '
}

@test "search: ruby gem bundle rake rails" {
  run _bash-it-search rails ruby gem bundler rake --no-color

  assert_line -n 0 '      aliases:  bundler   rails  '
  assert_line -n 1 '      plugins:  chruby   ruby  '
  assert_line -n 2 '  completions:  bundler   gem   rake  '
}

@test "search: rails ruby gem bundler rake -chruby" {
  run _bash-it-search rails ruby gem bundler rake -chruby --no-color

  assert_line -n 0 '      aliases:  bundler   rails  '
  assert_line -n 1 '      plugins:  ruby  '
  assert_line -n 2 '  completions:  bundler   gem   rake  '
}

@test "search: @git" {
  run _bash-it-search '@git' --no-color
  assert_line -n 0 '      aliases:  git  '
  assert_line -n 1 '      plugins:  git  '
  assert_line -n 2 '  completions:  git ✓  '
}

@test "search: @git --enable / --disable" {
  set -e
  run _bash-it-search '@git' --enable --no-color
  run _bash-it-search '@git' --no-color

  [[ "${lines[0]}"  =~ '✓' ]]

  run _bash-it-search '@git' --disable --no-color
  run _bash-it-search '@git' --no-color

  assert_line -n 0 '      aliases:  git  '
  assert_line -n 0 '      aliases:  git  '
  assert_line -n 2 '  completions:  git  '
}
