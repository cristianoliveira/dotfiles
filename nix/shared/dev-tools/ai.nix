{ pkgs ? import <nixpkgs> {}, ... }: {
  environment.systemPackages = with pkgs; [
    # AI in the terminal
    unstable.aichat

    # Agents
    nur.repos.charmbracelet.crush
    nightly.codex
    nightly.opencode

    unstable.claude-code
    unstable.beads # Advanced todo list for AI
  ];
}
