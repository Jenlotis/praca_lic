#!/bin/bash
while true; do

echo "Which program do you want to use(M/N)"
read PROGRAM
PROGRAM=${PROGRAM^}

# reads names of every set of input data for latter use
NAZWY=$(ls ./input |awk '$0 ~ ".1.fastq.gz"{print $0}' | awk -F "." '{print $1}')
echo $NAZWY

if [ $PROGRAM = M ];
then

	for i in $NAZWY
	do
		echo "What is thread count you want to use: "
		read THREADS
		echo "We will be using $THREADS threads"

		echo "give the full name of the reference file it must be in reference folder and in genebnak format: "
		read REFERENCE_M

		# cleaning data
		# -i input1, -I input2, -o output1, -O output2, -V log info every milion bases, -w amount of used threads
		fastp -i ./input/$i.1.fastq.gz -I ./input/$i.2.fastq.gz  -o ./cleanded/$i.Out1.fasta -O ./cleanded/$i.Out2.fasta -w $THREADS

		# chcecking size of the file for downsapling
		XXX=$( seqkit stats ./cleaned/Out1.fasta -j $THREADS | awk '$1~"./cleaned/Out1.fasta" {print $4}' | sed 's/,//g' | awk '{print 	7000000/$1*100}' )
		echo $XXX "this is percent of reads that is closest to the highest for mitofinder, we suggest using " $(printf '%.0f' $XXX) " it is however possible to use lower value(int only)"
		echo "To what percent you want to dowsample(recomended $(printf '%.0f' $XXX)): "
		# read XXX
		echo "We will downsaple to $XXX % of the original"

		# downsampling i packing
		# -s percent of the original , --interleave creates one file with paried ends, -r input files, \ gzip > packing and saving to file
		./MITObim-1.9.1/misc_scripts/downsample.py -s $XXX --interleave -r ./cleaned/$i.Out1.fasta -r ./cleaned/$i.Out2.fasta | gzip > ./downsampling/$i.downsam_$XXX.fastaq.gz

		# deinterlaving file
		# in= input file(interlaved), out1= i out2= out files(seperated paired ends)
		./BBMap_38.95/reformat.sh in=./downsampling/$i.downsam_$XXX.fastaq.gz out1=./downsampling/$i.down_pair1_$XXX.fastq.gz out2=./downsampling/$i.down_pair2_$XXX.fastq.gz 

		# MITOfinder looking for mitRNA
		# -j process name(internal ID), -1 i -2 input files pair end(-s allows for single end), -r reference sequence, -o which geneteci code to use(5-Invertebrate(bezkregowce))
		mitofinder -j $i.$XXX -1 ./downsampling/$i.Down_pair1_$XXX.fastq.gz -2 ./downsampling/$i.Down_pair2_$XXX.fastq.gz -r ./reference/$REFERENCE_M -o 5 --override

	done

elif [ $PROGRAM = N ];
then
	# NOVOplasty looking for mitRNA
	# creating config file

	for i in $NAZWY
	do

		echo "Give the full name of the reference file. It must be in \"reference\" folder and in \"fasta\" format: "
		read REFERENCE_N

		echo "Project:
-----------------------
Project name          = $i
Type                  = mito
Genome Range          = 12000-22000
K-mer                 = 33
Max memory            = 14
Extended log          = 0
Save assembled reads  = no
Seed Input            = ../reference/$REFERENCE_N
Extend seed directly  = no
Reference sequence    =
Variance detection    =
Chloroplast sequence  =

Dataset 1:
-----------------------
Read Length           = 151
Insert size           = 300
Platform              = illumina
Single/Paired         = PE
Combined reads        = 
Forward reads         = ../input/$i.1.fastq.gz
Reverse reads         = ../input/$i.2.fastq.gz
Store Hash            =

Heteroplasmy:
-----------------------
MAF                   = 
HP exclude list       = 
PCR-free              = 

Optional:
-----------------------
Insert size auto      = yes
Use Quality Scores    = no
Output path           = 


