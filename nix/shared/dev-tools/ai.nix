{ pkgs ? import <nixpkgs> {}, ... }: {
  environment.systemPackages = with pkgs; [
    # AI in the terminal
    unstable.aichat

    # Agents
    copkgs.pi       # nightly.pi
    copkgs.opencode # nightly.opencode

    unstable.claude-code

    copkgs.beads # nightly.beads # Advanced todo list for AI
    nightly.beads_viewer # Beads viewer for visualizing beads data

    ## TOOLS (mostly for AI agents)
    copkgs.gob                      # Parallel job runner for AI
    unstable.jira-cli-go            # Allow agent to access jira
    copkgs.qmd                      # On-device search engine for markdown notes, meeting transcripts, and knowledge bases

    copkgs.mcpli   # Run mcp as cli
  ];
}
