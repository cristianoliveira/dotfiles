NODE_VERSION=v17.4.0

echo; echo "Installing nvm and node $NODE_VERSION"
curl https://raw.githubusercontent.com/creationix/nvm/v0.11.1/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export NVM_NODEJS_ORG_MIRROR=http://nodejs.org/dist

nvm install $NODE_VERSION
nvm alias default $NODE_VERSION

npm install -g yarn

git clone git@github.com:lukechilds/zsh-nvm.git $HOME/.zsh-nvm
