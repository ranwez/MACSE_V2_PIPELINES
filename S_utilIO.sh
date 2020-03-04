#!/usr/bin/env bash
#set -euo pipefail

function get_in_file_param(){
  local file=$(readlink -f "$2")
  if [[ ! -f $file ]]; then
    printf "Problem with option $1, File $file does not exist"
    quit_pb_option
  fi
  echo $file
}

function get_out_file_param(){
  local file=$(readlink -f "$2")
  if [[ -f $file ]]; then
    printf "Problem with option $1, File $file already  exist"
    quit_pb_option
  fi
  touch "$file"; rm "$file" || quit_pb_option
  echo $file
}

function get_in_dir_param(){
  local dir=$(readlink -f "$2")
  if [ ! -e  $dir ]; then
    mkdir "$dir"
  fi
  echo $dir
}

# $1 parameter allows to specify a prefix to identify your tmp folders
function get_tmp_dir(){
  local tmp_dir=$(mktemp -d -t "$1"_$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXXXX)
  echo $tmp_dir
}

# in debug mode ($1=1), do not delete the temporary directory passed as $2
function clean_tmp_dir(){
  if (( $1==0 )); then
    printf rm -rf "$2"
  fi
}
