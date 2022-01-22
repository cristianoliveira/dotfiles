GOLANG_VERSION=go1.17.6

echo "Installing gvm and golang $GOLANG_VERSION"
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

source $HOME/.gvm/scripts/gvm

gvm install $GOLANG_VERSION
gvm use $GOLANG_VERSION --default
