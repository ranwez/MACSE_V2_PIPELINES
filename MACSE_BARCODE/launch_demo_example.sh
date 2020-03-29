# build reference alignments
./nextflow P_buildRefAlignment.nf --refSeq Mammalia/Homo_sapiens_NC_012920_COI-5P_ref.fasta --seqToAlign Mammalia/Mammalia_BOLD_117156seq_COI-5P_2020.fasta --geneticCode 2 --outPrefix Mammalia_COI
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
