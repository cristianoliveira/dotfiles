TMP_FOLDER=~/.fasd

git clone https://github.com/clvv/fasd.git $TMP_FOLDER

cd $TMP_FOLDER
make install

rm -rf $TMP_FOLDER
