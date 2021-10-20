export PATH=$PATH:/Users/crosa/.multirust/toolchains/stable/cargo/bin
RUST_ENV=$HOME/.cargo/env
if [[ -f "$RUST_ENV" ]]; then
    echo "$RUST_ENV exists. Loading..."
    source "$RUST_ENV"
fi
