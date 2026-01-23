{ pkgs ? import <nixpkgs> {}, ... }: {
  environment.systemPackages = with pkgs; [
    # AI in the terminal
    unstable.aichat

    # Agents
    nightly.codex
    nightly.opencode

    unstable.claude-code

    nightly.beads # Advanced todo list for AI
    nightly.beads_viewer # Beads viewer for visualizing beads data

    ## TOOLS (mostly for AI agents)
    nightly.gob                      # Parallel job runner for AI
    unstable.jira-cli-go             # Allow agent to access jira
    nightly.qmd                      # On-device search engine for markdown notes, meeting transcripts, and knowledge bases
  ];
}
