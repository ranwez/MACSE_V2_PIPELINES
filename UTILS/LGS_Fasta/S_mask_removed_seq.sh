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
    printf'"\n This script masked sequences of infile.fasta (put them in lower case) that are not kept (col_keep_info="false" in info.csv) and let those kept (col_keep_info="true") unchanged'
    echo "your command line is incorrect please check your options"
    printf "\n$SCRIPT_NAME --in_seq_file infile.fasta --in_keep_seq_info info.csv [--col_name_info 1] --col_keep_info 8 --out_seq_file maskedfile.fasta \n\n"
    exit 1
}

COL_NAME_INFO=1;
COL_KEEP_INFO=-1;
while (( $# > 0 )); do

    case "$1" in
        --in_seq_file)
            IN_SEQ_FILE="$2";  shift 2
            if [ ! -r  $IN_SEQ_FILE ]; then
              echo " INPUT FILE $IN_SEQ_FILE does not exist or is not readable"
              quit_pb_option
            fi
            ;;

        --in_keep_seq_info)
            IN_KEEP_FILE="$2";  shift 2
            if [ ! -r  $IN_KEEP_FILE ]; then
              echo " INPUT FILE $IN_KEEP_FILE does not exist or is not readable"
              quit_pb_option
            fi
            ;;

          --col_name_info)
              COL_NAME_INFO="$2";  shift 2
              ;;

          --col_keep_info)
              COL_KEEP_INFO="$2";  shift 2
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

echo -n "" > $OUT_SEQ_FILE;
echo "file : $IN_KEEP_FILE"
for l in $(cat $IN_KEEP_FILE) ; do
  s=$(echo $l | cut -f$COL_NAME_INFO -d";")
  k=$(echo $l | cut -f$COL_KEEP_INFO -d";")
  #line without true or false may not contain sequence to grep, e.g. file header
  if [[ $k == "true" ]] ; then
    seq=$(grep -A1 "^>$s$" $IN_SEQ_FILE | tail -1)
    printf ">$s\n$seq\n" >> $OUT_SEQ_FILE
  else
    if [[ $k == "false" ]] ; then
      seq=$(grep -A1 "^>$s$" $IN_SEQ_FILE | tail -1)
      seqRm=$( echo "$seq" | tr '[:upper:]' '[:lower:]')
      printf ">$s\n$seqRm\n" >> $OUT_SEQ_FILE
    fi
  fi
done
