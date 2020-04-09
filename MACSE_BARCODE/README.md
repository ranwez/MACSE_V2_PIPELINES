# MACSE_barcoding pipeline
 are representative of the diversity of the barcoding input sequence dataset.

## context
Metabarcoding analysis often requires to handle thousands of sequences. Such datasets are not directly tractable with the alignSequence subprogram of MACSE, but they can be handled by sequentially adding your newly obtained sequences to a reference alignment containing sequences of related taxa for your targeted locus (COX1, matK, rbcL, etc...). We successfully used this approach in the Moorea project, [M. Leray et al 2013](https://frontiersinzoology.biomedcentral.com/articles/10.1186/1742-9994-10-34).

The proposed approach implemented in the MACSE_BARCODE pipeline consists of three steps (Delsuc and Ranwez 2020, to appear):
1. identifying a small subset of a few hundred sequences that best represent the barcoding dataset diversity
2. aligning these representative sequences to build a reference alignment
3. using this reference alignment to align the thousands of remaining barcode sequences.

We developed two nextflow pipelines to automatizes these steps. The first one build the reference alignment (step 1 and 2) while the second one align the barcoding sequences using this reference alignment (step 3).
The only things needed to run them is to have a recent release of singularity installed on your machine and nextflow.

## installation

Singularity and nextflow are installed on most HPC facilities you could hence probably skipped these two first steps.

### Singularity
A recent version of singularity (>3.4) is needed the procedure to install singularity is [described here](https://sylabs.io/guides/3.5/user-guide/quick_start.html#quick-installation-steps).

### nextflow
Nextflow is much easier to install and it can be installed as a regular user (no need to be root) using one of the following command:

``` bash
curl -s https://get.nextflow.io | bash
```
or
``` bash
wget -qO- https://get.nextflow.io | bash
```

### getting the needed singularity containers
The container can be built using the recipes provided on this github site or downloaded as regular file from the official [sylabs repository](https://sylabs.io/docs/); but the most convenient to get them is to download them from the sylabs repository directly to your HPC using the following instructions:   
``` bash
singularity pull --arch amd64 library://vranwez/default/representative_seqs:v01
singularity pull --arch amd64 library://vranwez/default/omm_macse:v10.02
```

### getting the needed nextflow pipelines
The two nexflow pipelines are small text files available here [P_buildRefAlignment.nf](https://raw.githubusercontent.com/ranwez/MACSE_V2_PIPELINES/master/MACSE_BARCODE/BUILD_REF_ALIGN/P_buildRefAlignment.nf) [P_enrichAlignment.nf](https://raw.githubusercontent.com/ranwez/MACSE_V2_PIPELINES/master/MACSE_BARCODE/ENRICH_ALIGN/P_enrichAlignment.nf).

### adjusting the nextflow config file
Nextflow separates the workflow itself from the directive regarding the correct way to execute it in the environment. One key advantage of Nextflow is that by changing slightly the “nextflow.config” file, the same workflow will be parallelized and launched to exploit the full resources of a high performance computing (HPC) cluster. The key parameters to change in this configuration file are: (1) the “executor”, which could be “local” to run on a standard machine, “sge” or “slurm” to be launched on a HPC cluster or even run on the cloud, and (2) the “queue”, which specifies on which queue the job should be run if a grid based executor is used.
The last thing to do is to adapt one of our model nextflow.config file to your HPC environment.

## running the workflows
You can download the example datasets used in (Delsuc and Ranwez 2020) as well as their expected output on the [dedicated MACSE page](https://bioweb.supagro.inra.fr/macse/index.php?menu=downloadTuto)
Running the two workflow for the COI mammalian dataset can thus be done using the following two commands
``` bash
./nextflow P_buildRefAlignment.nf --refSeq Mammalia/Homo_sapiens_NC_012920_COI_ref.fasta --seqToAlign Mammalia/Mammalia_BOLD_121180seq_COI.fasta --geneticCode 2 --outPrefix Mammalia_COI
```

``` bash
#warning this take about 140h of CPU
./nextflow P_enrichAlignment.nf --refAlign RESULTS_REFA_Mammalia_COI/REF_ALIGN_Mammalia_COI/Mammalia_COI_final_align_NT.aln --seqToAlign RESULTS_REFA_Mammalia_COI/Mammalia_COI_homolog.fasta --geneticCode 2 --outPrefix Mammalia_COI
```
On our grid cluster, the identification of representative sequences and the generation of the reference alignment with P_buildRefAlignment took only 8 minutes. The obtention of the final alignment with P_enrichAlignment required about 134 hours of CPU time but the final result was produced in just 1 hour and 38 minutes thanks to the parallelization used in the pipeline. If you just want to test that the pipelines are working correctly it is hence probably better to extract just a subset of the homologous sequences to align using the two following commands:

``` bash
head -1000 RESULTS_REFA_Mammalia_COI/Mammalia_COI_homolog.fasta > Few_Mammalia_COI_homolog.fasta
./nextflow P_enrichAlignment.nf --refAlign RESULTS_REFA_Mammalia_COI/REF_ALIGN_Mammalia_COI/Mammalia_COI_final_align_NT.aln --seqToAlign Few_Mammalia_COI_homolog.fasta --geneticCode 2 --outPrefix Mammalia_COI
```
