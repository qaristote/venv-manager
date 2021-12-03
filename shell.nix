{ pkgs ? import <nixpkgs> { } }:

let settings = { nix.enable = true; };
in import ./. { inherit pkgs settings; }
