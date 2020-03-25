#!/bin/bash

# on error exit flag : set -e
set -o errexit

# error if a var is unset : set -u
set -o nounset

# raise error in pipe
set -o pipefail

# authors : V. Ranwez

######################################
# SCRIPT PARAMETERS
SCRIPT_NAME=$(basename "$0")
function quit_pb_option() {
    printf "\nThis script align coding nucleotide sequences using MACSE and HMMcleaner. For large dataset the OMM_MACSE pipeline is better adapted.\n"
    printf "your command line is incorrect please check your options"
    printf "\n$SCRIPT_NAME --out_dir out_dir --out_file_prefix out_file_prefix --in_seq_file seq_file.fasta [--genetic_code_number code_number]  [--min_percent_NT_at_ends 0.7] [--out_detail_dir SAVE_DETAILS/] [--in_seq_lr_file less_reliable_seq_file.fasta] [--java_mem 500m] [--no_prefiltering] [--no_FS_detection] [--no_filtering] [--no_postfiltering] [--replace_FS_by_gaps] [--save_details]\n\n"
    printf "\n\nFor further details please check the documentation on MACSE website: https://bioweb.supagro.inra.fr/macse\n\n"

    exit 1
}



PRE_FILTERING=1
POST_FILTERING=1
FILTERING=1
FS_DETECTION=1
HAS_SEQ_LR=0
SEQ_LR_OPT=""
GC_OPT=""
SAVE_DETAILS=0
JAVA_MEM=250m
REPLACE_FS_GAP=0
MIN_PERCENT_NT_AT_ENDS=0.7


#https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash/33826763#33826763
#while true; do
if (( $# == 0)); then
  quit_pb_option
fi

printf "\n\n============== PARSING OPTIONS\n"
while (( $# > 0 )); do
    echo "parse option $1"
    case "$1" in
        --out_dir)
            OUT_DIR="$2"; shift 2;
            if [ ! -e  $OUT_DIR ]; then
              mkdir "$OUT_DIR"
            fi
            ;;
        --out_file_prefix)
            OUT_FILE_PREFIX="$2"; PREFIX="$2"; shift 2;
            ;;
        --in_seq_file)
            IN_SEQ_FILE="$2";  shift 2
            if [ ! -r  $IN_SEQ_FILE ]; then
              echo " INPUT FILE $IN_SEQ_FILE does not exist or is not readable"
              quit_pb_option
            fi
            ;;
        --min_percent_NT_at_ends)
            MIN_PERCENT_NT_AT_ENDS="$2";  shift 2
            ;;
        --java_mem)
            JAVA_MEM="$2"; shift 2
            ;;
        --in_seq_lr_file)
            IN_SEQ_LR_FILE=$2
            HAS_SEQ_LR=1
            SEQ_LR_OPT="-seq_lr ../$IN_SEQ_LR_FILE"
            if [ ! -r  $IN_SEQ_FILE ]; then
              echo " INPUT FILE $IN_SEQ_LR_FILE does not exist or is not readable"
              quit_pb_option
            fi
            shift 2
            ;;
        --out_detail_dir)
            OUT_DETAIL_DIR=$2
            SAVE_DETAILS=1
            shift 2
            if [ ! -e  $OUT_DETAIL_DIR ]; then
              mkdir "$OUT_DETAIL_DIR"
            fi
            ;;
        --genetic_code_number)
            GC_OPT=" -gc_def $2 ";  shift 2
            ;;
        --no_prefiltering)
                PRE_FILTERING=0;  shift 1
                ;;
        --no_FS_detection)
                FS_DETECTION=0;  shift 1
                ;;
        --no_filtering)
                FILTERING=0;  shift 1
                ;;
        --no_postfiltering)
                POST_FILTERING=0;  shift 1
                ;;
        --replace_FS_by_gaps)
                REPLACE_FS_GAP=1;  shift 1
                ;;
        --save_details)
                SAVE_DETAILS=1;  shift 1
                ;;
        *)
            echo "Option $1 is unknown please ckeck your command line"
            quit_pb_option
            ;;
    esac
done


if [ -e  $OUT_DIR/${OUT_FILE_PREFIX}_homologous_NT.aln ]
then
  echo "stop"
  echo "$OUT_DIR/${OUT_FILE_PREFIX}_homologous_NT.aln: exist filtering and alignment already done => NOTHING TO DO"
  exit 0
fi

printf "============================ PROCESSING $PREFIX\n"

######################################
# PROGRAMS ENVIRONMENT
hmmcleaner="perl ${LG_HMMCLEANER}"
LG_HOME=${LG_HOME_PATH}
macse="java -jar -Xmx${JAVA_MEM} ${LG_MACSE}"
######################################
#create TMP dir
mkdir "__MCS_$PREFIX"
cd "__MCS_$PREFIX"

