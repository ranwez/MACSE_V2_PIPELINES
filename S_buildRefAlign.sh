#!/usr/bin/env bash
set -euo pipefail


##############################################################
## handle parameters and IO files/folders
##############################################################

# get useful directory with absolute path and include dependencies
wd_dir="$PWD"
script_dir=$(dirname $(readlink -f "$0"))
source "$script_dir"/S_utilIO.sh

# calling functions open subshells so simple exit is not enough you have to kill the master shell
trap "exit 1" 10; script_id=$$

function quit_pb_option() {
    printf "\nOptions : --in_refSeq --in_seqFile [--in_geneticCode] [--out_refAlign] [--debug]\n"
    kill -10 $script_id
    echo "toto"
}

#handle parameters
debug=0; in_geneticCode=2 # set default values
while (( $# > 0 )); do
    case "$1" in
	     --in_refSeq)      in_refSeq=$(get_in_file_param "$1" "$2");     shift 2;;
	     --in_seqFile)     in_seqFile=$(get_in_file_param "$1" "$2");    shift 2;;
	     --in_geneticCode) in_geneticCode="$2";                          shift 2;;
       --out_refAlign)   out_refAlign=$(get_out_file_param "$1" "$2"); shift 2;;
       --debug)          debug=1;                                      shift 1;;
	      *) printf "Option $1 is unknown please ckeck your command line"; quit_pb_option;;
    esac
done

# check that mandatory parameters are set
# https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
if [ -z ${in_refSeq+x}  ]; then printf "mandatory --in_refSeq is missing";  quit_pb_option; fi
if [ -z ${in_seqFile+x} ]; then printf "mandatory --in_seqFile is missing"; quit_pb_option; fi

# handle temporary folder and files
tmp_dir=$(get_tmp_dir "__build_ref"); mkdir $tmp_dir
trap clean_tmp_dir $debug "$tmp_dir" EXIT
cd tmp_dir

##############################################################
## start working
##############################################################
module load bioinfo/vsearch/2.14.0
cp $in_refSeq in.fasta
cat $in_seqFile >> in.fasta
vsearch -cluster_smallmem in.fasta --strand both --uc clust_res --usersort --centroids centroids.fasta --id 0.7
cp clust_res centroids.fasta $wd_dir
