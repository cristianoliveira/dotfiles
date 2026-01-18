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

    nightly.gob # Parallel job runner for AI
  ];
}
