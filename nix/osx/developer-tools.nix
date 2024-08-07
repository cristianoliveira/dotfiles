{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    colima # docker runtime 
  ];

  homebrew.casks = [
    # More dev tools
    "visual-studio-code" # For pairing
    "dbeaver-community" # DB sql client
  ];
}