######################################
#filter sequences using MACSE

if(( $PRE_FILTERING > 0)); then
    printf "\n\n============== MACSE PRE_FILTERING\n"
    $macse -prog trimNonHomologousFragments $GC_OPT -seq ../$IN_SEQ_FILE $SEQ_LR_OPT -out_NT __${PREFIX}_homol_tmp_NT.fasta -out_AA __${PREFIX}_homol_tmp_AA.fasta -out_trim_info __${PREFIX}_homol_fiter.csv -out_mask_detail __${PREFIX}_NonHomolFilter_NT_mask_detail.fasta -min_trim_in 60 -min_trim_ext 45 -debug
else
    cp ../$IN_SEQ_FILE __${PREFIX}_homol_tmp_NT.fasta
    if (( $HAS_SEQ_LR > 0 )); then
        echo "" >> __${PREFIX}_homol_tmp_NT.fasta
        cat "../$IN_SEQ_LR_FILE">> __${PREFIX}_homol_tmp_NT.fasta
    fi

    echo "seqName;initialSeqLength;nbKeep;nbTrim;nbInformativeTrim;percentHomologExcludingExtremities;percentHomologIncludingExtremities;keptSequences" >__${PREFIX}_homol_fiter.csv
    for s in $(grep ">" __${PREFIX}_homol_tmp_NT.fasta | cut -f1 -d">"); do
          echo "${s};NA;NA;NA;NA;NA;NA;NA;true" >>__${PREFIX}_homol_fiter.csv
          $LG_HOME/LGS_Fasta/S_unmask_seq.sh --in_seq_file __${PREFIX}_homol_tmp_NT.fasta --out_seq_file __${PREFIX}_NonHomolFilter_NT_mask_detail.fasta
    done

fi

######################################
# align sequences using MACSE
printf "\n\n============== ALIGN SEQUENCES\n"

$macse -prog alignSequences $GC_OPT -seq __${PREFIX}_homol_tmp_NT.fasta  -out_NT __${PREFIX}_unmask_NT.aln -out_AA __${PREFIX}_unmask_AA.aln

#not optimal but done this way since adapted from OMM_MACSE pipeline
cp __${PREFIX}_unmask_NT.aln __${PREFIX}_homol_NT.aln
cp __${PREFIX}_unmask_AA.aln __${PREFIX}_homol_AA.aln

sed -i -e '/^[^>]/s/[!*?]/X/g'  __${PREFIX}_homol_AA.aln                         # mask FS and STOP that are not understand except by MACSE


######################################
# filer alignment (based on AA translation) using HMMcleaner

if(( $FILTERING > 0)); then
    printf "\n\n============== FILTER ALIGNMENTS\n"
    THRESHOLD=10 # lower is more stringeant, 10 is the advised value
    $hmmcleaner --del-char $ ./__${PREFIX}_homol_AA.aln ${THRESHOLD}

    printf "\n\n============== MACSE REPORT FILTERING\n"
    if (( $POST_FILTERING > 0 )); then
      $macse -prog reportMaskAA2NT -mask_AA $  -align_AA  __${PREFIX}_homol_AA_Hmm${THRESHOLD}.fasta -align __${PREFIX}_homol_NT.aln -out_NT __${PREFIX}_final_homol_NT.aln -out_mask_detail __${PREFIX}_hmmCleaner_mask2_detail.aln -min_NT_to_keep_seq 100 -mask_AA $ -min_seq_to_keep_site 4 -min_percent_NT_at_ends ${MIN_PERCENT_NT_AT_ENDS} -dist_isolate_AA 3 -min_homology_to_keep_seq 0.3 -min_internal_homology_to_keep_seq 0.5
    else
      $macse -prog reportMaskAA2NT -mask_AA $  -align_AA  __${PREFIX}_homol_AA_Hmm${THRESHOLD}.fasta -align __${PREFIX}_homol_NT.aln -out_NT __${PREFIX}_final_homol_NT.aln -out_mask_detail __${PREFIX}_hmmCleaner_mask2_detail.aln -min_NT_to_keep_seq 100 -mask_AA $ -min_seq_to_keep_site -1 -min_percent_NT_at_ends -1 -dist_isolate_AA -1 -min_homology_to_keep_seq -1 -min_internal_homology_to_keep_seq -1 # vérifier tous les -1 sont correctement gérés par MACSE
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
  $macse -prog exportAlignment -align __${PREFIX}_final_homol_NTOK.aln -codonForInternalStop NNN -codonForFinalStop NNN -codonForInternalFS --- -codonForExternalFS --- -out_NT __${PREFIX}_final_homol_NTOK_export.aln -out_AA __${PREFIX}_final_homol_AAOK_export.aln
