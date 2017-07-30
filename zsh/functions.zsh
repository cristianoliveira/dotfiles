# Lower from python
function lowercase {
    python -c "print('$1'.lower())"
}

# I miss this feature in python
# Install some library on env and save it in given file
# Ex: pip-install-save mock test-requirements.txt
function pip-install-save { pip install $1 && touch $2 && pip freeze | grep $1 >> $2 }

# lazyperson Curl wrappers
function cget { curl -XGET -D - $@ }
function cpost { curl -XPOST -D - $@ }

# lazyperson - makes an directory and enter in it
function mkdircd { mkdir $1 && cd $1 }

# Creates a gif for a given mov file
function gifify() {
  if [[ -n "$1" ]]; then
      if [[ $2 == '--good' ]]; then
            ffmpeg -i $1 -r 10 -vcodec png out-static-%05d.png
            time convert -verbose +dither -layers Optimize -resize 600x600\> out-static*.png  GIF:- | gifsicle --colors 128 --delay=5 --loop --optimize=3 --multifile - > $1.gif
            rm out-static*.png
      else
            ffmpeg -i $1 -s 600x400 -pix_fmt rgb24 -r 10 -f gif - | gifsicle --optimize=3 --delay=3 > $1.gif
      fi
   else
        echo "proper usage: gifify <input_movie.mov>. You DO need to include extension."
   fi
}


# Kills any process that matches a regexp passed to it
function killit() {
    ps aux | grep -v "grep" | grep "$@" | awk '{print $2}' | xargs sudo kill
}

# Shows process running that matches
function psaux() {
    ps aux | grep "$@"
}

# Python stuff

# Workon current directory name
function py.env() {
  workon $(basename $PWD)
}

function auth-token() {
  credentials="$(python -c "import base64; print base64.b64encode('$1:$2')")"
  echo $credentials
  echo "$(curl -XPOST $FN_AUTH_ENDPOINT
    -l 'Authorization: Basic $credentials'
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d grant_type=client_credentials)"
}


