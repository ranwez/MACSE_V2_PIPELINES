# MACSE pipelines

This repository provides source code for several pipelines dedicated to the alignment of nucleotide coding sequences that are based on MACSE. These pipelines are mostly bash scripts encapsulated within Singularity containers and sometimes combined into NextFlow workflows.

## Pipeline overview

### pipelines to align CDS/exons
* **alfix**: this pipeline uses MACSE and HmmCleaner to produce a high quality alignment of nucleotide (NT) coding sequences using their amino acid (AA) translations. It is well suited for datasets containing a few dozen of sequences of a few Kb.
*  **OMM_MACSE**: this pipeline also produces a codon-aware alignment thanks to MACSE, which could be filtered by HmmCleaner, but it can handle larger datasets by relying on MAFFT, MUSCLE or PRANK to scale up.

These two pipelines are described in our MACSE tutorial paper [[ranwez et al. 2020]](#ranwez_2020_tuto)

### pipelines dedicated to barcoding
* **macse_barcode** this nextflow pipeline allows to aligns hundred of thousands of barcoding sequences
* **build_ref_align** this nextflow pipeline identifies a small subset of sequences that are representative of the diversity of the barcoding input sequence dataset
* **enrich_align** this nextflow pipeline aligns barcoding sequences based on a reference alignment.
* **representative_sequences** A bash script that identifies a small subset of sequences that are representative of the diversity of the barcoding input sequence dataset and is chained with OMM_MACSE in the **build_ref_align** workflow.


These pipelines are detailed in our book chapter dedicated to MACSE and barcoding datasets [[Delscuc & Ranwez, 2020]](#delsuc_2020). While using **macse_barcode** is the easiest solution, chaining **build_ref_align** and **enrich_align** allows to check the quality of the proposed reference alignment and to manually curate it, if needed, before using it to align the barcode sequences.

We used the **macse_barcode** pipeline to align **COI**, **matK** and **rbcL** sequences for numerous taxonomic groups, all resulting alignments are available [here](https://bioweb.supagro.inra.fr/macse/index.php?menu=download_Barcoding).

## MACSE overview

MACSE: Multiple Alignment of Coding SEquences Accounting for Frameshifts and Stop Codons.

A wide range of molecular analyses relies on multiple sequence alignments (MSA). Until now the most efficient solution to align nucleotide (NT) sequences containing open reading frames was to use indirect procedures that align amino acid (AA) translation before reporting the inferred gap positions at the codon level. There are two important pitfalls with this approach. Firstly, any premature stop codon impedes using such a strategy. Secondly, each sequence is translated with the same reading frame from beginning to end, so that the presence of a single additional nucleotide leads to both aberrant translation and alignment.

MACSE [[Ranwez et al, 2011]](#Ranwez_2011) aligns coding NT sequences with respect to their AA translation while allowing NT sequences to contain multiple frameshifts and/or stop codons. MACSE is hence the first automatic solution to align protein-coding gene datasets containing non-functional sequences (pseudogenes) without disrupting the underlying codon structure. It has also proved useful in detecting undocumented frameshifts in public database sequences and in aligning next-generation sequencing reads/contigs against a reference coding sequence.

For further details about the underlying algorithm see the original publication:
MACSE: Multiple Alignment of Coding SEquences accounting for frameshifts and stop codons.
Vincent Ranwez, Sébastien Harispe, Frédéric Delsuc, Emmanuel JP Douzery
PLoS One 2011, 6(9): e22594.

More information (including documentations and tutorials) are available on the [MACSE website](https://bioweb.supagro.inra.fr/macse)


## Singularity overview

A singularity container [[Kurtzer, 2017]](#Kurtzer_2017) contains everything that is needed to execute a specific task. The person building the container has to handle dependencies and environment configuration so that the end-user do not need to bother. The file specifying the construction of the container is a simple text file called a recipe (we provide the recipe of our container as well as the containers). As our scripts/pipelines often relies on several other scripts and external tools (e.g. MAFFT) singularity container is very handy as the end user just need to install singularity and download the container without having to care for installing dependencies or setting environment variables.

A brief introduction to singularity is available [here](https://bioweb.supagro.inra.fr/macse/index.php?menu=pipelines).

## Nextflow overview

Nextflow [[Di Tommaso, 2017]](#Di_Tommaso_2017) enables scalable and reproducible scientific workflowsusing software containers allowing the adaptation of pipelines written in the most commonscripting languages.

Nextflow separates the workflow itself from the directive regarding the correct way to execute it in the environment. One key advantage of Nextflow is that, by changing slightly the “nextflow.config” file, the same workflow will be parallelized and launched to exploit the full resources of a high performance computing (HPC) cluster.

## References
<a id="Di_Tommaso_2017"></a> Di Tommaso, P., Chatzou, M., Floden, E. W., Barja, P. P., Palumbo, E., and Notredame, C.(2017). Nextflow enables reproducible computational workflows. Nature Biotechnology,35(4):316–319. [Nextflow web site](https://www.nextflow.io/)

<a id="Kurtzer_2017"></a> Kurtzer, G. M., Sochat, V., and Bauer, M. W. (2017). Singularity: Scientific containers formobility of compute. PloS One, 12(5):e0177459. [singularity web site](https://sylabs.io/)

<a id="Ranwez_2011"></a>MACSE: Multiple Alignment of Coding SEquences accounting for frameshifts and stop codons.
Vincent Ranwez, Sébastien Harispe, Frédéric Delsuc, Emmanuel JP Douzery
PLoS One 2011, 6(9): e22594. [MACSE web site](https://bioweb.supagro.inra.fr/macse/i)

<a id="ranwez_2020_tuto"></a> Aligning protein-coding nucleotide sequences with MACSE. V. Ranwez, N. Chantret, F Delsuc. To appear in Methods in Molecular Biology (2020).

<a id="delsuc_2020">Accurate alignment of (meta)barcoding datasets using MACSE. Frédéric Delsuc and Vincent Ranwez (2020). In Scornavacca, C., Delsuc, F., and Galtier, N., editors, Phylogenetics
in the Genomic Era, chapter No. 2.3, pp. 2.3:1–2.3:30. No commercial publisher | Authors open access book. The book is freely available at [https://hal.inria.fr/PGE](https://hal.inria.fr/PGE). </a>
