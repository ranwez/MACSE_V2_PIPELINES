#!/usr/bin/env bash
#set -euo pipefail

function get_in_file_param(){
  local file; file=$(readlink -f "$2")
  local has_problem=0
  if [[ ! -f $file ]]; then
    printf "Problem with option $1, File $2 does not exist" >&2
    has_problem=1
  fi
  echo $file
  return $has_problem
}

function get_out_file_param(){
  local file; file=$(readlink -f "$2")
  local has_problem=0
  if [[ -f $file ]]; then
    printf "Problem with option $1, File $2 already  exist" >&2
    has_problem=1
  else
    (touch "$file" && rm "$file") || has_problem=1
  fi
  echo $file
  return $has_problem
}

function get_out_dir_param(){
  local dir=$(readlink -f "$2")
  local has_problem=0
  if [ ! -e  $dir ]; then
    mkdir "$dir"
  else
    printf "Problem with option $1, directory $2 already  exist" >&2
    has_problem=1
  fi
  echo $dir
  return $has_problem
}


function get_in_int_param(){
  local has_problem=0
  local re='^[0-9]+$'
  if ! [[ $2 =~ $re ]]; then
    printf "Problem with option $1,  $2 is not an integer" >&2
    has_problem=1
  fi
  echo $2
  return $has_problem
}


# $1 parameter allows to specify a prefix to identify your tmp folders
function get_tmp_dir(){
  local tmp_dir; tmp_dir=$(mktemp -d -t "$1"_$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXXXX)
  echo $tmp_dir
}

# in debug mode ($1=1), do not delete the temporary directory passed as $2
function clean_tmp_dir(){
  if (( $1==0 )); then
    rm -rf "$2"
  fi
}
