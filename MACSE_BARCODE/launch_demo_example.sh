
# build reference alignments lancé avec --in_minClustSize 10
#./nextflow P_buildRefAlignment.nf --refSeq Mammalia/Homo_sapiens_NC_012920_COI-5P_ref.fasta --seqToAlign Mammalia/Mammalia_BOLD_117156seq_COI-5P_2020.fasta --geneticCode 2 --outPrefix Mammalia_COI
./nextflow P_buildRefAlignment.nf --refSeq Mammalia/Homo_sapiens_NC_012920_COI_ref.fasta --seqToAlign Mammalia/Mammalia_BOLD_121180seq_COI.fasta --geneticCode 2 --outPrefix Mammalia_COI
./nextflow P_buildRefAlignment.nf --refSeq Magnoliophyta/Magnolia_officinalis_rbcL_ref.fasta --seqToAlign Magnoliophyta//Magnoliophyta_BOLD_rbcL_121989seqs.fasta --geneticCode 11 --outPrefix Magnoliophyta_RBCL
./nextflow P_buildRefAlignment.nf --refSeq Magnoliophyta/Magnolia_officinalis_NC_020316.1_matK_ref.fasta --seqToAlign Magnoliophyta/Magnoliophyta_BOLD_matK_107413seqs.fasta --geneticCode 11 --outPrefix Magnoliophyta_MATK
./nextflow P_buildRefAlignment.nf --refSeq Pinophyta/Pinus_sylvestris_NC_035069.1_matK_ref.fasta --seqToAlign Pinophyta/Pinophyta_BOLD_matK_2102seqs.fasta --geneticCode 11 --outPrefix Pinophyta_MATK
./nextflow P_buildRefAlignment.nf --refSeq Formicidae/Solenopsis_geminata_NC_014669.1_COI_Full_ref.fasta --seqToAlign Formicidae/Formicidae_BOLD_121954seq_COI.fasta --geneticCode 5 --outPrefix Formicidae_COI


# align barcoding sequences using reference alignment
./nextflow P_enrichAlignment.nf --refAlign RESULTS_REFA_Mammalia_COI/REF_ALIGN_Mammalia_COI/Mammalia_COI_final_align_NT.aln --seqToAlign RESULTS_REFA_Mammalia_COI/Mammalia_COI_homolog.fasta --geneticCode 2 --outPrefix Mammalia_COI
./nextflow P_enrichAlignment.nf --refAlign RESULTS_REFA_Magnoliophyta_RBCL/REF_ALIGN_Magnoliophyta_RBCL/Magnoliophyta_RBCL_final_align_NT.aln --seqToAlign RESULTS_REFA_Magnoliophyta_RBCL/Magnoliophyta_RBCL_homolog.fasta --geneticCode 11 --outPrefix Magnoliophyta_RBCL
./nextflow P_enrichAlignment.nf --refAlign RESULTS_REFA_Magnoliophyta_MATK/REF_ALIGN_Magnoliophyta_MATK/Magnoliophyta_MATK_final_align_NT.aln --seqToAlign RESULTS_REFA_Magnoliophyta_MATK/Magnoliophyta_MATK_homolog.fasta --geneticCode 11 --outPrefix Magnoliophyta_MATK
./nextflow P_enrichAlignment.nf --refAlign RESULTS_REFA_Pinophyta_MATK/REF_ALIGN_Pinophyta_MATK/Pinophyta_MATK_final_align_NT.aln --seqToAlign RESULTS_REFA_Pinophyta_MATK/Pinophyta_MATK_homolog.fasta --geneticCode 11 --outPrefix Pinophyta_MATK
./nextflow P_enrichAlignment.nf --refAlign RESULTS_REFA_Formicidae_COI/REF_ALIGN_Formicidae_COI/Formicidae_COI_final_align_NT.aln --seqToAlign RESULTS_REFA_Formicidae_COI/Formicidae_COI_homolog.fasta --geneticCode 5 --outPrefix Formicidae_COI

#relance magno MATK avec --in_minClustSize 10 --in_maxRepresentativeSeqs 150
# collect RESULTS
cp RESULTS_REFA_*/REF_ALIGN_*/*_final_align_*.aln REFERENCE_ALIGNMENTS/
cp RESULTS_REFA_*/*RevComSeqId.list REFERENCE_ALIGNMENTS/
cp RESULTS_ENRICH_*/*_alignAll_??.aln ../BARCODE_ALIGNMENTS/
cp RESULTS_ENRICH_*/*enrich*.csv ../BARCODE_ALIGNMENTS/

# Temps de calculus indicatifs pour COI Mammalia

Completed at: 08-avr.-2020 13:29:46
Duration    : 11m 16s
CPU hours   : 0.2
Succeeded   : 2

Completed at: 08-avr.-2020 15:10:35
Duration    : 1h 38m 49s
CPU hours   : 135.1
Succeeded   : 2'355


Completed at: 31-mars-2020 11:19:58
Duration    : 7m 21s
CPU hours   : 0.1
Succeeded   : 2

Completed at: 31-mars-2020 14:35:56
Duration    : 3h 6m 53s
CPU hours   : 156.4
Succeeded   : 2'345

et pour Pinophyta
Completed at: 31-mars-2020 11:16:40
Duration    : 3m 21s
CPU hours   : (a few seconds)
Succeeded   : 2


Completed at: 31-mars-2020 11:38:42
Duration    : 18m 56s
CPU hours   : 3.1
Succeeded   : 47
