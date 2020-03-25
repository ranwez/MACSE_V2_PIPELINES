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
    printf "\nThis script reorder sequences of in_seq_file2 as they appear in in_seq_file1 "
    printf "\nWARNING this is quite slow and sequence must be on a single line\n"
    printf "\nWARNING sequence in fasta2 not in fasta1 are not in out_seq_file\n"
    echo "your command line is incorrect please check your options"
    printf "\n$SCRIPT_NAME --in_seq_file1 in_file1.fasta --in_seq_file2 in_file2.fasta --out_seq_file in_file.fasta \n\n"
    exit 1
}

KEEP_SPECIFIC_SEQ=0
while (( $# > 0 )); do
    echo "parse $1"
    case "$1" in

        --in_seq_file1)
            IN_SEQ_FILE1="$2";  shift 2
            if [ ! -r  $IN_SEQ_FILE1 ]; then
              echo " INPUT FILE $IN_SEQ_FILE1 does not exist or is not readable"
              quit_pb_option
            fi
            ;;

        --in_seq_file2)
            IN_SEQ_FILE2="$2";  shift 2
            if [ ! -r  $IN_SEQ_FILE2 ]; then
              echo " INPUT FILE $IN_SEQ_FILE2 does not exist or is not readable"
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

#touch $fasta2_reorder; for seq in $(grep ">" $fasta1 ); do grep -A1 $seq $fasta2 >> $fasta2_reorder; done
touch $OUT_SEQ_FILE;
for seq in $(grep ">" $IN_SEQ_FILE1 ); do
  s=$(grep -A1 "^$seq$" $IN_SEQ_FILE2| tail -1);
  printf "$seq\n$s\n">> $OUT_SEQ_FILE
done
