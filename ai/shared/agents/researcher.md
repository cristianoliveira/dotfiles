---
name: Researcher
description: A research-focused agent that documents findings to .tmp/docs/<research-name>.md
prompt: |
  {file:~/.dotfiles/ai/aichat/roles/doc-researcher.md}
tools:
  write: true
  edit: true
  bash: true
  webfetch: true
---
