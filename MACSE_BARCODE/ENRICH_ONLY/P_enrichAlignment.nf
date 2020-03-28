#! usr/bin/env nextflow

params.refAlign="Toto_refAlign.fasta"
params.seqToAlign="Toto_allSeq.fasta"
params.javaMem="2000m"
params.resDIR="MACSE_BARCODE_RESULTS"
params.geneticCode="2"


Channel
    .fromPath( params.seqToAlign )
    .splitFasta( by: 10, file:true)
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
        -align $refAlignFile -gc_def ${params.gc} -seq $refAlignFile -seq_lr $seqF \
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
      file "${seqFTrimmed.baseName}.aln" into splitEnrichAln
      file "${seqFTrimmed.baseName}_stats.csv" into splitEnrichStat

      """
      java -XX:MaxMetaspaceSize=${params.javaMem} -Xms250m -Xmx${params.javaMem} \
          -jar /UTILS/macse_v2.03.jar -prog enrichAlignment \
          -align $refAlignFile -gc_def ${params.gc} -seq $refAlignFile -seq_lr $seqFTrimmed \
          -fs_lr 10 -stop_lr 10 -gap_ext_term 0.1 -gap_op_term 0.7\
          -fixed_alignment_ON -new_seq_alterable_ON \
          -maxFS_inSeq 2 -maxINS_inSeq 0 -maxSTOP_inSeq 1 \
          -fixed_alignment_ON -output_only_added_seq_ON\
          -out_NT ${seqFTrimmed.baseName}.aln -out_tested_seq_info ${seqFTrimmed.baseName}_stats.csv
      """
}

process mergeNoInsAln{
  input:
     file alignList from splitEnrichAln.collectFile(storeDir:"$workflow.launchDir/$params.resDIR", name:'alignAll_noIns.aln')
  output:
    file alignList
    """
    """

}

process mergeNoInsStat{
  input:
    file allStatFile from splitEnrichStat.collectFile(storeDir:"$workflow.launchDir/$params.resDIR", name:'alignAll_noIns.csv', keepHeader:true)
  output:
    file allStatFile
    """
    """
}

//process mergeTrimStat{
//  input:
//    file allTrimStatFile from splitTrimStat.collectFile(storeDir:"$workflow.launchDir/$params.resDIR", name:'alignAll_preTrimingStat.csv', keepHeader:true)
//  output:
//    file allTrimStatFile
//    """
//    """
//}

//result.view { it.trim() }
// module load bioinfo/nextflow/19.07.0.5106
// nextflow S_macse_barcode.nf --refAlign ../REF_ALIGN_MAMMAL_COI5P/refAlign_mammal_COI5P_final_mask_align_NT.aln --seqToAlign ../DATA/Mammalia_BOLD_100seq_COI-5P_2020.fasta
// nextflow S_macse_barcode.nf --refAlign ../REF_ALIGN_MAMMAL_COI5P/refAlign_mammal_COI5P_final_mask_align_NT.aln --seqToAlign ../homologous_seq_NT.fasta
