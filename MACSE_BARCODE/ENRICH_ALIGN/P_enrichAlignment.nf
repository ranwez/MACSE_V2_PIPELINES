#! usr/bin/env nextflow

params.refAlign="representatives.aln"
params.seqToAlign="allSeq.fasta"
params.geneticCode="2"
params.outPrefix="Mammals_COI"
params.javaMem="2000m"

params.resultdir= ["$baseDir", "RESULTS_ENRICH_${params.outPrefix}"].join(File.separator)
resultdir = file(params.resultdir)

resultdir.with {
    mkdirs()
}


Channel
    .fromPath( params.seqToAlign )
    .splitFasta( by: 100, file:true)
    .set {fasta_split }

process trimSequences {
  input:
    file seqF from fasta_split
    file refAlignFile from file(params.refAlign)
  output:
    file "${seqF.baseName}_trim_stat.csv" into splitTrimStat
    file "${seqF.baseName}_NT_trimed.fasta" into splitTrimSeq

    """
    java -XX:MaxMetaspaceSize=${params.javaMem} -Xms250m -Xmx${params.javaMem} \
        -jar /UTILS/macse_v2.03.jar -prog trimSequences \
        -align $refAlignFile -gc_def ${params.geneticCode} -seq $refAlignFile -seq_lr $seqF \
        -fs_lr 10 -stop_lr 10 -gap_ext_term 0.1 -gap_op_term 0.7\
        -out_NT_trimmed ${seqF.baseName}_NT_trimed.fasta \
        -out_NT_annotated ${seqF.baseName}_NT_masked.fasta \
        -out_trim_stat ${seqF.baseName}_trim_stat.csv
      """
}

process enrichNoIns {
    input:
      file seqFTrimmed from splitTrimSeq
      file refAlignFile from file(params.refAlign)
    output:
      file "${seqFTrimmed.baseName}_NT.aln" into splitEnrichAln_NT
      file "${seqFTrimmed.baseName}_AA.aln" into splitEnrichAln_AA
      file "${seqFTrimmed.baseName}_stats.csv" into splitEnrichStat
      file "${seqFTrimmed.baseName}_expAA.aln" into splitEnrichAln_AAexp
      file "${seqFTrimmed.baseName}_expNT.aln" into splitEnrichAln_NTexp

      """
      java -XX:MaxMetaspaceSize=${params.javaMem} -Xms250m -Xmx${params.javaMem} \
          -jar /UTILS/macse_v2.03.jar -prog enrichAlignment \
          -align $refAlignFile -gc_def ${params.geneticCode} -seq $refAlignFile -seq_lr $seqFTrimmed \
          -fs_lr 10 -stop_lr 10 -gap_ext_term 0.1 -gap_op_term 0.7\
          -fixed_alignment_ON -new_seq_alterable_ON \
          -maxFS_inSeq 2 -maxINS_inSeq 0 -maxSTOP_inSeq 1 \
          -fixed_alignment_ON -output_only_added_seq_ON\
          -out_NT ${seqFTrimmed.baseName}_NT.aln -out_AA ${seqFTrimmed.baseName}_AA.aln -out_tested_seq_info ${seqFTrimmed.baseName}_stats.csv


    if [ -s ${seqFTrimmed.baseName}_NT.aln ]
    then
      touch ${seqFTrimmed.baseName}_expNT.aln;
      touch ${seqFTrimmed.baseName}_expAA.aln;
    else
      java -XX:MaxMetaspaceSize=${params.javaMem} -Xms250m -Xmx${params.javaMem} \
          -jar /UTILS/macse_v2.03.jar -prog exportAlignment \
          -align ${seqFTrimmed.baseName}_NT.aln -gc_def ${params.geneticCode} \
          -codonForInternalFS NNN -charForRemainingFS - \
          -out_NT ${seqFTrimmed.baseName}_expNT.aln \
          -out_AA ${seqFTrimmed.baseName}_expAA.aln \
          -keep_gap_only_sites_ON
      sed -i -e '/^[^>]/s/!/X/g' ${seqFTrimmed.baseName}_expAA.aln
    fi
      """
}

process mergeNoInsAln{
  input:
     file alignListNT     from splitEnrichAln_NT.collectFile(storeDir:"$params.resultdir", name:"${params.outPrefix}_alignAll_NT.aln")
     file alignListAA     from splitEnrichAln_AA.collectFile(storeDir:"$params.resultdir", name:"${params.outPrefix}_alignAll_AA.aln")
     file alignListNT_exp from splitEnrichAln_NTexp.collectFile(storeDir:"$params.resultdir", name:"${params.outPrefix}_alignAll_NT_exp_noFS.aln")
     file alignListAA_exp from splitEnrichAln_AAexp.collectFile(storeDir:"$params.resultdir", name:"${params.outPrefix}_alignAll_AA_exp_noFS.aln")
  output:
    file alignListNT
    file alignListAA
    file alignListNT_exp
    file alignListAA_exp
    """
    """

}

process mergeNoInsStat{
  input:
    file allStatFile from splitEnrichStat.collectFile(storeDir:"$params.resultdir", name:"${params.outPrefix}_enrich_info.csv", keepHeader:true)
  output:
    file allStatFile
    """
    """
}

process mergeTrimStat{
  input:
    file allTrimStatFile from splitTrimStat.collectFile(storeDir:"$params.resultdir", name:"${params.outPrefix}_preTrimingStat.csv", keepHeader:true)
  output:
    file allTrimStatFile
    """
    """
}

//result.view { it.trim() }
// module load bioinfo/nextflow/19.07.0.5106
// nextflow S_macse_barcode.nf --refAlign ../REF_ALIGN_MAMMAL_COI5P/refAlign_mammal_COI5P_final_mask_align_NT.aln --seqToAlign ../DATA/Mammalia_BOLD_100seq_COI-5P_2020.fasta
// nextflow S_macse_barcode.nf --refAlign ../REF_ALIGN_MAMMAL_COI5P/refAlign_mammal_COI5P_final_mask_align_NT.aln --seqToAlign ../homologous_seq_NT.fasta
