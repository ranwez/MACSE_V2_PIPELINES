#!/usr/bin/env bash
set -Euo pipefail

SCRIPT_NAME=$(basename "$0")

function quit_pb_option() {
    printf "\n\nThis script transform the input fasta file so that each sequence is written on a single line.\n"
    printf "\nyour command line is incorrect please check your options"
    printf "\n usage example:\n$SCRIPT_NAME --in_seq_file input.fasta --out_seq_file output_1L.fasta \n"
    exit 1
}

# author : V. Ranwez
LG_UTILS=${LG_UTILS_PATH}
source "$LG_UTILS"/S_utilIO.sh

while (( $# > 0 )); do
    case "$1" in
	     --in_seq_file)                IN_SEQ_FILE=$(get_in_file_param "$1" "$2")               || quit_pb_option ; shift 2;;
	     --out_seq_file)               OUT_SEQ_FILE=$(get_out_file_param "$1" "$2")               || quit_pb_option ; shift 2;;
	      *) printf "Option $1 is unknown please ckeck your command line"; quit_pb_option;;
    esac
done

# check that mandatory parameters are set
# https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
if [ -z ${IN_SEQ_FILE+x}  ];    then printf "mandatory --in_seq_file is missing";     quit_pb_option; fi
if [ -z ${OUT_SEQ_FILE+x} ];    then printf "mandatory --OUT_SEQ_FILE is missing";    quit_pb_option; fi
awk 'BEGIN{first=1} {if ($0 ~ /^>/){if(first==0){printf "\n"}; printf($0"\n"); first=0;}else {printf $0}} END{printf "\n"}' "$IN_SEQ_FILE" > "$OUT_SEQ_FILE"
