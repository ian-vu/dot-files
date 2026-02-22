#!/bin/bash

# Claude Code Status Line Script
# This script generates a status line showing directory, git, Python, and AWS information

# Read input JSON from stdin
input=$(cat)

# Debug: uncomment the next line to see the actual JSON structure
# echo "$input" | jq . > /tmp/claude-statusline-debug.json

# Extract current working directory from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Extract cost and duration information (if available)
# Using correct field paths from Claude Code documentation
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null || echo "")
duration=$(echo "$input" | jq -r '.cost.total_duration_ms // empty' 2>/dev/null || echo "")
cd "$cwd" 2>/dev/null || true

# Directory information
dir_info="📁 $(basename "$cwd") "

# Git information
git_info=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null || echo 'detached')
  git_status=""

  # Count staged files
  # staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  #
  # # Count unstaged files
  # unstaged=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  #
  # # Count untracked files
  # untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  #
  # # Get ahead/behind counts
  # ahead_behind=$(git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null || echo '0\t0')
  # ahead=$(echo "$ahead_behind" | cut -f1)
  # behind=$(echo "$ahead_behind" | cut -f2)

  # Build git status indicators
  if [ "$staged" -gt 0 ]; then
    git_status="${git_status}+$staged "
  fi
  if [ "$unstaged" -gt 0 ]; then
    git_status="${git_status}~$unstaged "
  fi
  if [ "$untracked" -gt 0 ]; then
    git_status="${git_status}?$untracked "
  fi
  if [ "$ahead" -gt 0 ]; then
    git_status="${git_status}↑$ahead "
  fi
  if [ "$behind" -gt 0 ]; then
    git_status="${git_status}↓$behind "
  fi

  git_info="🌱 $branch $git_status"
fi

# Python information
py_info=""
# if command -v python3 >/dev/null 2>&1; then
#     py_ver=$(python3 --version 2>/dev/null | cut -d' ' -f2 2>/dev/null || echo '')
#     if [ -n "$py_ver" ]; then
#         py_info="🐍$py_ver "
#     fi
#     if [ -n "$VIRTUAL_ENV" ]; then
#         venv_name=$(basename "$VIRTUAL_ENV")
#         py_info="${py_info}($venv_name) "
#     fi
# fi

# AWS information
aws_info=""
if [ -n "$AWS_PROFILE" ]; then
  aws_info="☁️  $AWS_PROFILE "
fi

# AI session information
ai_info=""
model_display_name=$(echo "$input" | jq -r '.model.display_name // empty' 2>/dev/null || echo "")

# Show model if available
if [ -n "$model_display_name" ] && [ "$model_display_name" != "null" ]; then
  ai_info="🤖 ${model_display_name} "
fi

# Cost information
cost_info=""
if [ -n "$cost" ] && [ "$cost" != "null" ] && [ "$cost" != "" ]; then
  cost_rounded=$(printf "%.2f" "$cost")
  cost_info="💰 \$${cost_rounded} "
fi

# Duration information (separate from AI info)
duration_info=""
if [ -n "$duration" ] && [ "$duration" != "null" ] && [ "$duration" != "" ]; then
  if [[ "$duration" =~ ^[0-9]+$ ]]; then
    total_seconds=$((duration / 1000))
    days=$((total_seconds / 86400))
    hours=$(((total_seconds % 86400) / 3600))
    minutes=$(((total_seconds % 3600) / 60))
    seconds=$((total_seconds % 60))

    if [ "$days" -gt 0 ]; then
      duration_info="⏳ ${days}d${hours}h${minutes}m "
    elif [ "$hours" -gt 0 ]; then
      duration_info="⏳ ${hours}h${minutes}m${seconds}s "
    elif [ "$minutes" -gt 0 ]; then
      duration_info="⏳ ${minutes}m${seconds}s "
    else
      duration_info="⏳ ${seconds}s "
    fi
  fi
fi

# Context window usage
context_info=""
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null || echo "0")
if [ -n "$context_pct" ] && [ "$context_pct" != "null" ]; then
  context_rounded=$(printf "%.0f" "$context_pct")
  context_info="🧠 ${context_rounded}% "
fi

# Output the complete status line
# Build output with long pipes between sections
parts=()
for part in "$dir_info" "$py_info" "$aws_info" "$context_info" "$cost_info" "$duration_info"; do
  trimmed=$(echo -n "$part" | sed 's/ *$//')
  [ -n "$trimmed" ] && parts+=("$trimmed")
done
result=""
for i in "${!parts[@]}"; do
  [ "$i" -gt 0 ] && result+=" ┃ "
  result+="${parts[$i]}"
done
echo "$result"
