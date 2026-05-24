#!/bin/bash
# DO hook — blocks dangerous Bash commands before they execute

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$CMD" | grep -qE "terraform destroy|aws s3 rm|aws s3 rb"; then
  echo '{"decision": "block", "reason": "Destructive command detected. Use /tf-destroy for terraform destroy, or /deploy for S3 operations."}'
fi
