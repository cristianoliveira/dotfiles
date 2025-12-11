{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    go

    # Debugging
    wrapped.delve
  ];
}
