#!/usr/bin/env bash
set -Euo pipefail

# author : V. Ranwez

##############################################################
## handle parameters and IO files/folders
##############################################################

# get useful directory with absolute path and include dependencies
script_name=$(basename "$0")
wd_dir="$PWD"
script_dir=$(dirname $(readlink -f "$0"))
source "$script_dir"/S_utilIO.sh


function quit_pb_option() {
    printf "\n\nOptions: --in_refSeq --in_seqFile [--in_geneticCode] [--out_repSeq] [--out_homologSeq] [--out_listRevComp] [--in_minClustSize] [--in_maxRepresentativeSeqs] [--debug]\n"
    printf "\n usage example:\n$script_name --in_refSeq DATA/Hsapiens_COI5P.fasta --in_seqFile DATA/Mammalia_BOLD_141145seq_2020.fasta --in_geneticCode 2 \n"
    printf "\n\nFor further details please check the documentation on MACSE website: https://bioweb.supagro.inra.fr/macse\n\n"
    exit 1
}

#handle parameters
debug=0; in_geneticCode=2; in_minClustSize=10; in_maxRepresentativeSeqs=100;

while (( $# > 0 )); do
    case "$1" in
	     --in_refSeq)                  in_refSeq=$(get_in_file_param "$1" "$2")                   || quit_pb_option ; shift 2;;
	     --in_seqFile)                 in_seqFile=$(get_in_file_param "$1" "$2")                  || quit_pb_option ; shift 2;;
	     --in_geneticCode)             in_geneticCode=$(get_in_int_param "$1" "$2")               || quit_pb_option ; shift 2;;
       --in_minClustSize)            in_minClustSize=$(get_in_int_param "$1" "$2")              || quit_pb_option ; shift 2;;
       --in_maxRepresentativeSeqs)   in_maxRepresentativeSeqs=$(get_in_int_param "$1" "$2")     || quit_pb_option ; shift 2;;
       --out_repSeq)                 out_repSeq=$(get_out_file_param "$1" "$2")                 || quit_pb_option ; shift 2;;
       --out_homologSeq)             out_homologSeq=$(get_out_file_param "$1" "$2")             || quit_pb_option ; shift 2;;
       --out_listRevComp)            out_listRevComp=$(get_out_file_param "$1" "$2")            || quit_pb_option ; shift 2;;
       --debug)                      debug=1                                                                      ; shift 1;;
	      *) printf "Option $1 is unknown please ckeck your command line"; quit_pb_option;;
    esac
done

# check that mandatory parameters are set
# https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
if [ -z ${in_refSeq+x}  ]; then printf "mandatory --in_refSeq is missing";  quit_pb_option; fi
if [ -z ${in_seqFile+x} ]; then printf "mandatory --in_seqFile is missing"; quit_pb_option; fi

#check if default file/folder names should be used (done afterward in case default values trigger errors)
if [ -z ${out_repSeq+x}  ];     then out_repSeq=$(get_out_file_param "--out_repSeq"     "representative_seq_NT.fasta")      || quit_pb_option; fi
if [ -z ${out_homologSeq+x}  ]; then out_homologSeq=$(get_out_file_param "--out_homologSeq" "homologous_seq_NT.fasta") || quit_pb_option; fi
if [ -z ${out_listRevComp+x}  ];then out_listRevComp=$(get_out_file_param "--out_listRevComp" "revComp_seq_ids.list")       || quit_pb_option; fi


# handle temporary folder and files
tmp_dir=$(get_tmp_dir "__build_ref");
trap 'clean_tmp_dir $debug "$tmp_dir"' EXIT
cd $tmp_dir

##############################################################
## set software PATH
##############################################################
#local usage, set your own path toward the three required tools
mmseqs="/usr/local/bioinfo/singularity/3.4.2/bin/singularity exec /usr/local/bioinfo/MMseqs2/11-e1a1c/MMseqs2.11-e1a1c.img mmseqs"
macse="$wd_dir"/macse_v2.03.jar
seqtk="seqtk"
#as part of the Singularity container they are directly available
seqtk="seqtk"
mmseqs="mmseqs"
macse=$SING_MACSE;
##############################################################
## identify sequences similar to the reference one
##############################################################
java -jar -Xmx800m $macse -prog translateNT2AA -gc_def $in_geneticCode -seq $in_refSeq -out_AA ref_seq_AA.fasta

cp $in_seqFile __seqs.fasta
$mmseqs easy-search __seqs.fasta ref_seq_AA.fasta  res_search.tsv TMP --search-type 2 --translation-table $in_geneticCode --split-memory-limit 70G --format-output "query,qaln,qstart,qend,qcov"

awk '{if($5>0.5 && $4>$3) print $1}' res_search.tsv | sort -T $tmp_dir -u > relevant_dir_id
awk '{if($5>0.5 && $3>$4) print $1}' res_search.tsv | sort -T $tmp_dir -u > relevant_rev_id

$seqtk subseq $in_seqFile relevant_dir_id > relevant_dir.fasta
$seqtk subseq $in_seqFile relevant_rev_id > relevant_rev_tmp.fasta
$seqtk seq -r relevant_rev_tmp.fasta > relevant_rev.fasta
sed -i -e 's/^>/>revComp_/' relevant_rev.fasta
mv relevant_dir.fasta relevant_seq.fasta
cat relevant_rev.fasta >> relevant_seq.fasta

##############################################################
## cluster these sequences at the AA level 100% identify
##############################################################
awk '{seq=gsub("-","",$2); print ">"$1"\n"$2""}' res_search.tsv > relevant_seqAA.fasta
$mmseqs easy-cluster relevant_seqAA.fasta --min-seq-id 1 -c 1 --cov-mode 1 ClusterRes TMP

##############################################################
## get the centroid of each large sequence cluster
##############################################################
cut -f1 ClusterRes_cluster.tsv | sort -T $tmp_dir| uniq -c | sort -T $tmp_dir-n | awk -v N=${in_minClustSize} '{if($1>N){print $2}}' | tail -$in_maxRepresentativeSeqs >representatives_id
$seqtk subseq relevant_seq.fasta representatives_id > representatives.fasta


##############################################################
## save usevul results
##############################################################
cp representatives.fasta $out_repSeq
cp relevant_seq.fasta $out_homologSeq
cp relevant_rev_id $out_listRevComp

cd $wd_dir
