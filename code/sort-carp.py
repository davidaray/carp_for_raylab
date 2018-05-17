from Bio import SeqIO
from sys import argv

script, IN, PREFIX = argv

INPUT = IN
VERIFIED = open(PREFIX + '_annotated.fa', 'w')
UNCLASS = open(PREFIX + '_unclassified.fa', 'w')
PARTIAL = open(PREFIX + '_partial.fa', 'w')
CHIMERIC = open(PREFIX + '_chimeric.fa', 'w')

CHIMERICCOUNT = 0
PARTIALCOUNT = 0
UNCLASSCOUNT = 0
VERIFIEDCOUNT = 0

with open(INPUT, 'r') as INFILE:
	for RECORD in SeqIO.parse(INFILE, 'fasta'):
		if 'Chimeric' in RECORD.description:
			CHIMERICCOUNT = CHIMERICCOUNT + 1
			SeqIO.write(RECORD, CHIMERIC, 'fasta')
		elif 'PartialAnnotation' in RECORD.description:
			PARTIALCOUNT = PARTIALCOUNT + 1
			SeqIO.write(RECORD, PARTIAL, 'fasta')
		elif 'Unclassified' in RECORD.description:
			UNCLASSCOUNT = UNCLASSCOUNT + 1
			SeqIO.write(RECORD, UNCLASS, 'fasta')
		else: 
			VERIFIEDCOUNT = VERIFIEDCOUNT + 1
			SeqIO.write(RECORD, VERIFIED, 'fasta')

print('Verified = ' + str(VERIFIEDCOUNT) + '.')
print('Unclassified = ' + str(UNCLASSCOUNT) + '.')
print('Chimeric = ' + str(CHIMERICCOUNT) + '.')
print('Partial = ' + str(PARTIALCOUNT) + '.')

VERIFIED.close()
UNCLASS.close()
CHIMERIC.close()
PARTIAL.close()

