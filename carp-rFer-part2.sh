#$ -V
#$ -cwd
#$ -S /bin/bash
#$ -N carprFer2
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
WORKDIR=/lustre/scratch/daray/carp2
##Path to singularity container
SINGPATH=/home/daray/singularity_containers

cd $WORKDIR
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

ANNOT=$WORKDIR/annotationfiles/
REPBASETES=$ANNOT/Vert_use.fa
KNOWNTES="Vert_use.fa"

##Fix GB_TE.fa
cd $ANNOT
perl -pi -e "s/^>/>gi|GBTE|sp|/g" GB_TE.fa
sed -i 's/ /| /' GB_TE.fa

OTHERTES=$ANNOT/bat_rayTEs.fas
OTHERS=bat_rayTEs.fas

RETROS=all_retrovirus.fasta
CODE=/$WORKDIR/code

#########Start work


cd $WORKDIR/chunks


##Use igor to report repeat feature family groupings in JSON format -- WORKING
find ./ -maxdepth 1 -name '[!.]*.gff' -print0 | xargs -r0 cat >$WORKDIR/krishna.gff

cd $WORKDIR
singularity exec $SINGPATH/carpUbuntu.img igor -in krishna.gff -out krishna.json

##Use seqer to generate consensus sequences from genome intervals -- WORKING
singularity exec $SINGPATH/carpUbuntu.img gffer < krishna.json > krishna.igor.gff

singularity exec $SINGPATH/carpUbuntu.img seqer -aligner=muscle -dir=consensus -fasta=true -maxFam=100 -subsample=true -minLen=0.95 -threads=36 -ref=$PREFIX".mfa" krishna.igor.gff

##Use RepeatMasker to annotate consensus sequences with the Repbase library -- WORKING
find ./consensus -maxdepth 1 -name '[!.]*.fq' -print0 | xargs -r0 cat > ConsensusSequences.fa

cat $REPBASETES $OTHERTES > combined_library.fa

/lustre/work/daray/software/RepeatMasker/RepeatMasker -pa 36 -a -nolow -norna -dir ./ -lib combined_library.fa ConsensusSequences.fa

singularity exec $SINGPATH/carpUbuntu.img perl code/format_RMSK.pl ConsensusSequences.fa.out >ConsensusSequences.fa.map

##Ok. This part is tricksy. 
##Change lines 23, 24, 27, 28, 29 as appropriate for your filenames
##Save the modified files to the code folder under a new name.
sed "s/Vertebrate_use.fa/$KNOWNTES/g" $CODE/ClassifyConsensusSequences.java >ClassifyConsensusSequences_mod.java
sed -i "s/our_known_reps_20130520.fasta/$OTHERS/g" ClassifyConsensusSequences_mod.java
sed -i "s/public class ClassifyConsensusSequences/public class ClassifyConsensusSequences_mod/g" ClassifyConsensusSequences_mod.java
singularity exec $SINGPATH/carpUbuntu.img javac ClassifyConsensusSequences_mod.java
singularity exec $SINGPATH/carpUbuntu.img java -cp . ClassifyConsensusSequences_mod
mv ClassifyConsensusSequences_mod* $CODE  

##Filter sequences
##ID protein coding sequences
makeblastdb -in $ANNOT/uniprot_sprot.fasta -dbtype prot 
blastx -db $ANNOT/uniprot_sprot.fasta -query results_classify/notKnown.fa -max_hsps 1 -seg no -evalue 0.00001 -num_threads 32 -max_target_seqs 1 -word_size 2 -outfmt 6 -out results_classify/notKnown.fa.spwb.ncbi
awk '{print $1"\t""blast""\t""hit""\t"$7"\t"$8"\t"$11"\t"".""\t"".""\t""Target sp|"$2" "$9" "$10}' results_classify/notKnown.fa.spwb.ncbi | awk '{if($4>$5) print $1"\t"$2"\t"$3"\t"$5"\t"$4"\t"$6"\t"$7"\t"$8"\t"$9" "$10" "$11" "$12; else print $0}' > results_classify/notKnown.fa.spwb.gff

##ID GenBank TEs
makeblastdb -in $ANNOT/GB_TE.fa -dbtype prot -out $ANNOT/GB_TE.new
blastx -db $ANNOT/GB_TE.new -query results_classify/notKnown.fa -max_hsps 1 -seg no -evalue 0.00001 -num_threads 32 -max_target_seqs 1 -word_size 2 -outfmt 6 -out results_classify/notKnown.fa.tewb.ncbi
awk '{print $1"\t""blast""\t""hit""\t"$7"\t"$8"\t"$11"\t"".""\t"".""\t""Target sp|"$2" "$9" "$10}' results_classify/notKnown.fa.tewb.ncbi | awk '{if($4>$5) print $1"\t"$2"\t"$3"\t"$5"\t"$4"\t"$6"\t"$7"\t"$8"\t"$9" "$10" "$11" "$12; else print $0}' > results_classify/notKnown.fa.tewb.gff

