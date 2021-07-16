#!/usr/bin/env bash
set -Euo pipefail

# author : V. Ranwez


######################################
# SCRIPT PARAMETERS
SCRIPT_NAME=$(basename "$0")
OPTIONS="$@"
DATE=$(date)

printf "\n\n" # separate script message from the rest

function quit_pb_option() {
    printf "\n\nThis script aligns sequences using: 1) MACSE pre-filtering, 2) MACSE alignment to find frameshifts, 3) MAFFT for aligning the resulting AA sequences, and 4) HMMcleaner for cleaning resulting alignments.\n"
    printf "\nyour command line is incorrect please check your options"
    printf "\n usage example:\n$SCRIPT_NAME --out_dir out_dir --out_file_prefix PREFIX --in_seq_file seq_file.fasta [--genetic_code_number code_number] [--alignAA_soft MAFFT/MUSCLE/PRANK] ][--aligner_extra_option \"--localpair --maxiterate 1000\"] [--min_percent_NT_at_ends 0.7] [--out_detail_dir SAVE_DETAILS/] [--in_seq_lr_file less_reliable_seq_file.fasta] [--java_mem 500m] [--no_prefiltering] [--no_FS_detection] [--no_filtering] [--no_postfiltering] [--min_seqToKeepSite] [--replace_FS_by_gaps] [--save_details] [--debug]\n"
    printf "\n\nFor further details please check the documentation on MACSE website: https://bioweb.supagro.inra.fr/macse\n\n"
    exit 1
}

# get useful directory with absolute path and include dependencies
script_name=$(basename "$0")
wd_dir="$PWD"
script_dir=$(dirname $(readlink -f "$0"))
LG_UTILS=${LG_UTILS_PATH}
source "$LG_UTILS"/S_utilIO.sh

#handle parameters

PRE_FILTERING=1; POST_FILTERING=1; FILTERING=1; FS_DETECTION=1; REPLACE_FS_GAP=0
HAS_SEQ_LR=0; SEQ_LR_OPT="";GC_OPT=""
ALIGN_SOFT="MAFFT"; ALIGNER_EXTRA_OPTION=""
SAVE_DETAILS=0; debug=0;JAVA_MEM=250m
MIN_PERCENT_NT_AT_ENDS=0.7; MIN_SEQ_TO_KEEP_SITE=0; REPLACE_FS_GAP=0


while (( $# > 0 )); do
    case "$1" in
	     --in_seq_file)                IN_SEQ_FILE=$(get_in_file_param "$1" "$2")               || quit_pb_option ; shift 2;;
	     --in_seq_lr_file)             IN_SEQ_LR_FILE=$(get_in_file_param "$1" "$2")            || quit_pb_option ; HAS_SEQ_LR=1; SEQ_LR_OPT="-seq_lr $IN_SEQ_LR_FILE"; shift 2;;
	     --genetic_code_number)        in_geneticCode=$(get_in_int_param "$1" "$2")             || quit_pb_option ; GC_OPT=" -gc_def $in_geneticCode"; shift 2;;
       --java_mem)                   JAVA_MEM="$2"                                            || quit_pb_option ; shift 2;;
       --out_dir)                    OUT_DIR=$(get_out_dir_param "$1" "$2")                  || quit_pb_option ; shift 2;;
       --out_file_prefix)            PREFIX="$2"                                              || quit_pb_option ; shift 2;;
       --min_percent_NT_at_ends)     MIN_PERCENT_NT_AT_ENDS="$2"                              || quit_pb_option ; shift 2;;
       --out_detail_dir)             OUT_DETAIL_DIR=$(get_out_file_param "$1" "$2")           || quit_pb_option ; SAVE_DETAILS=1; shift 2;;
       --no_prefiltering)            PRE_FILTERING=0                                                            ; shift 1;;
       --no_FS_detection)            FS_DETECTION=0                                                             ; shift 1;;
       --no_filtering)               FILTERING=0                                                                ; shift 1;;
       --no_postfiltering)           POST_FILTERING=0                                                           ; shift 1;;
       --min_seqToKeepSite)          MIN_SEQ_TO_KEEP_SITE=$(get_in_int_param "$1" "$2")                         ; shift 2;;
       --replace_FS_by_gaps)         REPLACE_FS_GAP=1                                                           ; shift 1;;
       --debug)                      debug=1                                                                    ; shift 1;;
       --save_details)               SAVE_DETAILS=1                                                             ; shift 1;;
       --alignAA_soft)               ALIGN_SOFT="$2"                                           || quit_pb_option; shift 2
           if [[ ! "$ALIGN_SOFT" =~ ^(MAFFT|MUSCLE|PRANK)$ ]];  then
             echo " Alignment software $ALIGN_SOFT is not handle, please choose between MAFFT or MUSCLE"; quit_pb_option
           fi
           ;;
       --aligner_extra_option)       ALIGNER_EXTRA_OPTION="$2"                                || quit_pb_option ; shift 2;;
	      *) printf "Option $1 is unknown please ckeck your command line"; quit_pb_option;;
    esac
