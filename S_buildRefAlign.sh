#!/usr/bin/env bash
set -euo pipefail

function quit_pb_option() {
    printf "\nOptions : --in_refSeq --in_seqFile [--in_geneticCode] [--out_refAlign] [--debug]\n"
    exit 1
}
source S_utilIO.sh
trap clean_tmp_dir $tmp_dir EXIT

# get parameters
debug=0
in_geneticCode=2
while (( $# > 0 )); do
    case "$1" in
	     --in_refSeq)      in_refSeq=$(get_in_file_param "$1" "$2");    shift 2 ;;
	     --in_seqFile)     in_seqFile=$(get_in_file_param "$1" "$2");   shift 2;;
	     --in_geneticCode) in_geneticCode="$2"; shift 2 ;;
       --out_refAlign)   out_refAlign=$(get_out_file_param "$1" "$2"); shift 2;;
	      *) printf "Option $1 is unknown please ckeck your command line"; quit_pb_option;;
    esac
done

# check that mandatory parameters are set
printf "$in_refSeq $in_seqFile" || quit_pb_option

module load bioinfo/vsearch/2.14.0

tmp_dir=$(get_tmp_dir "__build_ref");
wd=$(PWD)

cd tmp_dir
cp $in_refSeq in.fasta
cat $in_seqFile >> in.fasta
vsearch -cluster_smallmem in.fasta --strand both --uc clust_res --usersort --centroids centroids.fasta --id 0.7
cp clust_res centroids.fasta $wd
