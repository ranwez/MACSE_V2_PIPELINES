#! usr/bin/env nextflow

params.javaMem="2000m"
params.minClustSize="10"
params.maxRepresentativeSeqs="100"

help=false

params.resultdir= ["$baseDir", "RESULTS_BARCODE_${params.outPrefix}"].join(File.separator)
resultdir = file(params.resultdir)

resultdir.with {
    mkdirs()
}

if(!params.refSeq) {
    println """ please specify the reference sequences using --refSeq"""
    help=true;
}

if(!params.seqToAlign) {
    println """ please specify the barcoding sequences to be aligned using --seqToAlign"""
    help=true;
}

if(!params.geneticCode) {
    println """ please specify the genetic code number to be used to translate your nucleotide sequences using --geneticCode"""
    help=true;
}

if(!params.outPrefix) {
    println """ please specify the prefix of the output file/folders that will contain the pipeline results using --outPrefix"""
    help=true;
}

if( help == true)
{
  println """\

    usage: nextflow P_macse_barcode.nf --refSeq ref_seq_NT.fasta --seqToAlign barcding_seqs_NT.fasta --geneticCode genetic_code_number --outPrefix PREFIX [--javaMem memoryToAllocate] [--minClustSize 10][--maxRepresentativeSeqs 100]
    usage example 1: nextflow P_macse_barcode.nf  --refSeq Homo_sapiens_NC_012920_COI_ref.fasta --seqToAlign Mammalia_BOLD_121180seq_COI.fasta --outPrefix Mammals_COI --geneticCode 2
    usage example 2: nextflow P_macse_barcode.nf  --refSeq Homo_sapiens_NC_012920_COI_ref.fasta --seqToAlign Mammalia_BOLD_121180seq_COI.fasta --outPrefix Mammals_COI --geneticCode 2 --javaMem 4000m --minClustSize 10 --maxRepresentativeSeqs 100

    For more details please see our book chapter, the MACSE website (https://bioweb.supagro.inra.fr/) or our github repository (https://github.com/ranwez/MACSE_V2_PIPELINES/tree/master/MACSE_BARCODE).

This MACSE_BARCODE pipeline consists of three steps:
    1. identifying a small subset of a few hundred sequences that best represent the input barcoding dataset diversity
    2. aligning these representative sequences, together with the reference sequence, to build a reference alignment
    3. using this reference alignment to align the input barcode sequences that are homologous to the reference sequence.

If you find this pipeline useful please cite this pipeline as well as the tools it relies on:
    - (The barcoding pipeline) Frédéric Delsuc, Vincent Ranwez. Accurate alignment of (meta)barcoding datasets using MACSE. Scornavacca, Celine; Delsuc, Frédéric; Galtier, Nicolas. Phylogenetics in the Genomic Era, No commercial publisher | Authors open access book, pp.2.3:1--2.3:31, 2020. ⟨hal-02539955⟩ (https://hal.inria.fr/PGE)
    - (MACSE V2) Vincent Ranwez, Emmanuel J P Douzery, Cédric Cambon, Nathalie Chantret, Frédéric Delsuc, MACSE v2: Toolkit for the Alignment of Coding Sequences Accounting for Frameshifts and Stop Codons, Molecular Biology and Evolution, Volume 35, Issue 10, October 2018, Pages 2582–2584, https://doi.org/10.1093/molbev/msy159
    - (MAFFT) Katoh K., Standley D.M. (2013). MAFFT multiple sequence alignment software version 7: improvements in performance and usability. Molecular biology and evolution, 30(4), 772-780. Edgar R.C. (2004).
    - (HMMCleaner) Di Franco, Arnaud, et al. Evaluating the usefulness of alignment filtering methods to reduce the impact of errors on evolutionary inferences. BMC Evolutionary Biology, vol. 19, no. 1, 2019. Gale Academic Onefile, Accessed 13 Oct. 2019.
    - (MMSEQ2)   Steinegger M and Soeding J. Clustering huge protein sequence sets in linear time. Nature Communications, doi: 10.1038/s41467-018-04964-5 (2018).
    - (nextflow) P. Di Tommaso, et al. Nextflow enables reproducible computational workflows. Nature Biotechnology 35, 316–319 (2017) doi:10.1038/nbt.3820
    - (singularity) Kurtzer GM, Sochat V, Bauer MW (2017) Singularity: Scientific containers for mobility of compute. PLoS ONE 12(5): e0177459. https://doi.org/10.1371/journal.pone.0177459
    - (SEQTK) https://github.com/lh3/seqtk
    """
    exit 1
}
else{
  println """\

         MACSE barcode pipeline runnning ...
         ===================================
         refSeq:                ${params.refSeq}
         seqToAlign:            ${params.seqToAlign}
         outPrefix:             ${params.outPrefix}
         geneticCode:           ${params.geneticCode}
         javaMem:               ${params.javaMem}
         minClustSize:          ${params.minClustSize}
         maxRepresentativeSeqs: ${params.maxRepresentativeSeqs}

         """
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
    /S_getRepresentativeSeqs.sh --in_refSeq $refSeqFile --in_seqFile $seqF --in_minClustSize ${params.minClustSize} --in_maxRepresentativeSeqs ${params.maxRepresentativeSeqs} --in_geneticCode ${params.geneticCode} --out_repSeq ${params.outPrefix}_repSeq.fasta --out_homologSeq ${params.outPrefix}_homolog.fasta --out_listRevComp ${params.outPrefix}_RevComSeqId.list
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