else
  $macse -prog exportAlignment -align __${PREFIX}_final_homol_NTOK.aln -codonForInternalStop NNN -codonForFinalStop NNN -codonForInternalFS NNN -codonForExternalFS NNN -out_NT __${PREFIX}_final_homol_NTOK_export.aln -out_AA __${PREFIX}_final_homol_AAOK_export.aln
fi

cp __${PREFIX}_final_homol_NTOK.aln ../$OUT_DIR/${OUT_FILE_PREFIX}_final_mask_align_NT.aln
cp __${PREFIX}_final_homol_AAOK.aln ../$OUT_DIR/${OUT_FILE_PREFIX}_final_mask_align_AA.aln

cp __${PREFIX}_final_homol_NTOK_export.aln ../$OUT_DIR/${OUT_FILE_PREFIX}_final_align_NT.aln
cp __${PREFIX}_final_homol_AAOK_export.aln ../$OUT_DIR/${OUT_FILE_PREFIX}_final_align_AA.aln

printf "\n\n============== MACSE merge masks if needed \n"


if(( ${PRE_FILTERING} > 0 || ${FILTERING} > 0)); then
  cp __${PREFIX}_unmask_NT.aln ../$OUT_DIR/${OUT_FILE_PREFIX}_final_unmask_align_NT.aln
  cp __${PREFIX}_unmask_AA.aln ../$OUT_DIR/${OUT_FILE_PREFIX}_final_unmask_align_AA.aln
fi

if(( ${PRE_FILTERING} > 0 && ${FILTERING} == 0 )); then
    ${LG_HOME}/LGS_Fasta/S_mask_removed_seq.sh --in_seq_file __${PREFIX}_NonHomolFilter_NT_mask_detail.fasta --in_keep_seq_info __${PREFIX}_homol_fiter.csv --out_seq_file __${PREFIX}_NonHomolFilter_RmSeq_NT_mask_detail.fasta --col_keep_info 8
    cp __${PREFIX}_homol_fiter.csv ../$OUT_DIR/${OUT_FILE_PREFIX}_maskHomolog_stat.csv
    cp __${PREFIX}_homol_fiter.csv ../$OUT_DIR/${OUT_FILE_PREFIX}_maskFull_stat.csv
    cp __${PREFIX}_NonHomolFilter_RmSeq_NT_mask_detail.fasta ../$OUT_DIR/${OUT_FILE_PREFIX}_maskFull_detail.fasta
fi

if(( ${FILTERING} > 0 )); then
    $LG_HOME/LGS_Fasta/S_mask_removed_seq.sh --in_seq_file __${PREFIX}_NonHomolFilter_NT_mask_detail.fasta --in_keep_seq_info __${PREFIX}_homol_fiter.csv --out_seq_file __${PREFIX}_NonHomolFilter_RmSeq_NT_mask_detail.fasta --col_keep_info 8
    $macse -prog mergeTwoMasks -mask_file1 __${PREFIX}_NonHomolFilter_RmSeq_NT_mask_detail.fasta -mask_file2 __${PREFIX}_hmmCleaner_mask2_detail.aln -out_mask_detail __${PREFIX}_maskFull_detail.fasta -out_trim_info __${PREFIX}_maskFull_stat.csv
    cp __${PREFIX}_homol_fiter.csv ../$OUT_DIR/${OUT_FILE_PREFIX}_maskHomolog_stat.csv
    cp __${PREFIX}_maskFull_stat.csv ../$OUT_DIR/${OUT_FILE_PREFIX}_maskFull_stat.csv
    cp __${PREFIX}_maskFull_detail.fasta ../$OUT_DIR/${OUT_FILE_PREFIX}_maskFull_detail.fasta
fi

cp $LG_HOME/readme_output.txt ../$OUT_DIR/

cd ..

if(( SAVE_DETAILS>0 )); then
  mv __MCS_$PREFIX $OUT_DETAIL_DIR
else
  rm -rf "__MCS_$PREFIX"
fi
printf "\n\n==============  $PREFIX processed\n\n"
######################################
# command line examples
# rm -rf __MCS_ENSG00000068137_PLEKHH3; /media/sf_vince/My_cloud/Git_renater/linux-genomics/LG_Scripts/LGS_Align/S_filter_and_align_CDS.sh --out_file_prefix ENSG00000068137_PLEKHH3 --out_dir OUT  --in_seq_file ENSG00000068137_PLEKHH3_NT.fasta
# rm -rf __MCS_NIT2/; /media/sf_vince/My_cloud/Git_renater/linux-genomics/LG_Scripts/LGS_Align/S_filter_and_align_CDS.sh --out_file_prefix NIT2 --out_dir OUT  --in_seq_file NIT2/ENSG00000114021_NIT2.fai --in_seq_lr_file NIT2/hmm_ENSG00000114021_NIT2_nt2aa.fam
