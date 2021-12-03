{ config, lib, pkgs, ... }:

with lib;
let cfg = config.nix;
in {
  options.nix = { enable = mkEnableOption "nix"; };

  config = mkIf cfg.enable {
    buildInputs = with pkgs; [
      nixfmt
      nixos-option
      nix-prefetch-scripts
      nix-prefetch-github
    ];
  };
}
