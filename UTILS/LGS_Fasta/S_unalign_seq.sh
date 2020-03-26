#!/bin/bash

# on error exit flag : set -e
set -o errexit

# error if a var is unset : set -u
set -o nounset

# raise error in pipe
set -o pipefail

# date : 20171214
# authors : V. Ranwez


######################################
# SCRIPT PARAMETERS
SCRIPT_NAME=$(basename "$0")
function quit_pb_option() {
    printf "\nThis script remove gap character (-) from fasta sequences"
    echo "your command line is incorrect please check your options"
    printf "\n$SCRIPT_NAME --in_seq_file in_file.fasta --out_seq_file out_file.fasta [--keep_FS]\n\n"
    exit 1
}

KEEP_FS=0;
while (( $# > 0 )); do
    case "$1" in

        --in_seq_file)
            IN_SEQ_FILE="$2";  shift 2
            if [ ! -r  $IN_SEQ_FILE ]; then
              echo " INPUT FILE $IN_SEQ_FILE does not exist or is not readable"
              quit_pb_option
            fi
            ;;
        --out_seq_file)
            OUT_SEQ_FILE="$2";  shift 2
            ;;

        --keep_FS)
            KEEP_FS=1;  shift 1
            ;;
        *)
            echo "Option $1 is unknown please ckeck your command line"
            quit_pb_option
            ;;
    esac
done
cp $1 $2
if(( KEEP_FS >0 )); then
  sed -i -e '/^[^>]/s/[-]//g' $2
else
  sed -i -e '/^[^>]/s/[-!]//g' $2
fi
