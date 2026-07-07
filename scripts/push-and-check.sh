#!/usr/bin/env bash
#
# push-and-check.sh — push and automatically verify CI status
#
# Usage:
#   bash scripts/push-and-check.sh
#   bash scripts/push-and-check.sh --wait    # wait for CI to complete
#
# What it does:
#   1. Pushes current branch to origin
#   2. Checks GitHub API for latest workflow run status
#   3. Displays result (PASS/FAIL/RUNNING)

set -euo pipefail

WAIT_MODE=0
REPO="stsgs1980/Z-ai-governance"

for arg in "$@"; do
    case "$arg" in
        --wait) WAIT_MODE=1 ;;
        --help|-h) sed -n '2,16p' "$0"; exit 0 ;;
        *) echo "Unknown flag: $arg"; exit 2 ;;
    esac
done

# 1. Push
echo "Pushing..."
if ! git push 2>&1; then
    echo "Push failed"
    exit 1
fi

# 2. Wait for CI to start
sleep 2

# 3. Check CI status
check_ci() {
    local response
    response=$(curl -s "https://api.github.com/repos/$REPO/actions/runs?per_page=1" 2>/dev/null)

    if [ -z "$response" ]; then
        echo "Cannot reach GitHub API"
        return 1
    fi

    echo "$response" | node -e "
        const d=require('fs').readFileSync('/dev/stdin','utf8');
        try {
            const j=JSON.parse(d);
            if (!j.workflow_runs || j.workflow_runs.length === 0) {
                console.log('NO_RUNS');
                return;
            }
            const r=j.workflow_runs[0];
            console.log(r.status + '|' + r.conclusion + '|' + r.html_url);
        } catch(e) {
            console.log('PARSE_ERROR');
        }
    "
}

echo "Checking CI status..."

if [ $WAIT_MODE -eq 1 ]; then
    echo "Waiting for CI to complete (Ctrl+C to stop)..."
    while true; do
        result=$(check_ci || echo "ERROR")
        status=$(echo "$result" | cut -d'|' -f1)
        conclusion=$(echo "$result" | cut -d'|' -f2)
        url=$(echo "$result" | cut -d'|' -f3)

        case "$status" in
            completed)
                if [ "$conclusion" = "success" ]; then
                    echo "PASS: CI passed"
                    echo "URL: $url"
                    exit 0
                else
                    echo "FAIL: CI failed ($conclusion)"
                    echo "URL: $url"
                    exit 1
                fi
                ;;
            in_progress|queued|waiting|requested|pending|expected|neutral|stale)
                echo "RUNNING: $status"
                sleep 10
                ;;
            *)
                echo "Status: $status"
                sleep 10
                ;;
        esac
    done
else
    result=$(check_ci || echo "ERROR")
    status=$(echo "$result" | cut -d'|' -f1)
    conclusion=$(echo "$result" | cut -d'|' -f2)
    url=$(echo "$result" | cut -d'|' -f3)

    case "$status" in
        completed)
            if [ "$conclusion" = "success" ]; then
                echo "PASS: CI passed"
            else
                echo "FAIL: CI failed ($conclusion)"
            fi
            ;;
        in_progress|queued|waiting|requested|pending|expected|neutral|stale)
            echo "RUNNING: CI is $status"
            ;;
        *)
            echo "Status: $status"
            ;;
    esac
    echo "URL: $url"
fi
