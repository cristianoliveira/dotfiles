{ pkgs, co-pkgs, ... }: {
  pkgs.overlays = [ 
    (final: prev: { mypkgs = import co-pkgs { inherit pkgs; }; })
  ];
}
