import sys

def insert_gaps(aligned_file, unaligned_file):
    unaligned_seqs = {}
    with open(unaligned_file, "r") as unaligned:
        seq_name = ""
        seq = ""
        for line in unaligned:
            if line.startswith(">"):
                if seq_name:
                    unaligned_seqs[seq_name] = seq
                seq_name = line.strip()
                seq = ""
            else:
                seq += line.strip()
        if seq_name:
            unaligned_seqs[seq_name] = seq
    
    with open(aligned_file, "r") as aligned:
        seq_name = ""
        for line in aligned:
            if line.startswith(">"):
                seq_name = line.strip()
                print(line.strip())
            else:
                aligned_seq = line.strip()
                unaligned_seq = unaligned_seqs.get(seq_name, "")
                i = 0
                res = []
                for char in aligned_seq:
                    if char == "-" or char == "!":
                        res.append(char)
                    else:
                        res.append(unaligned_seq[i])
                        i += 1
                print("".join(res))

if len(sys.argv) != 3:
    print("Usage: python insert_gaps.py input_aligned.fasta input_nonaligned.fasta")
    sys.exit(1)

aligned_file = sys.argv[1]
unaligned_file = sys.argv[2]

insert_gaps(aligned_file, unaligned_file)

