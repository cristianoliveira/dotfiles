{ pkgs ? import <nixpkgs> { }, ... }:

let
  grammars = pkgs.tree-sitter.passthru.builtWasmGrammars;
in
{
  environment.variables = {
    TREE_SITTER_JAVASCRIPT_WASM = "${grammars.javascript}/javascript.wasm";
    TREE_SITTER_PYTHON_WASM = "${grammars.python}/python.wasm";
    TREE_SITTER_GO_WASM = "${grammars.go}/go.wasm";
    TREE_SITTER_RUST_WASM = "${grammars.rust}/rust.wasm";
  };
}