##ID retroviruses
makeblastdb -in $ANNOT/all_retrovirus.fasta -dbtype nucl
tblastx -db $ANNOT/all_retrovirus.fasta -query results_classify/notKnown.fa -max_hsps 1 -seg no -evalue 0.00001 -num_threads 32 -max_target_seqs 1 -word_size 2 -outfmt 6 -out results_classify/notKnown.fa.ervwb.ncbi
awk '{print $1"\t""blast""\t""hit""\t"$7"\t"$8"\t"$11"\t"".""\t"".""\t""Target sp|"7 $2" "$9" "$10}' results_classify/notKnown.fa.ervwb.ncbi | awk '{if($4>$5) print $1"\t"$2"\t"$3"\t"$5"\t"$4"\t"$6"\t"$7"\t"$8"\t"$9" "$10" "$11" "$12; else print $0}' > results_classify/notKnown.fa.ervwb.gff
cp results_classify/notKnown.fa.spwb.gff ProteinReport/notKnown.fa.spwb.gff
cp results_classify/notKnown.fa ProteinReport/notKnown.fa

##Get protein information from consensus sequences
##GetProteins.java will be used. It needs two input files: notKnown.fa, notKnown.fa.spwb.gff.
##Change lines 4-11 as appropriate for your filenames
##Save the modified files to the code folder.
cp $CODE/GetProteins.java GetProteins.java
singularity exec $SINGPATH/carpUbuntu.img javac GetProteins.java
singularity exec $SINGPATH/carpUbuntu.img java -cp . GetProteins
mv GetProteins* $CODE 
mv protein.txt results_classify/protein.txt

##Check for simple sequence repeats
##Must download and install phobos
##http://www.ruhr-uni-bochum.de/ecoevo/cm/cm_phobos.htm
/lustre/scratch/daray/carp-rm/code/phobos-v3.3.12-linux/bin/phobos-linux-gcc4.1.2 -r 7 --outputFormat 0 --printRepeatSeqMode 0 ProteinReport/notKnownNotProtein.fa > results_classify/notKnownNotProtein.phobos
cp $CODE/IdentifySSRs.java IdentifySSRs.java
singularity exec $SINGPATH/carpUbuntu.img javac IdentifySSRs.java
singularity exec $SINGPATH/carpUbuntu.img java -cp . IdentifySSRs
mv IdentifySSRs* $CODE 
mv SSR.txt results_classify/SSR.txt

##Generate annotated repeat library
##Need ten files to get this to work. 
##1. ConsensusSequences.fa
##2. ConsensusSequences.fa.map
##3. notKnown.fa.tewb.gff
##4. notKnown.fa.ervwb.gff
##5. protein.txt
##6. known.txt
##7. GB_TE.fa
##8. all_retrovirus.fasta
##9. SSR.txt (if you do not have this, leave the definition in, it will generate error messages, but will not stop the program or affect the results.)
##10. LA4v2-satellite.fa (you do not have this, or equivalent, as you didn’t have any satellites, but leave the definition in-it will cause error messages, but will not stop the program or affect the results.)
##Check lines 442-457 for necessary files, paths, and parameters.
cp $CODE/GenerateAnnotatedLibrary.java GenerateAnnotatedLibrary.java
singularity exec $SINGPATH/carpUbuntu.img javac GenerateAnnotatedLibrary.java
singularity exec $SINGPATH/carpUbuntu.img java -cp . GenerateAnnotatedLibrary
mv GenerateAnnotatedLibrary* $CODE 

cd finallibrary
python ../code/sort-carp.py Denovo_TE_Library.fasta $PREFIX

cut -d ' ' -f1 $PREFIX"_annotated.fa" | sed 's/_consensus:/_/g' | sed 's/\*/#/' | sed 's/\*/\//' | sed 's/NonLTR\/LINE/LINE\/LINE/g' |  sed 's/NonLTR\/SINE/SINE\/SINE/g'>$PREFIX"_annotated_rm.fa"
sed 's/consensus#Chimeric/Chimeric:/g' $PREFIX"_chimeric.fa" | sed 's/ric: /ric:/g'| sed 's/ /_/g' | sed 's/;_/;/g' >$PREFIX"_chimeric_mod.fa"
sed 's/consensus#PartialAnnotation/Partial:/g' $PREFIX"_partial.fa" | sed 's/tial: /tial:/g'| sed 's/ /_/g' | sed 's/;_/;/g' >$PREFIX"_partial_mod.fa"
sed 's/consensus#//g' $PREFIX"_unclassified.fa" | sed 's/ Matches no similar sequence/#Unknown\/Unknown/g' > $PREFIX"_unclassified_rm.fa" 

grep "Family#" $WORKING/carprFer2.e* | awk '{print $3 "\t" $4}' | sed 's/(//g' | sed 's/)//g' | sed 's/#//g' >rFer_familycounts.txt

sort -nrk2 rFer_familycounts.txt >rFer_familysorts.txt

