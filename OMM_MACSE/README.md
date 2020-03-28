# OMM_MACSE

MACSE (Multiple Alignment of Coding SEquences Accounting for Frameshifts and Stop Codons) provides a complete toolkit dedicated to the multiple alignment of coding sequences that can be leveraged via both the command line and a Graphical User Interface (GUI). A pipeline for aligning hundreds of sequences.

## context
A wide range of molecular analyses relies on multiple sequence alignments (MSA). Until now the most efficient solution to align nucleotide (NT) sequences containing open reading frames was to use indirect procedures that align amino acid (AA) translation before reporting the inferred gap positions at the codon level. There are two important pitfalls with this approach. Firstly, any premature stop codon impedes using such a strategy. Secondly, each sequence is translated with the same reading frame from beginning to end, so that the presence of a single additional nucleotide leads to both aberrant translation and alignment.

[MACSE](https://bioweb.supagro.inra.fr/macse/) aligns coding NT sequences with respect to their AA translation while allowing NT sequences to contain multiple frameshifts and/or stop codons. MACSE is hence the first automatic solution to align protein-coding gene datasets containing non-functional sequences (pseudogenes) without disrupting the underlying codon structure. It has also proved useful in detecting undocumented frameshifts in public database sequences and in aligning next-generation sequencing reads/contigs against a reference coding sequence.

Various strategies can be built using the MACSE toolkit to handle datasets of various sizes and containing various types of sequences (contigs, pseudogenes, barcoding sequences).

## The OMM_MACSE pipeline
The OMM_MACSE pipeline was originally developed to produce the alignments of the [OrthoMaM database](http://orthomam1.mbb.univ-montp2.fr:8080/OrthoMaM_v10b6/).

To ease the alignment of coding nucleotide sequences, we provide this ready to use alignment pipeline, which include optional filtering steps. This pipeline output the (filtered) nucleotide alignment, the corresponding (filtered) amino acid ones and the detail of the filtering steps (if some filtering steps were selected). By leveraging an external amino alignment software (MAFFT, MUSCLE or PRANK) it can handle hundreds of sequences of several kb. For smaller dataset (dozen of sequences) you may consider using the AlFiX pipeline. For barcoding analyses, please see our [dedicated strategies](https://github.com/ranwez/MACSE_V2_PIPELINES/). For more details please see the [online documentation](https://bioweb.supagro.inra.fr/macse/index.php?menu=docPipeline/docPipelineHtml) and the associated papers.

Both pipelines include four optional filtering steps:
1. a prefiltering performed before sequence alignment to mask non homologous sequence fragments that is done using trimNonHomologousFragments
2. a filtering of the amino acid alignment to mask residues that seem to be misaligned. This is done using HmmCleaner at the amino acid level and reported at the codon level using reportMaskAA2NT
3. a post-processing filtering is done to further masked isolated codons and patchy sequences (if 80% of a sequence has been masked it is probably better to remove it completely). This step is performed by setting options of reportMaskAA2NT accordingly.
4. finally the extremities of the alignment are trimmed until a site with a minimal percentage of nucleotides is reached (using trimAlignment).

All these filtering steps are active by default but can be individually turned OFF and the minimal percentage of nucleotides used for the final trimming step can be adjusted. The pipeline also provide detailed traceability information concerning the filtering processes.

## Usage example
```
./OMM_MACSE_V10.02.sif --in_seq_file Magnoliophyta_RBCL_100seq_NT.fasta --out_dir ALIGN_RBCL_MAGNO --out_file_prefix magno_rbcl --genetic_code_number 11 --min_percent_NT_at_ends 0.2
```
