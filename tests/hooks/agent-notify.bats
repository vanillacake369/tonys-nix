#!/usr/bin/env bats

@test "agent-notify shell suite passes" {
  run bash "$BATS_TEST_DIRNAME/../../modules/agents/providers/claude/hooks/agent-notify-test.sh"
  [ "$status" -eq 0 ]
}
