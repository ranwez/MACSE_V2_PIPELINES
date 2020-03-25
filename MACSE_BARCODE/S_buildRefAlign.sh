#!/usr/bin/env bash
set -Euo pipefail


##############################################################
## handle parameters and IO files/folders
##############################################################

# get useful directory with absolute path and include dependencies
wd_dir="$PWD"
script_dir=$(dirname $(readlink -f "$0"))
source "$script_dir"/S_utilIO.sh


function quit_pb_option() {
    printf "\nOptions : --in_refSeq --in_seqFile [--in_geneticCode] [--out_refAlign] [--debug]\n"
    exit 1
}

#handle parameters
debug=0; in_geneticCode=2 # set default values
while (( $# > 0 )); do
    case "$1" in
	     --in_refSeq)      in_refSeq=$(get_in_file_param "$1" "$2") || quit_pb_option    ; shift 2;;
	     --in_seqFile)     in_seqFile=$(get_in_file_param "$1" "$2")|| quit_pb_option    ; shift 2;;
	     --in_geneticCode) in_geneticCode="$2"                                           ; shift 2;;
       --out_refAlign)   out_refAlign=$(get_out_file_param "$1" "$2")|| quit_pb_option ; shift 2;;
       --debug)          debug=1                                                       ; shift 1;;
	      *) printf "Option $1 is unknown please ckeck your command line"; quit_pb_option;;
    esac
done

# check that mandatory parameters are set
# https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
if [ -z ${in_refSeq+x}  ]; then printf "mandatory --in_refSeq is missing";  quit_pb_option; fi
if [ -z ${in_seqFile+x} ]; then printf "mandatory --in_seqFile is missing"; quit_pb_option; fi

# handle temporary folder and files
tmp_dir=$(get_tmp_dir "__build_ref");
trap 'clean_tmp_dir $debug "$tmp_dir"' EXIT
cd $tmp_dir

##############################################################
## start working get sequences similar to the ref one
##############################################################
module load system/java/jre8
module load bioinfo/MMseqs2/11-e1a1c
module load bioinfo/seqtk/1.3-r106


java -jar -Xmx800m "$wd_dir"/macse_v2.03.jar -prog translateNT2AA -gc_def $in_geneticCode -seq $in_refSeq -out_AA ref_seq_AA.fasta

#singularity exec /usr/local/bioinfo/MMseqs2/11-e1a1c/MMseqs2.11-e1a1c.img mmseqs easy-search ../DATA/Mammalia_BOLD_141145seq_2020.fasta homo_sapiens_ref_AA.fasta res.aln TMP --search-type 2 --translation-table 2 --split-memory-limit 70G --format-output "query,qaln,qstart,qend,tcov,qframe"
cp $in_seqFile __seqs.fasta
singularity exec /usr/local/bioinfo/MMseqs2/11-e1a1c/MMseqs2.11-e1a1c.img mmseqs easy-search __seqs.fasta ref_seq_AA.fasta  res_search.tsv TMP --search-type 2 --translation-table 2 --split-memory-limit 70G --format-output "query,qaln,qstart,qend,tcov"
#mmseqs easy-search __seqs.fasta ref_seq_AA.fasta  res_search.tsv TMP --search-type 2 --translation-table 2 --split-memory-limit 70G --format-output "query,qaln,qstart,qend,tcov"

awk '{if($4>$3) print $1}' res_search.tsv >relevant_dir_id
awk '{if($3>$4) print $1}' res_search.tsv >relevant_rev_id


seqtk subseq $in_seqFile relevant_dir_id > relevant_dir.fasta
seqtk subseq $in_seqFile relevant_rev_id > relevant_rev_tmp.fasta
seqtk seq -r relevant_rev_tmp.fasta > relevant_rev.fasta
mv relevant_dir.fasta relevant_seq.fasta
cat relevant_rev.fasta >> relevant_seq.fasta

awk '{seq=gsub("-","",$2); print ">"$1"\n"$2""}' res_search.tsv > relevant_seqAA.fasta
singularity exec /usr/local/bioinfo/MMseqs2/11-e1a1c/MMseqs2.11-e1a1c.img mmseqs easy-cluster relevant_seqAA.fasta --min-seq-id 1 -c 1 --cov-mode 1 ClusterRes TMP
cut -f1 ClusterRes_cluster.tsv | sort | uniq -c | sort -n | awk '{if($1>100){print $2}}'>representatives_id
seqtk subseq relevant_seq.fasta representatives_id > representatives.fasta

qsub -b y -N ali -q normal.q "module unload system/singularity/2.6.0; module load system/singularity/3.4.2; ${wd_dir}/OMM_MACSE_v10.01.sif --in_seq_file representatives.fasta --out_dir REF_ALIGN --out_file_prefix refAlign --genetic_code_number 2 --alignAA_soft MAFFT --min_percent_NT_at_ends 0.2"
# the export does not handle the genetic genetic_code
cp -r REF_ALIGN $wd_dir
cp -r $tmp_dir $wd_dir
cp REF_ALIGN/refAlign_final_mask_align_NT.aln  $wd_dir/refAlign_final_NT.aln

exit 1

#vsearch -cluster_smallmem in.fasta --strand plus --uc clust_res --usersort --centroids centroids.fasta --id 0.7
#qsub -b y -N buildRef -q normal.q "/homedir/ranwez/GITHUB/macse_barcode/S_buildRefAlign.sh --in_seqFile DATA/Mammalia_BOLD_141145seq_2020.fasta --in_refSeq DATA/Homo_sapiens_NC_012920_COI-5P_ref.fasta --debug"

# qsub -b y -N blast -q normal.q "blastx -query ../DATA/Mammalia_BOLD_141145seq_2020.fasta -subject homo_sapiens_ref_AA.fasta -evalue 0.00001 -outfmt '6 qseqid qframe' > res_blastX"
