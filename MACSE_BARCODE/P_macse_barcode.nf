#! usr/bin/env nextflow

params.refSeq="refSeq.fasta"
params.seqToAlign="allSeq.fasta"
params.geneticCode=""
params.outPrefix="Mammals_COI"
params.javaMem="2000m"

params.resultdir= ["$baseDir", "RESULTS_BARCODE_${params.outPrefix}"].join(File.separator)
resultdir = file(params.resultdir)

resultdir.with {
    mkdirs()
}

process getRepresentatives{

  publishDir "$resultdir", mode: 'copy'

  input:
    file seqF from file(params.seqToAlign)
    file refSeqFile from file(params.refSeq)
  output:
    file "${params.outPrefix}_homolog.fasta" into homologousSequences
    file "${params.outPrefix}_repSeq.fasta" into representativeSequences
    file "${params.outPrefix}_RevComSeqId.list"
    """
    /S_getRepresentativeSeqs.sh --in_refSeq $refSeqFile --in_seqFile $seqF --in_minClustSize 20 --in_geneticCode ${params.geneticCode} --out_repSeq ${params.outPrefix}_repSeq.fasta --out_homologSeq ${params.outPrefix}_homolog.fasta --out_listRevComp ${params.outPrefix}_RevComSeqId.list
    # for testing get only a small subset of sequences to align
    #head -200 ${params.outPrefix}_homolog.fasta > ${params.outPrefix}_homolog_200.fasta
    #mv ${params.outPrefix}_homolog_200.fasta ${params.outPrefix}_homolog.fasta
    """
}

process alignRepresentatives{

  publishDir "$resultdir", mode: 'copy'

  input:
    file repSeq from  representativeSequences
    file refSeqFile from file(params.refSeq)
  output:
    file "REF_ALIGN_${params.outPrefix}/${params.outPrefix}_final_align_NT.aln" into refAlignNT
    file "REF_ALIGN_${params.outPrefix}/${params.outPrefix}_final_align_AA.aln" into refAlignAA
    """
    /OMM_MACSE/S_OMM_MACSE_V10.02.sh --in_seq_file $refSeqFile --in_seq_lr_file ${repSeq} --out_dir REF_ALIGN_${params.outPrefix} --out_file_prefix ${params.outPrefix} --genetic_code_number ${params.geneticCode} --alignAA_soft MAFFT --no_prefiltering --min_percent_NT_at_ends 0 --java_mem ${params.javaMem}
    """
}


//file seqF from (homologousSequences).splitFasta( by: 10, file:true).set {fasta_split }
process trimSequences {
  input:
    file (seqF) from homologousSequences.splitFasta(by: 100)
    file refAlignFile from refAlignNT
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
      file refAlignFile from refAlignNT
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


    if [ ! -s ${seqFTrimmed.baseName}_NT.aln ]
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
