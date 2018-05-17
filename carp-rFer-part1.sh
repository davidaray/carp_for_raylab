#$ -V
#$ -cwd
#$ -S /bin/bash
#$ -N carp2-p1
#$ -o $JOB_NAME.o$JOB_ID
#$ -e $JOB_NAME.e$JOB_ID
#$ -q omni
#$ -pe sm 36
#$ -P quanah

##Details for this process are found at the carp-te documentation on github
##github.com/carp-te/carp-documentation

module load intel singularity perl ncbi-blast 

#####!!!!!!NEED TO SET ALL OF THIS UP BEFORE RUNNING
##The genome to be analyzed. Usually a multifasta file.
GENOME=rFer.fa
PREFIX=rFer
## Working directories and files
WORKDIR=/lustre/scratch/daray/carp2
ANNOT=$WORKDIR/annotationfiles/
CODE=/$WORKDIR/code
##Path to singularity container
SINGPATH=/home/daray/singularity_containers
#####Retrieve necessary annotation files
##Known repeats of relevance from RepBase. Should be downloaded from RepBase prior to analysis. 
##For example, if working with vertebrates, download all known vertebrate TEs from RepBase and save as
##vertebrates.fa. Place in subfolder called 'annotationfiles'.
REPBASETES=$ANNOT/Vert_use.fa
KNOWNTES="Vert_use.fa"
##Other known TEs from previous analyses but not in RepBase. Place in subfolder called 'annotationfiles'.
OTHERTES=$ANNOT/bat_rayTEs.fas
OTHERS=bat_rayTEs.fas
##Retrovirus data
##Got to https://www.ncbi.nlm.nih.gov/genomes/GenomesGroup.cgi?taxid=11632 and 'Retreive Sequences' in fasta format. 
RETROS=all_retrovirus.fasta

#########Start work
cd $WORKDIR

#Check for and, if necessary, create subdirectories for files generated.
if [ -d results_classify ] 
then echo "results_classify is present"
else 
mkdir results_classify 
fi

if [ -d ProteinReport ] 
then echo "ProteinReport is present"
else 
mkdir ProteinReport 
fi

if [ -d finallibrary ] 
then echo "finallibrary is present"
else 
mkdir finallibrary
fi

if [ -d chunks ] 
then echo "chunks is present"
else 
mkdir chunks
fi

cd chunks
if [ -d temp ] 
then echo "temp is present"
else 
mkdir temp
fi

#Get necessary annotation files.


##Protein data
cd $ANNOT
wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz 
gunzip uniprot_sprot.fasta.gz
##GenBank TE entries: Only do this if it hasn't been done in the last year or so. Takes a long time.
singularity exec $SINGPATH/carpUbuntu.img esearch -db protein -query "reverse transcriptase or transposon or repetitive element or RNA-directed DNA polymerase or pol protein or non-LTR retrotransposon or mobile element or retroelement or polyprotein or retrovirus or (group-specific antigen gag) or polymerase (pol)" | singularity exec $SINGPATH/carpUbuntu.img efetch -format fasta > GB_TE.fa &
##Be aware that the file obtained above will not be in the right format. There is a step in the next script that corrects it. 

##split genome into manageable parts
cd $WORKDIR/chunks
singularity exec $SINGPATH/carpUbuntu.img bundle -bundle 20000000 -in $WORKDIR/$GENOME 
cat *.fa > $WORKDIR/$PREFIX".mfa"

##Use krishna to self-align genomes
##You may want to change the values for threads or filterlength of filterid depending on your needs.
singularity exec $SINGPATH/carpUbuntu.img matrix -threads=12 -krishnaflags="-tmp=./temp -threads=2 -log -filtid=0.94 -filtlen=200" *.fa


##This should generate many, many files in your chunks folder as well as a 'krishna.gff' file in your working directory. It should also download and populate your annotationfiles folder with 'uniprot_sprot.fasta' and 'GB_TE.fa'

#Move on to next submission script