done

# handle aligner default options
if [ -z ${aligner_extra_option+x}  ];    then
  case $ALIGN_SOFT in
    "MAFFT" ) ALIGNER_EXTRA_OPTION="--localpair --maxiterate 1000";;
  *) ALIGNER_EXTRA_OPTION=""
  esac
fi


# check that mandatory parameters are set
# https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
if [ -z ${IN_SEQ_FILE+x}  ];    then printf "mandatory --in_seq_file is missing";     quit_pb_option; fi
if [ -z ${OUT_DIR+x} ];         then printf "mandatory --out_dir is missing";         quit_pb_option; fi
if [ -z ${PREFIX+x} ]; then printf "mandatory --PREFIX is missing"; quit_pb_option; fi


printf "============================ PROCESSING $PREFIX\n"

######################################
# PROGRAMS ENVIRONMENT
mafft="${LG_MAFFT} --quiet $ALIGNER_EXTRA_OPTION"
muscle="${LG_MUSCLE} $ALIGNER_EXTRA_OPTION"
prank="${LG_PRANK} $ALIGNER_EXTRA_OPTION"
hmmcleaner="perl ${LG_HMMCLEANER}"
macse="java -jar -Xmx${JAVA_MEM} ${LG_MACSE}"

######################################
# handle temporary folder and files
tmp_dir=$(get_tmp_dir "__OMM_$PREFIX");
trap 'clean_tmp_dir $debug "$tmp_dir"' EXIT
cd $tmp_dir

######################################
#filter sequences and identify frameshift using MACSE

touch __${PREFIX}_homol_tmp_NT_lr.fasta

cp $IN_SEQ_FILE __all_seq.fasta;
if (( $HAS_SEQ_LR > 0 )); then
    echo "" >> __all_seq.fasta; cat "$IN_SEQ_LR_FILE">> __all_seq.fasta;
fi

if(( $PRE_FILTERING > 0)); then
    printf "\n\n============== MACSE PRE_FILTERING\n"
    if (( $HAS_SEQ_LR > 0 )); then
        $macse -prog trimNonHomologousFragments $GC_OPT -seq __all_seq.fasta -out_NT __${PREFIX}_homol_tmp_NT_all.fasta -out_AA __${PREFIX}_homol_tmp_all_AA.fasta -out_trim_info __${PREFIX}_homol_fiter.csv -out_mask_detail __${PREFIX}_NonHomolFilter_NT_mask_detail.fasta -min_trim_in 60 -min_trim_ext 45 -debug
        __${PREFIX}_homol_tmp_NT_all.fasta
        for s in $(grep ">" $IN_SEQ_FILE); do grep -A1 -e"$s$" __${PREFIX}_homol_tmp_NT_all.fasta; done >  __${PREFIX}_homol_tmp_NT.fasta
        for s in $(grep ">" $IN_SEQ_LR_FILE); do grep -A1 -e"$s$" __${PREFIX}_homol_tmp_NT_all.fasta; done >  __${PREFIX}_homol_tmp_NT_lr.fasta
    else
      $macse -prog trimNonHomologousFragments $GC_OPT -seq __all_seq.fasta -out_NT __${PREFIX}_homol_tmp_NT.fasta -out_AA __${PREFIX}_homol_tmp_AA.fasta -out_trim_info __${PREFIX}_homol_fiter.csv -out_mask_detail __${PREFIX}_NonHomolFilter_NT_mask_detail.fasta -min_trim_in 60 -min_trim_ext 45 -debug
    fi

    nbKeep=$(grep -c ";true$" __${PREFIX}_homol_fiter.csv)
    if(( nbKeep==0)); then
      printf "\nError: no sequence kept after the pre-filtering. This prefiltering is well adapted when your input sequence file contains many sequences (e.g > 20 sequences).\n In other cases it could be better to turn it off using the --no_prefiltering option\n" >&2
      exit 1
    fi
