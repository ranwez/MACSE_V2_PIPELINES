#! usr/bin/env nextflow

params.refAlign="refAlign.fasta"
params.seqToAlign="allSeq.fasta"
params.javaMem="600m"
params.gc="2"


Channel
    .fromPath( params.seqToAlign )
    .splitFasta( by: 10, file:true)
    .set {fasta_split }

process enrichNoIns {
    input:
      file seqF from fasta_split
      file 'refAlignFile' from file(params.refAlign)
    output:
      file "${seqF.baseName}_NT.aln" into splitEnrichAln
      file "${seqF.baseName}_stats.csv" into splitEnrichStat
      //stdout result

      """
      . /etc/profile.d/modules.sh
      module load system/java/jre8
      #echo $seqF ${params.refAlign} ${params.gc}
      java -XX:MaxMetaspaceSize=${params.javaMem} -Xms250m -Xmx${params.javaMem} \
        -jar /homedir/ranwez/MACSE_BARCODE/macse_v2.03.jar -prog enrichAlignment \
          -align $refAlignFile -gc_def ${params.gc} -seq $refAlignFile -seq_lr $seqF \
          -fixed_alignment_ON -new_seq_alterable_ON -fs_lr 10 -stop_lr 10 \
          -maxFS_inSeq 2 -maxINS_inSeq 0 -maxSTOP_inSeq 1 \
          -fixed_alignment_ON -output_only_added_seq_ON\
          -out_NT ${seqF.baseName}_NT.aln -out_tested_seq_info ${seqF.baseName}_stats.csv
      """
}

process mergeNoIns{
   publishDir '/homedir/ranwez/MACSE_BARCODE/NEXTRES/', mode: 'copy', overwrite: false
   input:
     file alignList from splitEnrichAln.collect()

    """
    echo -n "" > alignAll_noIns.aln


    for alignFile in ${alignList}
    do
        cat \$alignFile >> alignAll_noIns.aln
    done


    cp alignAll_noIns.aln /homedir/ranwez/MACSE_BARCODE/TEST_MMSEQ2/
    """

}

process mergeNoInsStat{
  input:
    file allStatFile from splitEnrichStat.collectFile(storeDir:'/homedir/ranwez/MACSE_BARCODE/TEST_MMSEQ2/', name:'alignAll_noIns.csv', keepHeader:true)
  output:
    file allStatFile
    """
    """
}

//splitEnrichStat
//  .collectFile(storeDir:'/homedir/ranwez/MACSE_BARCODE/TEST_MMSEQ2/', name:'alignAll_noIns.csv', keepHeader:true)


//result.view { it.trim() }
// module load bioinfo/nextflow/19.07.0.5106
// nextflow S_macse_barcode.nf --refAlign REF_ALIGN/refAlign_final_mask_align_NT.aln --seqToAlign DATA/Mammalia_BOLD_100seq_COI-5P_2020.fasta
// nextflow S_macse_barcode.nf --refAlign REF_ALIGN/refAlign_final_mask_align_NT.aln --seqToAlign DATA/Mammalia_BOLD_100seq_COI-5P_2020.fasta
