
HMMCleaner V1_8_VR2
    Di Franco, Arnaud, et al. Evaluating the usefulness of alignment filtering methods to reduce the impact of errors on evolutionary inferences. BMC Evolutionary Biology, vol. 19, no. 1, 2019. Gale Academic Onefile, Accessed 13 Oct. 2019.

    Note that this script used a modified version (V1_8_VR2) of HMMCleaner V1_8 developped by Raphael Poujol
        Vincent Ranwez modified the original perl script so that
            1. sequences and sequence names are unchanged even when they contain unusual characters
            2. all output files are saved in the current directory (rather that being spread in the directory containing the input fasta file and HMMCleaner perl script)
            3. default masking char is '-' instead of ' '

            HMMCleaner has since been re-written by Arnaud Di Franco and a more recent release of HMMCleaner is available here: https://metacpan.org/pod/HmmCleaner.pl
