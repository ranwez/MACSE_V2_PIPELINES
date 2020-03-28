# Representative Sequences
This pipeline identifies a small subset of sequences that are representative of the diversity of the barcoding input sequence dataset.

## context
Metabarcoding analysis often requires to handle thousands of sequences. Such datasets are not directly tractable with the alignSequence subprogram of MACSE, but they can be handled by sequentially adding your newly obtained sequences to a reference alignment containing sequences of related taxa for your targeted locus (COX1, matK, rbcL, etc...). We successfully used this approach in the Moorea project, [M. Leray et al 2013](https://frontiersinzoology.biomedcentral.com/articles/10.1186/1742-9994-10-34).

The first step for such a strategy is to assemble a reliable reference alignment if you don't have one. To this aim we suggest the following strategy:
1. collect a large datasets of sequence corresponding to your target marker and taxonomic level of interest  (e.g. by using your own full set of sequences or by querying a public database such as  [BOLD](http://v3.boldsystems.org/))
2. identify from this dataset a small subset of sequences that are representative of the observe diversity of this dataset
3. align these sequences (e.g. using our [omm_macse pipeline](https://github.com/ranwez/MACSE_V2_PIPELINES/tree/master/OMM_MACSE) )

As sequences may be in reverse complement or wrongly annotated, it is convenient to use a sequence carefully checked that is in the correct reading frame to guide the process.

## The "representative sequences" pipeline
This pipeline takes as input a sequence of reference and a set of input sequences and conduct the following steps using [MMSEQS2](https://github.com/soedinglab/MMseqs2), [MACSE](https://bioweb.supagro.inra.fr/macse/) and [seqtk] (https://github.com/lh3/seqtk)
1. each input sequence is compared (in the six reading frame) to the amino acid translation of the reference sequences
2. a set of sequences homologous to the reference one is identified, and they are reverse complemented when neeeded
3. a clustering of the amino acid sequences homologous to the reference is conducted and a representative sequence is kept for each large ClusterRes

This pipeline is encapsulated in a singularity container.

## Usage example
A basic usage is as following:
```
./representative_seqs_v01.01.sif --in_refSeq one_reference_seq.fasta --in_seqFile barcoding_sequences_to_align.fasta --in_geneticCode 11
```
For more details about the pipeline option simply launch it without any parametes:
```
./representative_seqs_v01.01.sif
```
