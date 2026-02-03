#!/bin/bash
# Check status of background agents every 2 minutes
# Triggered by any tool use, but time-gated to run only every 2 minutes

set -e

WORKING_DIR="${CLAUDE_WORKING_DIRECTORY:-/home/user/HCD-buddy}"
STATUS_FILE="$WORKING_DIR/.claude/agent-status.md"
LAST_CHECK_FILE="$WORKING_DIR/.claude/.last-agent-check"
AGENT_REGISTRY="$WORKING_DIR/.claude/.agent-registry"
CHECK_INTERVAL=120  # 2 minutes in seconds

# Get current timestamp
NOW=$(date +%s)

# Check if enough time has passed since last check
if [ -f "$LAST_CHECK_FILE" ]; then
    LAST_CHECK=$(cat "$LAST_CHECK_FILE")
    ELAPSED=$((NOW - LAST_CHECK))
    if [ $ELAPSED -lt $CHECK_INTERVAL ]; then
        exit 0  # Not time yet, skip
    fi
fi

# Check if we have any registered agents
if [ ! -f "$AGENT_REGISTRY" ] || [ ! -s "$AGENT_REGISTRY" ]; then
    exit 0  # No agents to check
fi

# Update last check time
echo "$NOW" > "$LAST_CHECK_FILE"

# Create status report
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TASKS_DIR="/tmp/claude/-home-user-HCD-buddy/tasks"

{
    echo "# Agent Status Report"
    echo ""
    echo "**Last Updated:** $TIMESTAMP"
    echo ""
    echo "| Agent | Status | Output Size |"
    echo "|-------|--------|-------------|"

    RUNNING=0
    COMPLETED=0

    while IFS='|' read -r AGENT_ID AGENT_NAME; do
        OUTPUT_FILE="$TASKS_DIR/${AGENT_ID}.output"
        if [ -f "$OUTPUT_FILE" ]; then
            SIZE=$(wc -c < "$OUTPUT_FILE" 2>/dev/null || echo "0")
            # Check if agent is still writing (file modified in last 30 seconds)
            if [ "$(find "$OUTPUT_FILE" -mmin -0.5 2>/dev/null)" ]; then
                STATUS="🔄 Running"
                ((RUNNING++))
            else
                STATUS="✅ Complete"
                ((COMPLETED++))
            fi
            echo "| $AGENT_NAME | $STATUS | ${SIZE} bytes |"
        else
            echo "| $AGENT_NAME | ⏳ Pending | - |"
            ((RUNNING++))
        fi
    done < "$AGENT_REGISTRY"

    echo ""
    echo "**Summary:** $COMPLETED completed, $RUNNING in progress"
    echo ""
} > "$STATUS_FILE"

# Output summary to stderr (visible in hook output)
echo "Agent Status: $COMPLETED completed, $RUNNING running" >&2
