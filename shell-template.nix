{ pkgs ? import <nixpkgs> { } }:

let settings = { ... }: { };
in import ~/.config/venv-manager { inherit pkgs settings; }
