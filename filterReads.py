import argparse
import fileinput


parser = argparse.ArgumentParser()
parser.add_argument('-l', type=int, help='minimum length', required=True)
args = parser.parse_args()

# file is a fasta or a fastq
filetype = 'unknown'
# save read name and information
read_name = ''
read_seq = ''
# should the fastq read be skipped? 0: don't know; 1: no; 2: yes
skip = 0

for line in fileinput.input(files='-'):
    if line[0] == '>':
        # FASTA
        if filetype == 'fasta':
            # check read size and print if long enough
            if len(read_seq) >= args.l:
                print(read_name + '\n' + read_seq)
            read_seq = ''
        else:
            filetype = 'fasta'
        read_name = line.rstrip()
    elif line[0] == '@':
        # FASTQ
        if filetype == 'fastq':
            # if the read shouldn't be skipped, print
            if skip == 1:
                print(read_name + '\n' + read_seq)
                skip = 0
        else:
            filetype = 'fastq'
        read_name = line.rstrip()
    else:
        if filetype == 'fasta':
            read_seq += line.rstrip()
        elif filetype == 'fastq':
            if skip == 0:
                read_seq = line.rstrip()
                if len(read_seq) < args.l:
                    skip = 2
                else:
                    skip = 1
            elif skip == 1:
                read_seq += '\n' + line.rstrip()

# last line
if filetype == 'fasta':
    # check read size and print if long enough
    if len(read_seq) >= args.l:
        print(read_name + '\n' + read_seq)
elif filetype == 'fastq':
    # if the read shouldn't be skipped, print
    if skip == 1:
        print(read_name + '\n' + read_seq)
