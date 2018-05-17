Original instructions are available at https://github.com/carp-te/carp-documentation in CARP.pdf.

This pipeline relies on a singularity container that must be built prior to working.
You must build the container on a computer on which you are root or request it from david.4.ray@gmail.com. 
To build the container you must have singularity installed -- https://singularity.lbl.gov -- and run 'singularity build carpUbuntu.img carpcarpTEDarUbuntuMod.def'
Once built, add the container to a local directory on your hpcc and take note of the path. 

Proceed with the following: 

In working directory:
1. Two submission scripts, part1.sh and part2.sh
Part1 will run krishna/matrix and download necessary files while doing so. 
Part2 will complete the annotation run using the output of krishna and the downloaded files.
2. Your genome in .fa format.
3. Two folders directories, 'code' and 'annotation' files.

The 'code' directory should contain 6 files and one folder:
Files:
sort-carp.py - for final sorting of the generated library
IdentifySSRs.java - https://github.com/carp-te/carp-documentation
GetProteins.java - https://github.com/carp-te/carp-documentation
GenerateAnnotatedLibrary.java - https://github.com/carp-te/carp-documentation
format_RMSK.pl - https://github.com/carp-te/carp-documentation
ClassifyConsensusSequences.java - https://github.com/carp-te/carp-documentation
Folder:
phobos-v3.3.12-linux, containing all files necessary for phobos to run. Obtained from http://www.ruhr-uni-bochum.de/ecoevo/cm/cm_phobos.htm

The 'annotationfiles' directory should contain:
1. known repeats of relevance from RepBase. Should be downloaded from RepBase prior to analysis. For example, if working with vertebrates, download all known vertebrate TEs from RepBase and save as vertebrates.fa. 
2. a file with repeats we may have identified via previous work. For example, if working with a new bat, I have a file called bat.TEs.full.11-2-16.final.fas with all of our previous TEs from bats that have not been deposited in RepBase yet.
3. a file with known retrovirues from NCBI, all_retrovirus.fasta. Got to https://www.ncbi.nlm.nih.gov/genomes/GenomesGroup.cgi?taxid=11632 and 'Retreive Sequences' in fasta format. 

Edit your part1.sh file to match:
1. the job title for your job on the cluster (line 4)
2. your genome name and a prefix for it (18 & 19)
3. your working directory (21)
4. the path to your singularity container for running carp (25)
5. the name of your known repeats files, the annotationfiles from above (30, 31, 33, 34)
6. your needs for your genome. For example, in line 92, you can use more or fewer processors by altering the thread numbers. You can increase or decrease the probability of getting lineage-specific elements by raising filtid. You can edit filtlen to retrieve smaller repeats.

Edit your part2.sh file to match:
1-5 from part1.sh
Everything else should be automatic.

Your part1.sh should generate many, many files in your chunks folder as well as a 'krishna.gff' file in your working directory. It should also download and populate your annotationfiles folder with 'uniprot_sprot.fasta' and 'GB_TE.fa'

Your part2.sh will also generate many files. The important ones are in 'finallibrary'.

To run, log in to quanah and type the following:
qsub <name of your part1.sh>
qsub -hold_jid <name the job title in part1.sh> <name of your part2.sh>
For example:
$qsub carp-rFer-part1.sh
$qsub -hold_jid carp2-p1 carp-rFer-part2.sh

part1.sh will run to completion and part2.sh will start afterward.

If you have a longer wall time than 48 hours, this isn't actually necessary but it doesn't hurt.

