#! usr/bin/env nextflow


params.javaMem="2000m"
params.minClustSize="10"
params.maxRepresentativeSeqs="100"

help=false


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

    usage: nextflow P_buildRefAlignment.nf --refSeq ref_seq_NT.fasta --seqToAlign barcding_seqs_NT.fasta --geneticCode genetic_code_number --outPrefix PREFIX [--javaMem memoryToAllocate] [--minClustSize 10][--maxRepresentativeSeqs 100]
    usage example 1: nextflow P_buildRefAlignment.nf  --refSeq Homo_sapiens_NC_012920_COI_ref.fasta --seqToAlign Mammalia_BOLD_121180seq_COI.fasta --outPrefix Mammals_COI --geneticCode 2
    usage example 2: nextflow P_buildRefAlignment.nf  --refSeq Homo_sapiens_NC_012920_COI_ref.fasta --seqToAlign Mammalia_BOLD_121180seq_COI.fasta --outPrefix Mammals_COI --geneticCode 2 --javaMem 4000m --minClustSize 10 --maxRepresentativeSeqs 100

    For more details please see our book chapter, the MACSE website (https://bioweb.supagro.inra.fr/) or our github repository (https://github.com/ranwez/MACSE_V2_PIPELINES/tree/master/MACSE_BARCODE).

This MACSE_BARCODE pipeline consists of three steps:
    1. identifying a small subset of a few hundred sequences that best represent the input barcoding dataset diversity
    2. aligning these representative sequences, together with the reference sequence, to build a reference alignment
    3. using this reference alignment to align the input barcode sequences that are homologous to the reference sequence.
This pipeline chain the two first steps and gived you the opportunity to manually correct the reference alignment before launching the last step.

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

         MACSE buildRefAlignment pipeline runnning ...
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


params.resultdir= ["$baseDir", "RESULTS_REFA_${params.outPrefix}"].join(File.separator)
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
    /S_getRepresentativeSeqs.sh --in_refSeq $refSeqFile --in_seqFile $seqF --in_minClustSize ${params.minClustSize} --in_maxRepresentativeSeqs ${params.maxRepresentativeSeqs} --in_geneticCode ${params.geneticCode} --out_repSeq ${params.outPrefix}_repSeq.fasta --out_homologSeq ${params.outPrefix}_homolog.fasta --out_listRevComp ${params.outPrefix}_RevComSeqId.list
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