else
    cp $IN_SEQ_FILE __${PREFIX}_homol_tmp_NT.fasta
    if (( $HAS_SEQ_LR > 0 )); then
        cp "$IN_SEQ_LR_FILE" __${PREFIX}_homol_tmp_NT_lr.fasta
    fi
    # ensure that the sequence are written on a single line also in this case
    $LG_UTILS/LGS_Fasta/S_fasta1L.sh --in_seq_file __${PREFIX}_homol_tmp_NT.fasta --out_seq_file __${PREFIX}_homol_tmp_NT_1L.fasta
    rm __${PREFIX}_homol_tmp_NT.fasta; mv __${PREFIX}_homol_tmp_NT_1L.fasta __${PREFIX}_homol_tmp_NT.fasta

    echo "seqName;initialSeqLength;nbKeep;nbTrim;nbInformativeTrim;percentHomologExcludingExtremities;percentHomologIncludingExtremities;keptSequences" >__${PREFIX}_homol_fiter.csv
    for s in $(grep ">" __all_seq.fasta | cut -f2 -d">"); do
          echo "${s};NA;NA;NA;NA;NA;NA;true" >>__${PREFIX}_homol_fiter.csv
    done
    $LG_UTILS/LGS_Fasta/S_unmask_seq.sh --in_seq_file __all_seq.fasta --out_seq_file __${PREFIX}_NonHomolFilter_NT_mask_detail.fasta

fi

if(( FS_DETECTION > 0 )); then
  printf "\n\n============== MACSE FRAMESHIFT DETECTION\n"
  SEQ_LR_OPT="";
  if [ -s "__${PREFIX}_homol_tmp_NT_lr.fasta" ]; then SEQ_LR_OPT="-seq_lr __${PREFIX}_homol_tmp_NT_lr.fasta"; fi
  echo "$macse -prog alignSequences $GC_OPT -seq __${PREFIX}_homol_tmp_NT.fasta  $SEQ_LR_OPT -optim 2 -max_refine_iter 3 -local_realign_init 0.2 -out_NT __${PREFIX}_homol_tmp_NT.aln -out_AA __${PREFIX}_homol_tmp_AA.aln"
  $macse -prog alignSequences $GC_OPT -seq __${PREFIX}_homol_tmp_NT.fasta $SEQ_LR_OPT -optim 2 -max_refine_iter 3 -local_realign_init 0.2 -out_NT __${PREFIX}_homol_tmp_NT.aln -out_AA __${PREFIX}_homol_tmp_AA.aln

  #check if it is fine or not
  if [ ! -f __${PREFIX}_homol_tmp_NT.aln ] ; then
      printf "\n\nSomething goes wrong with MACSE alignSequences subprogram.\nIn absence of other error message, this is generally link to memory problems.\n Try to re-launch the script with extra memory using the --java_mem option: e.g. --java_mem 2000m\n"
      exit 1;
  fi
  #prepare fasta file
   sed -e '/^[^>]/s/-*//g'  __${PREFIX}_homol_tmp_NT.aln > __${PREFIX}_homol_NT.fasta # unaligned NT but with FS preserved
   sed -e '/^[^>]/s/-*//g'  __${PREFIX}_homol_tmp_AA.aln > __${PREFIX}_homol_AA.fasta # unaligned AA but preserve FS and stop
else
  cp __${PREFIX}_homol_tmp_NT.fasta __${PREFIX}_homol_NT.fasta
  cat __${PREFIX}_homol_tmp_NT_lr.fasta >> __${PREFIX}_homol_NT.fasta
  $macse -prog translateNT2AA $GC_OPT -keep_final_stop_ON -seq __${PREFIX}_homol_NT.fasta -out_AA __${PREFIX}_homol_AA.fasta
