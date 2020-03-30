#! usr/bin/env nextflow

params.refSeq="refSeq.fasta"
params.seqToAlign="allSeq.fasta"
params.geneticCode=""
params.outPrefix="Mammals_COI"
params.javaMem="2000m"

params.resultdir= ["$baseDir", "RESULTS_REFA_${params.outPrefix}"].join(File.separator)
resultdir = file(params.resultdir)

resultdir.with {
    mkdirs()
}

process getRepresentatives{

  publishDir "$resultdir"

  input:
    file seqF from file(params.seqToAlign)
    file refSeqFile from file(params.refSeq)
  output:
    file "${params.outPrefix}_homolog.fasta" into homologousSequences
    file "${params.outPrefix}_repSeq.fasta" into representativeSequences
    file "${params.outPrefix}_RevComSeqId.list"
    """
    /S_getRepresentativeSeqs.sh --in_refSeq $refSeqFile --in_seqFile $seqF --in_minClustSize 10 --in_geneticCode ${params.geneticCode} --out_repSeq ${params.outPrefix}_repSeq.fasta --out_homologSeq ${params.outPrefix}_homolog.fasta --out_listRevComp ${params.outPrefix}_RevComSeqId.list
    """
}

process alignRepresentatives{

  publishDir "$resultdir"

  input:
    file repSeq from  representativeSequences
    file refSeqFile from file(params.refSeq)
  output:
    file "REF_ALIGN_${params.outPrefix}/${params.outPrefix}_final_align_NT.aln" into refAlignNT
    file "REF_ALIGN_${params.outPrefix}/${params.outPrefix}_final_align_AA.aln" into refAlignAA
    """
    # /OMM_MACSE/S_OMM_MACSE_V10.02.sh --in_seq_file $refSeqFile --in_seq_lr_file ${repSeq} --out_dir REF_ALIGN_${params.outPrefix} --out_file_prefix ${params.outPrefix} --genetic_code_number ${params.geneticCode} --alignAA_soft MAFFT --min_percent_NT_at_ends 0.2 --java_mem ${params.javaMem}
    /OMM_MACSE/S_OMM_MACSE_V10.02.sh --in_seq_file $refSeqFile --in_seq_lr_file ${repSeq} --out_dir REF_ALIGN_${params.outPrefix} --out_file_prefix ${params.outPrefix} --genetic_code_number ${params.geneticCode} --alignAA_soft MAFFT --min_percent_NT_at_ends 0 --java_mem ${params.javaMem}
    """
}
