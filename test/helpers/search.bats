#!/usr/bin/env bats

load ../helper
load ../../lib/composure

cite about param example group

load ../../lib/bash-it
load ../../lib/search
load ../../lib/helpers/utils
load ../../lib/helpers/components
load ../../lib/helpers/search

local_setup () {
  prepare
}

@test "bash-it helpers: search: _bash-it-rewind should successfully rewind the output by N chars" {

  run _bash-it-rewind
  assert_success

  run printf "AAA$(_bash-it-rewind 2)AA"
  assert_success
  assert_output "AAA[2DAA"

  run printf "AAA$(_bash-it-rewind 2)AAA"
  assert_success
  assert_output "AAA[2DAAA"
}