fi
sed -i -e '/^[^>]/s/[!*?]/X/g'  __${PREFIX}_homol_AA.fasta                         # mask FS and STOP that are not understand except by MACSE

######################################
# align AA sequences
printf "\n\n============== ALIGN AMINO SEQUENCES\n"

#align AA using third party program and report gap in NT seq. Show the command line to the user
set -x
case $ALIGN_SOFT in
  "MAFFT" )
    ${mafft} __${PREFIX}_homol_AA.fasta > __${PREFIX}_homol_AA.aln
    ;;
  "MUSCLE" )
    ${muscle} -in __${PREFIX}_homol_AA.fasta -out __${PREFIX}_homol_AA.aln
    ;;
  "PRANK" )
    ${prank} -d=__${PREFIX}_homol_AA.fasta -o=__${PREFIX}_homol_AA.aln; mv __${PREFIX}_homol_AA.aln.best.fas __${PREFIX}_homol_AA.aln;
    ;;
esac
set +x
# get the NT and AA alignment with * and !
$macse -prog reportGapsAA2NT $GC_OPT -align_AA  __${PREFIX}_homol_AA.aln -seq __${PREFIX}_homol_NT.fasta -out_NT __${PREFIX}_homol_NT.aln
cp __${PREFIX}_homol_NT.aln __${PREFIX}_unmask_NT.aln
$macse -prog translateNT2AA $GC_OPT -seq __${PREFIX}_unmask_NT.aln -out_AA __${PREFIX}_unmask_AA.aln -keep_final_stop_ON


######################################
# filer alignment (based on AA translation) using HMMcleaner

if(( $FILTERING > 0)); then
    printf "\n\n============== FILTER ALIGNMENTS\n"
    THRESHOLD=10 # lower is more stringeant, S. Glemin used 5 for Triticea, 10 is the advised value
    $hmmcleaner --del-char $ ./__${PREFIX}_homol_AA.aln ${THRESHOLD}

    printf "\n\n============== MACSE REPORT FILTERING\n"
    if (( $POST_FILTERING > 0 )); then
      $macse -prog reportMaskAA2NT -mask_AA $  -align_AA  __${PREFIX}_homol_AA_Hmm${THRESHOLD}.fasta -align __${PREFIX}_homol_NT.aln -out_NT __${PREFIX}_final_homol_NT.aln -out_mask_detail __${PREFIX}_hmmCleaner_mask2_detail.aln -min_NT_to_keep_seq 100 -mask_AA $ -min_seq_to_keep_site $MIN_SEQ_TO_KEEP_SITE -min_percent_NT_at_ends ${MIN_PERCENT_NT_AT_ENDS} -dist_isolate_AA 3 -min_homology_to_keep_seq 0.3 -min_internal_homology_to_keep_seq 0.5
    else
      $macse -prog reportMaskAA2NT -mask_AA $  -align_AA  __${PREFIX}_homol_AA_Hmm${THRESHOLD}.fasta -align __${PREFIX}_homol_NT.aln -out_NT __${PREFIX}_final_homol_NT.aln -out_mask_detail __${PREFIX}_hmmCleaner_mask2_detail.aln -min_NT_to_keep_seq -1 -mask_AA $ -min_seq_to_keep_site $MIN_SEQ_TO_KEEP_SITE -min_percent_NT_at_ends -1 -dist_isolate_AA -1 -min_homology_to_keep_seq -1 -min_internal_homology_to_keep_seq -1 # vérifier tous les -1 sont correctement gérés par MACSE
    fi

    printf "\n\n============== MACSE TRANSLATE\n"
    $macse -prog translateNT2AA $GC_OPT -seq __${PREFIX}_final_homol_NT.aln -out_AA __${PREFIX}_final_homol_AA.aln

  else
    cp __${PREFIX}_unmask_NT.aln __${PREFIX}_final_homol_NT.aln
    cp __${PREFIX}_unmask_AA.aln __${PREFIX}_final_homol_AA.aln
fi


cp __${PREFIX}_final_homol_NT.aln __${PREFIX}_final_homol_NTOK.aln
cp __${PREFIX}_final_homol_AA.aln __${PREFIX}_final_homol_AAOK.aln

