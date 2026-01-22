{ pkgs ? import <nixpkgs> {}, ... }: {
  environment.systemPackages = with pkgs; [
    # AI in the terminal
    unstable.aichat

    # Agents
    nur.repos.charmbracelet.crush
    nightly.codex
    nightly.opencode

    unstable.claude-code

    nightly.beads # Advanced todo list for AI
    nightly.beads_viewer # Beads viewer for visualizing beads data

    ## TOOLS (mostly for AI agents)
    nightly.gob                      # Parallel job runner for AI
    nightly.confluence-cli           # Allow agent to access confluence
    unstable.jira-cli-go             # Allow agent to access jira
  ];
}
