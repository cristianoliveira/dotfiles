# clone a repository simple doing:
# githubclone 'cristianoliveira/dotfiles'
function githubclone { `git clone git@github.com:$1.git` }

function gitupdatefolder { `find . -maxdepth 1 -type d -print -execdir git --git-dir={}/.git --work-tree=$PWD/{} pull origin master \;` }
