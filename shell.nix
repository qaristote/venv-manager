{ pkgs ? import <nixpkgs> { } }:

let settings = { nix.enable = true; };
in import ~/.config/venv-manager { inherit pkgs settings; }
