The OMM_MACSE pipeline is made of several steps (some of which are optional):
step 1: prefiltering of non homologous sequence fragments by MACSE
step 2: frameshift detection and amino acid translation accounting for these frameshifts using MACSE
step 3: alignment of these corrected amino acid sequences using MAFFT, MUSCLE or PRANK then MACSE is used to derive the corresponding nucleotide alignment
step 4: filtering of this alignment using HMMCleaner
step 5: finally MACSE is used to post-filter this AA alignment and to derive the corresponding nucleotide alignment
step 6: export of these two alignments to remove frameshifts (!) and stop codons/symbols (*) that are not standard

This folder contains this readme file plus the eight following files (assuming you launch the pipeline with --out_prefix LOC_48720):

The nucleotide and amino acid alignments obtained at the end of step 3
1.	LOC_48720_final_unmask_align_NT.aln
2.	LOC_48720_final_unmask_align_AA.aln

The nucleotide and amino acid alignments obtained at the end of step 5
3.	LOC_48720_final_mask_align_NT.aln
4.	LOC_48720_final_mask_align_AA.aln

Three files provide traceability and statistics regarding the filtering/masking process:

5.	LOC_48720_maskFull_detail.fasta
In this FASTA unmasked nucleotides are in capital letters while masked ones are in lower case.

6.	Two tabular files summarize the impact of the filtering process on each sequence after step 1 (mask_homolog_stat) and step 5 (maskFull_stat)
LOC_48720_maskHomolog_stat.csv
LOC_48720_maskFull_stat.csv

    seqName: the sequence name
    initialSeqLength: the initial sequence length (before filtering)
    nbKeep: the number of nucleotides/characters that remains after filtering
    nbTrim: the number of nucleotides/characters that have been removed by the filtering process (including non informative nucleotides 'N')
    nbInformativeTrim: the number of informative nucleotides/characters that have been removed by the filtering process (excluding non informative nucleotides 'N')
    percentHomologExcludingExtremities: once extremities have been filtered which fraction of the remaining part of the sequence has also been filtered
    percentHomologIncludingExtremities: which fraction of the sequence has also been filtered
    keptSequences: is the sequence kept and included in the output fasta file

The nucleotide and amino acid alignments obtained at the end of step 6. They are standard fasta files but you lose the information regarding detected frameshifts and stop codons, pseudogenes will hence look as almost normal sequences at this step. We therefore strongly advice to consider the final_mask_align_AA.aln and to remove such sequences.

7.	LOC_48720_final_align_NT.aln
8.	LOC_48720_final_align_AA.aln
