# MACSE pipelines

This repository provides source code for several pipelines dedicated to the alignment of nucleotide coding sequences that are based on MACSE. This pipelines are mostly bash scripts encapsulated within singularity containers and sometimes combined in nextflow workflows.

## MACSE overview

MACSE: Multiple Alignment of Coding SEquences Accounting for Frameshifts and Stop Codons.

A wide range of molecular analyses relies on multiple sequence alignments (MSA). Until now the most efficient solution to align nucleotide (NT) sequences containing open reading frames was to use indirect procedures that align amino acid (AA) translation before reporting the inferred gap positions at the codon level. There are two important pitfalls with this approach. Firstly, any premature stop codon impedes using such a strategy. Secondly, each sequence is translated with the same reading frame from beginning to end, so that the presence of a single additional nucleotide leads to both aberrant translation and alignment.

[[MACSE]](#Ranwez_2011) aligns coding NT sequences with respect to their AA translation while allowing NT sequences to contain multiple frameshifts and/or stop codons. MACSE is hence the first automatic solution to align protein-coding gene datasets containing non-functional sequences (pseudogenes) without disrupting the underlying codon structure. It has also proved useful in detecting undocumented frameshifts in public database sequences and in aligning next-generation sequencing reads/contigs against a reference coding sequence.

For further details about the underlying algorithm see the original publication:
MACSE: Multiple Alignment of Coding SEquences accounting for frameshifts and stop codons.
Vincent Ranwez, Sébastien Harispe, Frédéric Delsuc, Emmanuel JP Douzery
PLoS One 2011, 6(9): e22594.

More information (including documentations and tutorials) are available on the [MACSE website](https://bioweb.supagro.inra.fr/macse)


## Singularity overview

A singularity container[[Kurtzer_2017]](#Kurtzer_2017) contains everything that is needed to execute a specific task. The person building the container has to handle dependencies and environment configuration so that the end-user do not need to bother. The file specifying the construction of the container is a simple text file called a recipe (we provide the recipe of our container as well as the containers). As our scripts/pipelines often relies on several other scripts and external tools (e.g. MAFFT) singularity container is very handy as the end user just need to install singularity and download the container without having to care for installing dependencies or setting environment variables.

A brief introduction to singularity is available [here](https://bioweb.supagro.inra.fr/macse/index.php?menu=pipelines).

## Nextflow overview

Nextflow [[Di Tommaso, 2017]](#Di_Tommaso_2017) enables scalable and reproducible scientific workflowsusing software containers allowing the adaptation of pipelines written in the most commonscripting languages.

Nextflow separates the workflow itself from the directive regarding the correct way to execute it in the environment. One key advantage of Nextflow is that, by changing slightly the “nextflow.config” file, the same workflow will be parallelized and launched to exploit the full resources of a high performance computing (HPC) cluster.

## References
<a id="Di_Tommaso_2017"></a> Di Tommaso, P., Chatzou, M., Floden, E. W., Barja, P. P., Palumbo, E., and Notredame, C.(2017). Nextflow enables reproducible computational workflows.Nature Biotechnology,35(4):316–319. [Nextflow web site](https://www.nextflow.io/)

<a id="Kurtzer_2017"></a> Kurtzer, G. M., Sochat, V., and Bauer, M. W. (2017). Singularity: Scientific containers formobility of compute.PloS One, 12(5):e0177459. [singularity web site]((https://sylabs.io/))

<a id="Ranwez_2011"></a>MACSE: Multiple Alignment of Coding SEquences accounting for frameshifts and stop codons.
Vincent Ranwez, Sébastien Harispe, Frédéric Delsuc, Emmanuel JP Douzery
PLoS One 2011, 6(9): e22594.