Project:
-----------------------
Project name         = Choose a name for your project, it will be used for the output files.
Type                 = (chloro/mito/mito_plant) \"chloro\" for chloroplast assembly, \"mito\" for mitochondrial assembly and 
                       \"mito_plant\" for mitochondrial assembly in plants.
Genome Range         = (minimum genome size-maximum genome size) The expected genome size range of the genome.
                       Default value for mito: 12000-20000 / Default value for chloro: 120000-200000
                       If the expected size is know, you can lower the range, this can be useful when there is a repetitive
                       region, what could lead to a premature circularization of the genome.
K-mer                = (integer) This is the length of the overlap between matching reads (Default: 33). 
                       If reads are shorter then 90 bp or you have low coverage data, this value should be decreased down to 23. 
                       For reads longer then 101 bp, this value can be increased, but this is not necessary.
Max memory           = You can choose a max memory usage, suitable to automatically subsample the data or when you have limited                      
                       memory capacity. If you have sufficient memory, leave it blank, else write your available memory in GB
                       (if you have for example a 8 GB RAM laptop, put down 7 or 7.5 (don\'t add the unit in the config file))
Extended log         = Prints out a very extensive log, could be useful to send me when there is a problem  (0/1).
Save assembled reads = All the reads used for the assembly will be stored in seperate files (yes/no)
Seed Input           = The path to the file that contains the seed sequence.
Extend seed directly = This gives the option to extend the seed directly, in stead of finding matching reads. Only use this when your seed 
                       originates from the same sample and there are no possible mismatches (yes/no)
Reference (optional) = If a reference is available, you can give here the path to the fasta file.
                       The assembly will still be de novo, but references of the same genus can be used as a guide to resolve 
                       duplicated regions in the plant mitochondria or the inverted repeat in the chloroplast. 
                       References from different genus haven\'t beeen tested yet.
Variance detection   = If you select yes, you should also have a reference sequence (previous line). It will create a vcf file                
                       with all the variances compared to the give reference (yes/no)
Chloroplast sequence = The path to the file that contains the chloroplast sequence (Only for mito_plant mode).
                       You have to assemble the chloroplast before you assemble the mitochondria of plants!

Dataset 1:
-----------------------
Read Length          = The read length of your reads.
Insert size          = Total insert size of your paired end reads, it doesn\'t have to be accurate but should be close enough.
Platform             = illumina/ion - The performance on Ion Torrent data is significantly lower
Single/Paired        = For the moment only paired end reads are supported.
Combined reads       = The path to the file that contains the combined reads (forward and reverse in 1 file)
Forward reads        = The path to the file that contains the forward reads (not necessary when there is a merged file)
Reverse reads        = The path to the file that contains the reverse reads (not necessary when there is a merged file)
Store Hash           = If you want several runs on one dataset, you can store the hash locally to speed up the process (put \"yes\" to store the hashes locally)
                       To run local saved files, goto te wiki section of the github page

Heteroplasmy:
-----------------------
MAF                  = (0.007-0.49) Minor Allele Frequency: If you want to detect heteroplasmy, first assemble the genome without this option. Then give the resulting                         
                       sequence as a reference and as a seed input. And give the minimum minor allele frequency for this option 
                       (0.01 will detect heteroplasmy of >1%)
HP exclude list      = Option not yet available  
PCR-free             = (yes/no) If you have a PCR-free library write yes

Optional:
-----------------------
Insert size auto     = (yes/no) This will finetune your insert size automatically (Default: yes)                               
Use Quality Scores   = It will take in account the quality scores, only use this when reads have low quality, like with the    
                       300 bp reads of Illumina (yes/no)
Output path          = You can change the directory where all the output files wil be stored.)" > ./NOVOPlasty/$i.config.txt

echo "zapis"

		# all things are in config file
		cd NOVOPlasty/
		perl NOVOPlasty4.3.1.pl -c $i.config.txt
	
	done
	
else
	#go back
	echo "wrong letter"
	continue
fi

break
done
