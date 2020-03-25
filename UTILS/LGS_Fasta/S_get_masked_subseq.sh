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
    printf "\nThis script remove lower case letters (masked) from fasta sequences"
    echo "your command line is incorrect please check your options"
    printf "\n$SCRIPT_NAME --in_seq_file infile.fasta --out_seq_file outfile.fasta \n\n"
    exit 1
}

while (( $# > 0 )); do
    echo "parse $1"
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
        *)
            echo "Option $1 is unknown please ckeck your command line"
            quit_pb_option
            ;;
    esac
done
cp "$IN_SEQ_FILE" "$OUT_SEQ_FILE"
sed -i -e '/^[^>]/s/[a-z]//g' "$OUT_SEQ_FILE"
