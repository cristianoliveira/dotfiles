function notepath(){
  notedate=$(date +"%Y-%m-%d")
  echo "$HOME/notes/$notedate.md"
}

function noteit() {
  echo "__________________" >> "$notepath"
  echo "$notepath"
  if [ ! -z "$1" ]; then
    echo "$@" >> "$notepath"
  else
    cat - >> "$notepath"
  fi
  echo "__________________" >> "$notepath"
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
