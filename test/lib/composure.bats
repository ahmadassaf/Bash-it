#!/usr/bin/env bats

load ../helper
load ../../lib/composure

@test "lib composure: composure_keywords()" {
  run _composure_keywords
  assert_output "about author example group param version"
}
