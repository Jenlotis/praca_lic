#!/bin/bash

# installing every important program(temporary version)

usage() {
	cat <<EOF
Options
	-h	this help
	-Z	instalation of all neded programs, nessesery github repositories are unpacked to new folder called gihub
	-B	run both subprograms
	-i	input path to folder with every file
	-p	do read are paired deafult = T
	-O	type of organism genetic code chceck MitoFinder -h for all options
	-M	run mitofinder path
	-m	full path to reference file for mitofinder(genebank format only)
	-t	amount of threads programs in mitofinder path will gonna use
	-N	run Novoplasty path
	-n	full path to reference file for novoplasy
		
EOF

}

function programy() {

	sudo apt-get install --assume-yes fastqc
	sudo apt-get install --assume-yes seqkit
	sudo apt-get install --assume-yes fastp
	sudo apt-get install --assume-yes perl
	sudo apt-get install --assume-yes python-pip python3 python3-pip
	sudo apt-get install --assume-yes cmake
	sudo apt-get install --assume-yes git
	sudo apt-get install --assume-yes awk
	sudo apt-get install --assume-yes bbmap
	sudo apt-get install automake autoconf  

	mkdir ./github
	cd ./github

	git clone https://github.com/chrishah/MITObim.git
	git clone https://github.com/Edith1715/NOVOplasty.git
	git clone https://github.com/RemiAllio/MitoFinder.git
		cd MitoFinder
		./install.sh
		p=$(pwd)
		echo -e "\n#Path to MitoFinder \nexport PATH=\$PATH:$p" >> ~/.bashrc 
		source ~/.bashrc  

}


function mitfi() {

	for i in $NAZWY;
	do

		# cleaning data
		# -i input1, -I input2, -o output1, -O output2, -V log info every milion bases, -w amount of used threads
		fastp -i $wejscie$i.1.fastq.gz -I $wejscie$i.2.fastq.gz  -o ./cleanded/$i.Out1.fasta -O ./cleanded/$i.Out2.fasta -w $THREADS -V

		# chcecking size of the file for downsapling
		XXX=$( seqkit stats ./cleaned/Out1.fasta -j $THREADS | awk '$1~"./cleaned/$i.Out1.fasta" {print $4}' | sed 's/,//g' | awk '{print 	7000000/$1*100}' )
		echo $XXX "this is percent of reads that is closest to the highest for mitofinder, we suggest using " $(printf '%.0f' $XXX) " it is however possible to use lower value(int only)"
		echo "To what percent you want to dowsample(recomended $(printf '%.0f' $XXX)): "
		XXX=9 #${XXX%.*}
		echo "We will downsaple to $XXX % of the original"

		# downsampling i packing
		# -s percent of the original , --interleave creates one file with paried ends, -r input files, \ gzip > packing and saving to file
		./github/MITObim/misc_scripts/downsample.py -s $XXX --interleave -r ./cleaned/$i.Out1.fasta -r ./cleaned/$i.Out2.fasta | gzip > ./downsampling/$i.downsam_$XXX.fastaq.gz
		
		# deinterlaving file
		# in= input file(interlaved), out1= i out2= out files(seperated paired ends)
		reformat.sh int=t in=./downsampling/$i.downsam_$XXX.fastaq.gz out1=./downsampling/$i.down_pair1_$XXX.fastq.gz out2=./downsampling/$i.down_pair2_$XXX.fastq.gz overwrite=true
		
		echo $REFERENCE_M "kaka"
		# MITOfinder looking for mitRNA
		# -j process name(internal ID), -1 i -2 input files pair end(-s allows for single end), -r reference sequence, -o which geneteci code to use(5-Invertebrate(bezkregowce))
		mitofinder -j $i.$XXX -1 ./downsampling/$i.Down_pair1_$XXX.fastq.gz -2 ./downsampling/$i.Down_pair2_$XXX.fastq.gz -r $REFERENCE_M -o $ORGANISM --override

done

}


function novpla () {

	for i in $NAZWY;
	do

		# NOVOplasty looking for mitRNA
		# creating config file

		echo "Project:
-----------------------
Project name          = $i
Type                  = mito
Genome Range          = 12000-22000
K-mer                 = 33
Max memory            = 14
Extended log          = 0
Save assembled reads  = no
Seed Input            = $REFERENCE_N
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
Forward reads         = $wejscie$i.1.fastq.gz
Reverse reads         = $wejscie$i.2.fastq.gz
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
Output path          = You can change the directory where all the output files wil be stored.)" > ./github/NOVOplasty/$i\_config.txt

		
		# all things are in config file
		perl ./github/NOVOplasty/NOVOPlasty4.3.1.pl -c ./github/NOVOplasty/$i\_config.txt	
done

}

# jezeli nie ma argumentu(jezeli lista argumentow ma dlugosc 0) wyswietl manual
while test $# -gt 0;
do

	case $1 in
	-h | --help)
		usage
		exit 0
		;;
	-Z)
		echo "installing programs"
		programy
		exit 0
		;;
	-i)
		echo "input path to folder"
		wejscie=("$2")
		shift
		shift
		;;
	-p)
		echo "paired ends"
		PAROWALNOSC="$2"
		if [ $PAROWALNOSC = T ]
		then
			# reads names of every set of input data for latter use
			NAZWY=$(ls $wejscie |awk '$0 ~ ".1.fastq.gz"{print $0}' | awk -F "." '{print $1}')
			echo $NAZWY
		fi
		shift
		shift
		;;
	-m)
		echo "reference for MITOfinder"
		REFERENCE_M="$2"
		shift
		shift
		;;
	-n)
		echo "reference for NOVOPlasty"
		REFERENCE_N="$2"
		shift
		shift
		;;
	-t)
		echo "thread used"
		THREADS="$2"
		shift
		shift
		;;
	-O)
		echo "organism"
		ORGANISM="$2"
		shift
		shift
		;;
	-B)
		echo "Both programs are running"
		mitfi
		novpla
		shift
		;;
	-M)
		echo "only MITOfinder is running"
		mitfi
		shift
		;;

	-N)
		echo "only NOVOPlasty is running"
		novpla
		shift
		;;	


		
	esac
done
exit 3