if(( $REPLACE_FS_GAP > 0)); then
  $macse -prog exportAlignment $GC_OPT  -align __${PREFIX}_final_homol_NTOK.aln -codonForInternalStop NNN -codonForFinalStop NNN -codonForInternalFS --- -codonForExternalFS --- -out_NT __${PREFIX}_final_homol_NTOK_export.aln -out_AA __${PREFIX}_final_homol_AAOK_export.aln
else
  $macse -prog exportAlignment $GC_OPT  -align __${PREFIX}_final_homol_NTOK.aln -codonForInternalStop NNN -codonForFinalStop NNN -codonForInternalFS NNN -codonForExternalFS NNN -out_NT __${PREFIX}_final_homol_NTOK_export.aln -out_AA __${PREFIX}_final_homol_AAOK_export.aln

fi

cp __${PREFIX}_final_homol_NTOK.aln $OUT_DIR/${PREFIX}_final_mask_align_NT.aln
cp __${PREFIX}_final_homol_AAOK.aln $OUT_DIR/${PREFIX}_final_mask_align_AA.aln

cp __${PREFIX}_final_homol_NTOK_export.aln $OUT_DIR/${PREFIX}_final_align_NT.aln
cp __${PREFIX}_final_homol_AAOK_export.aln $OUT_DIR/${PREFIX}_final_align_AA.aln

printf "\n\n============== MACSE merge masks if needed \n"


if(( ${PRE_FILTERING} > 0 || ${FILTERING} > 0)); then
  cp __${PREFIX}_unmask_NT.aln $OUT_DIR/${PREFIX}_final_unmask_align_NT.aln
  cp __${PREFIX}_unmask_AA.aln $OUT_DIR/${PREFIX}_final_unmask_align_AA.aln
fi

if(( ${PRE_FILTERING} > 0 && ${FILTERING} == 0 )); then
    ${LG_UTILS}/LGS_Fasta/S_mask_removed_seq.sh --in_seq_file __${PREFIX}_NonHomolFilter_NT_mask_detail.fasta --in_keep_seq_info __${PREFIX}_homol_fiter.csv --out_seq_file __${PREFIX}_NonHomolFilter_RmSeq_NT_mask_detail.fasta --col_keep_info 8
    cp __${PREFIX}_homol_fiter.csv $OUT_DIR/${PREFIX}_maskHomolog_stat.csv
    cp __${PREFIX}_homol_fiter.csv $OUT_DIR/${PREFIX}_maskFull_stat.csv
    cp __${PREFIX}_NonHomolFilter_RmSeq_NT_mask_detail.fasta $OUT_DIR/${PREFIX}_maskFull_detail.fasta
fi

if(( ${FILTERING} > 0 )); then
    $LG_UTILS/LGS_Fasta/S_mask_removed_seq.sh --in_seq_file __${PREFIX}_NonHomolFilter_NT_mask_detail.fasta --in_keep_seq_info __${PREFIX}_homol_fiter.csv --out_seq_file __${PREFIX}_NonHomolFilter_RmSeq_NT_mask_detail.fasta --col_keep_info 8
    $macse -prog mergeTwoMasks -mask_file1 __${PREFIX}_NonHomolFilter_RmSeq_NT_mask_detail.fasta -mask_file2 __${PREFIX}_hmmCleaner_mask2_detail.aln -out_mask_detail __${PREFIX}_maskFull_detail.fasta -out_trim_info __${PREFIX}_maskFull_stat.csv
    cp __${PREFIX}_homol_fiter.csv $OUT_DIR/${PREFIX}_maskHomolog_stat.csv
    cp __${PREFIX}_maskFull_stat.csv $OUT_DIR/${PREFIX}_maskFull_stat.csv
    cp __${PREFIX}_maskFull_detail.fasta $OUT_DIR/${PREFIX}_maskFull_detail.fasta
fi

cp $script_dir/readme_output.txt $OUT_DIR/
printf "\n\nThis analysis was done with \n\t-script: $script_name\n\t-parmaeters:$OPTIONS\n\t-directory:$wd_dir\n\t-date:$DATE:" >> $OUT_DIR/readme_output.txt

cd $wd_dir

printf "\n\n==============  $PREFIX processed\n\n"
