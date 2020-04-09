# MACSE_barcoding pipeline
 are representative of the diversity of the barcoding input sequence dataset.

## context
Metabarcoding analysis often requires to handle thousands of sequences. Such datasets are not directly tractable with the alignSequence subprogram of MACSE, but they can be handled by sequentially adding your newly obtained sequences to a reference alignment containing sequences of related taxa for your targeted locus (COX1, matK, rbcL, etc...). We successfully used this approach in the Moorea project, [M. Leray et al 2013](https://frontiersinzoology.biomedcentral.com/articles/10.1186/1742-9994-10-34).

The proposed approach implemented in the MACSE_BARCODE pipeline consists of three steps:
1. identifying a small subset of a few hundred sequences that best represent the barcoding dataset diversity
2. aligning these representative sequences to build a reference alignment
3. using this reference alignment to align the thousands of remaining barcode sequences.

We developed two nextflow pipelines to automatizes these steps. The only things needed to run them is to have a recent release of singularity installed on your machine and nextflow.

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

### getting the needed containers
singularity pull --arch amd64 library://vranwez/default/representative_seqs:v01
singularity pull --arch amd64 library://vranwez/default/omm_macse:v10.02

 They rely on two singularity containers that coud be simply download from
