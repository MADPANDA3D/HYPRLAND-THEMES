#!/usr/bin/env bash
set -euo pipefail

field="${1:-}"
cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/madpanda/pandora-media/current.json"
[[ -n "$field" && -r "$cache_file" ]] || exit 0

jq -r --arg field "$field" '
    def clean:
        if type == "string" then gsub("\\s+"; " ") | gsub("^\\s+|\\s+$"; "")
        else ""
        end;

    def self_test:
        (((.pageUrl // "") | test("/self-test|/plan-smoke")) or
         ((((.title // "") | clean) == "Bridge self-test" or
           ((.title // "") | clean) == "Plan Smoke") and
          ((.artist // "") | clean) == "MADPANDA"));

    def service_error:
        (((.artist // "") | clean) == "" and
         ((.album // "") | clean) == "" and
         ((.artUrl // "") | clean) == "" and
         ((.artPath // "") | clean) == "" and
         (((.title // "") | clean | ascii_downcase | contains("service unavailable")) or
          ((.title // "") | clean | test("^(500|502|503|504)\\b"))));

    if ((now - (.updatedAtEpoch // 0)) < 180) and (self_test | not) and (service_error | not) then
        .[$field] // empty
    else
        empty
    end
' "$cache_file" 2>/dev/null
