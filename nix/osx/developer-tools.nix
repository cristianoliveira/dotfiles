{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    colima # docker runtime 
  ];
}
