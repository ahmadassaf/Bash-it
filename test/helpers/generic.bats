#!/usr/bin/env bats

load ../helper
load ../../lib/composure

cite about param example group

load ../../lib/helpers/generic

local_setup () {
  prepare
}

@test "bash-it helpers: _is_function: should return a success status if the passed argument is a function" {
  test_function () {
    echo "I am a test!"
  }

  run _is_function test_function
  assert_success
}

@test "bash-it helpers: _is_function: should return a fail status if the passed argument is not a function" {
  run _is_function "I am a test!"
  assert_failure
}

@test "bash-it helpers: _command_exists function exists" {
  run type -a _command_exists &> /dev/null
  assert_success
}

@test "bash-it helpers: _command_exists function positive test ls" {
  run _command_exists ls
  assert_success
}

@test "bash-it helpers: _command_exists function negative test" {
  run _command_exists __addfkds_dfdsjdf
  assert_failure
}

@test "bash-it helpers: _command_exists function negative test with a default message" {
  run _command_exists a
  assert_failure
  assert_output "command a does not exist!"
}

@test "bash-it helpers: _command_exists function negative test with a custom message" {
  run _command_exists a "this function doesn't exist"
  assert_failure
  assert_output "this function doesn't exist"
}

@test "bash-it helpers: _array-contains: should be successful if an element is found in array" {
  declare -a fruits=(apple orange pear mandarin)

  run _array-contains "pear" "${fruits[@]}"
  assert_success

  run _array-contains "apple" "${fruits[@]}"
  assert_success

  run _array-contains "mandarin" "${fruits[@]}"
  assert_success
}

@test "bash-it helpers: _array-contains: should fail if an element is not found in array" {
  declare -a fruits=(apple orange pear mandarin)

  run _array-contains "cucumber" "${fruits[@]}"
  assert_failure

  run _array-contains "APPLE" "${fruits[@]}"
  assert_failure
}

@test "bash-it helpers: _clean-string: should trim all whitespaces" {
  local _test=" test test test "

  run _clean-string "$_test" "any" &> /dev/null
  assert_success
  assert_output "testtesttest"
}

@test "bash-it helpers: _clean-string: should trim trailing whitespaces" {
  local _test=" test test test "

  run _clean-string "$_test" "trailing" &> /dev/null
  assert_success
  assert_output " test test test"
}

@test "bash-it helpers: _clean-string: should trim leading and trailing spaces" {
  local _test=" test test test "

  run _clean-string "$_test" "all" &> /dev/null
  assert_success
  assert_output "test test test"
}

@test "bash-it helpers: _clean-string: should trim leading spaces" {
  local _test=" test test test "

  run _clean-string "$_test" "leading" &> /dev/null
  assert_success
  assert_output "test test test "
}

@test "bash-it helpers: _array-dedupe: should remove duplicates from array and return it sorted" {
  declare -a array_a=(apple orange pear mandarin)
  declare -a array_b=(apple pear apricot cucumber orange)

  run _array-dedupe "${array_a[@]}" "${array_b[@]}" &> /dev/null
  assert_success
  assert_output "apple apricot cucumber mandarin orange pear"
}

@test 'bash-it helpers: pathmunge: ensure function is defined' {
  run type -t pathmunge
  assert_line 'function'
}

@test 'bash-it helpers: pathmunge: single path' {
  local new_paths='/tmp/fake-pathmunge-path'
  local old_path="${PATH}"

  pathmunge "${new_paths}"
  assert_equal "${new_paths}:${old_path}" "${PATH}"
}

@test 'bash-it helpers: pathmunge: single path, with space' {
  local new_paths='/tmp/fake pathmunge path'
  local old_path="${PATH}"

  pathmunge "${new_paths}"
  assert_equal "${new_paths}:${old_path}" "${PATH}"
}

@test 'bash-it helpers: pathmunge: multiple paths' {
  local new_paths='/tmp/fake-pathmunge-path1:/tmp/fake-pathmunge-path2'
  local old_path="${PATH}"

  pathmunge "${new_paths}"
  assert_equal "${new_paths}:${old_path}" "${PATH}"
}

@test 'bash-it helpers: pathmunge: multiple paths, with space' {
  local new_paths='/tmp/fake pathmunge path1:/tmp/fake pathmunge path2'
  local old_path="${PATH}"

  pathmunge "${new_paths}"
  assert_equal "${new_paths}:${old_path}" "${PATH}"
}

@test 'bash-it helpers: pathmunge: multiple paths, with duplicate' {
  local new_paths='/tmp/fake-pathmunge-path1:/tmp/fake pathmunge path2:/tmp/fake-pathmunge-path1:/tmp/fake-pathmunge-path3'
  local want_paths='/tmp/fake pathmunge path2:/tmp/fake-pathmunge-path1:/tmp/fake-pathmunge-path3'
  local old_path="${PATH}"

  pathmunge "${new_paths}"
  assert_equal "${want_paths}:${old_path}" "${PATH}"
}
