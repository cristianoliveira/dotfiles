function notepath(){
  notedate=$(date +"%Y-%m-%d")
  echo "$HOME/notes/$notedate.txt"
}

function noteit() {
  path=notepath
  echo "__________________" >> "$path"
  echo "$path"
  if [ ! -z "$1" ]; then
    echo "$@" >> "$path"
  else
    cat "$path"
  fi
  echo "__________________" >> "$path"
}

function notedit() {
  if [ ! -z "$1" ]; then
    echo "$@" >> "$notepath"
  fi

  vim "$notepath"
}

function note() {
  cat "$notepath"
}
