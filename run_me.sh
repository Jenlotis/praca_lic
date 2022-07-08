#!/bin/bash

usage() {
	cat <<EOF
Options
	-h this help
	-Z instalation of all neded programs, nessesery github repositories are unpacked to new folder called 'gihub'
	-i input path to folder with every file
	-p do read are paired, deafult='T'
	-A run all available subprograms
	-M run MitoFinder path
	-m full path to reference file for MitoFinder(genebank format)
	-O type of organism genetic code chceck 'MitoFinder -h' for all options
	-N run NOVOplasty path
	-n full path to reference file for NOVOplasy(fasta format)
	-B run MITObim path
	-b full path to reference file for MITObim

EOF

}

function programy() {

	sudo apt-get install --assume-yes fastqc
	sudo apt-get install --assume-yes curl
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/$USER/.profile
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	brew install seqkit
	sudo apt-get install --assume-yes fastp
	sudo apt-get install --assume-yes libidn11
	sudo apt-get install --assume-yes docker.io
	sudo apt-get install --assume-yes perl
	sudo apt-get install --assume-yes python-pip python3 python3-pip
	sudo apt-get install --assume-yes cmake
	sudo apt-get install --assume-yes git
	sudo apt-get install --assume-yes mawk
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

function clean_sing() {

  if [[ $( ls ./$i/cleaned/ | grep -c $i ) != 2 ]];
	then
		# cleaning data
		# -i input, -o output, -w amount of used threads,  -V log info every milion bases
		fastp -i $wejscie$i.fastq.gz -o ./cleaned/$i.Out.fastq.gz $THREADf -V
	fi
}

function clean_pair() {



  if [[ $( ls ./$i/cleaned/ | grep -c $i.Out..f ) != 2 ]];
	then
		# cleaning data
		# -i input1, -I input2, -o output1, -O output2, -w amount of used threads,  -V log info every milion bases
		fastp -i $wejscie$i.1.fastq.gz -I $wejscie$i.2.fastq.gz  -o ./$i/cleaned/$i.Out1.fastq.gz -O ./$i/cleaned/$i.Out2.fastq.gz $THREADf -V
	fi
}

function downsam_s2s() {
  if [[ $( ls ./downsampling/ | grep -c $i.downsam_ ) != 0 ]];
  then
    procenty=$( ls ./downsampling/ | grep $i.downsam_ | awk -F "." '{print $2}' | awk -F "_" '{print $2}' )
    echo "there allready are downsampled files from $i to $procenty %"
    echo "do you want to use existing one or create new one(Existing/New)"
    read CCC
    if [[ $CCC = E ]];
    then
      echo "what percent ($procenty)"
      read XXX
      echo $XXX
    elif [[ $CCC = N ]];
    then
      DOWN=Start
    fi
  else
    DOWN=Start
  fi

  if [[ $DOWN = Start ]];
  then
    # chcecking size of the file for downsapling
    XXX=$( seqkit stats ./cleaned/$i.Out.fasta $THREADs | awk -v dolari="$i" '$1~"./cleaned/"dolari".Out1.fasta" {print $4}' | sed 's/,//g' | awk '{print 7000000/$1*100}' )
    echo $XXX "this is percent of reads that is closest to the highest for mitofinder, we suggest using " $(printf '%.0f' $XXX) " it is however possible to use lower value(int only)"
    echo "To what percent you want to dowsample(recomended $(printf '%.0f' $XXX)): "
    read XXX
    #XXX=9 #${XXX%.*}
    echo "We will downsaple to $XXX % of the original"

    # downsampling i packing
    # -s percent of the original , --interleave creates one file with paried ends, -r input files, \ gzip > packing and saving to file
    python2 ./github/MITObim/misc_scripts/downsample.py -s $XXX -r ./cleaned/$i.Out.fasta | gzip > ./downsampling/$i.downsam_$XXX.fastq.gz
  fi
}

function downsam_p2p() {

  # input: 2 cleaned files form ilumina; output: 2 downsapled files;
  # if there are already downsampled files function will ask user if they want to use existing ones or create new ones,

  if [[ $( ls ./$i/downsampling/ | grep -c $i.down_pair ) = 2 ]];
  then
    procenty=$( ls ./$i/downsampling/ | grep $i.downsam_ | awk -F "." '{print $2}' | awk -F "_" '{print $2}' )
    echo "there allready are downsampled files from $i to $procenty %"
    echo "do you want to use existing one or create new one(Existing/New)"
    read CCC
    if [[ $CCC = E ]];
    then
      echo "what percent ($procenty)"
      read XXX
      echo $XXX
    elif [[ $CCC = N ]];
    then
      DOWN=Start
    fi
  else
    DOWN=Start
  fi

  if [[ $DOWN = Start ]];
  then
    # chcecking size of the file for downsapling
    date +%T
    XXX=$( seqkit stats ./$i/cleaned/$i.Out1.fastq.gz $THREADs | awk -v dolari="$i" '$1~"./"dolari"/cleaned/"dolari".Out1.fastq.gz" {print $4}' | sed 's/,//g' | awk '{print 7000000/$1*100}' )
    echo $XXX "this is percent of reads that is closest to the highest for mitofinder, we suggest using " $(printf '%.0f' $XXX) " it is however possible to use lower value(int only)"
    echo "To what percent you want to dowsample(recomended $(printf '%.0f' $XXX)): "
    read XXX
    #XXX=9 #${XXX%.*}
    echo "We will downsaple to $XXX % of the original"

    # downsampling i packing
    # -s percent of the original , --interleave creates one file with paried ends, -r input files, \ gzip > packing and saving to file
    python2 ./github/MITObim/misc_scripts/downsample.py -s $XXX --interleave -r ./$i/cleaned/$i.Out1.fastq.gz -r ./$i/cleaned/$i.Out2.fastq.gz | gzip > ./$i/downsampling/$i.downsam_$XXX.fastq.gz

    # deinterlaving file
    # in= input file(interlaved), out1= and out2= out files(seperated paired ends)
    reformat.sh int=t in=./$i/downsampling/$i.downsam_$XXX.fastq.gz out1=./$i/downsampling/$i.down_pair$XXX.1.fastq.gz out2=./$i/downsampling/$i.down_pair$XXX.2.fastq.gz overwrite=true
  fi
}

function interlave() {

	if [[ $( ls ./$i/cleaned/ | grep -c $i.Out_inter ) != 1 ]];
	then
		#interlave
		reformat.sh in1=./$i/cleaned/$i.Out1.fastq.gz in2=./$i/cleaned/$i.Out2.fastq.gz out=./$i/cleaned/$i.Out_inter.fastq.gz overwrite=true
	fi
}


function mitfi_sing() {

  # MITOfinder looking for mitRNA
  # -j process name(internal ID), -s input file single end, -r reference sequence, -o which genetic code to use(5-Invertebrate(bezkregowce))
  python2 mitofinder -j $i.$XXX -s ./downsampling/$i.downsam_$XXX.fastq.gz -r $REFERENCE_M -o $ORGANISM --override
}

function mitfi_pair() {

  # MITOfinder looking for mitRNA
  # -j process name(internal ID), -1 i -2 input files pair end(-s allows for single end), -r reference sequence, -o which genetic code to use(5-Invertebrate(bezkregowce))
  python2 ./github/MitoFinder/mitofinder -j $i.$XXX -1 ./downsampling/$i.down_pair$XXX.1.fastq.gz -2 ./downsampling/$i.down_pair$XXX.2.fastq.gz -r $REFERENCE_M -o $ORGANISM --override
}

function novpla() {

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
Output path           = $p/$i/


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
Output path          = You can change the directory where all the output files wil be stored.)" > ./$i/$i\_Nconfig.txt


	# all things are in config file
	perl ./github/NOVOplasty/NOVOPlasty4.3.1.pl -c ./$i/$i\_Nconfig.txt


}

function mitobim_sing() {

	# starts a docker(if docker doesn't exist ona a computer crates it) then run MITObim, after mitobim end
	sudo docker run -d -it -v $p/$i/cleaned/:/home/data/input/ -v $p/$i/output/:/home/data/output/ -v $p/reference/:/home/data/reference/  chrishah/mitobim /bin/bash

	kontener=$( sudo docker ps | awk '$0 ~ "chrishah" {print $1}' )

	sudo docker exec $kontener /home/src/scripts/MITObim.pl -sample $i -ref $i -readpool /home/data/input/$i.Out.fastq.gz --quick /home/data/reference/$REFERENCE_B -end 10 --clean

	cp -r ./iteration* ./data/output/

	sudo docker stop $kontener
	sudo docker rm $kontener
}

function mitobim_pair() {

	# starts a docker(if docker doesn't exist ona a computer crates it) then run MITObim, after mitobim end
	sudo docker run -d -it -v $p/$i/cleaned/:/home/data/input/ -v $p/$i/output/:/home/data/output/ -v $p/reference/:/home/data/reference/  chrishah/mitobim /bin/bash

	kontener=$( sudo docker ps | awk '$0 ~ "chrishah" {print $1}' )

	sudo docker exec $kontener /home/src/scripts/MITObim.pl -sample $i -ref $i -readpool /home/data/input/$i.Out_inter.fastq.gz --quick /home/data/reference/$REFERENCE_B -end 10 --clean --redirect_tmp /home/data/output/

	cp -r ./iteration* ./data/output/

	sudo docker stop $kontener
	sudo docker rm $kontener
}

alfa=alfa
PAROWALNOSC=T
p=$(pwd)

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
		shift
		shift
		;;

	-m)
		echo "reference for MITOfinder"
		REFERENCE_M="$2"
		dana=$( grep -c LOCUS $REFERENCE_M )
		#echo $dana
		if [ $dana != 1 ]
		then
			echo "wrong file format for reference file for MITOfinder should be GenBank format"
			exit 3
		else
			echo
		fi
		shift
		shift
		;;

	-n)
		echo "reference for NOVOPlasty"
		REFERENCE_N="$2"
		dana=$( grep -c ">" $REFERENCE_N )
		#echo $dana
		if [ $dana != 1 ]
		then
			echo "wrong file format for reference file for NOVOPlasty should be fasta format"
			exit 3
		else
			echo
		fi
		shift
		shift
		;;

	-b)
		echo "reference for MITObim"
		REFERENCE_B=$2
		dana=$( grep -c ">" $REFERENCE_B )
		#echo $dana
		if [ $dana != 1 ]
		then
			echo "wrong file format for reference file for MITObim should be fasta format"
			exit 3
		else
			echo
			REFERENCE_B=$( echo $REFERENCE_B | awk -F "/" '{print $3}')
		fi
		shift
		shift
			;;

	-t)
		echo "thread used $2"
		THREADf="-w $2"
		THREADs="-j $2"
		shift
		shift
		;;

	-O)
		echo "organism"
		ORGANISM="$2"
		shift
		shift
		;;

	-A)
		echo "All programs are running"
		alfa=A
		# mitfi
		# novpla
		shift
		;;

	-B)
		echo "MITObim is running"
		alfa=#!/usr/bin/env bash
		shift
		;;

	-M)
		echo "MITOfinder is running"
		alfa=M
		# mitfi
		shift
		;;

	-N)
		echo "NOVOPlasty is running"
		alfa=N
		# novpla
		shift
		;;

	esac
done

if [ $PAROWALNOSC = T ]
then
	# reads names of every set of input data
	NAZWY=$(ls $wejscie |awk '$0 ~ ".1.fastq.gz" {print $0}' | awk -F "." '{print $1}')
	echo $NAZWY

	for i in $NAZWY;
	do

		mkdir $i
		mkdir ./$i/downsampling
		mkdir ./$i/cleaned
		mkdir ./$i/output

		if [ $alfa == A ];
		then
			#clean_pair
			#downsam_p2p
			#mitfi_pair
			#novpla
			#interlave
			mitobim_pair
		elif [ $alfa == M ];
		then
			clean_pair
			downsam_p2p
			mitfi_pair
		elif [ $alfa == N ];
		then
			novpla
		elif [ $alfa == B ];
		then
			interlave
			mitobim_pair
		else
			echo "program not chosen"
		fi
	done

elif [ $PAROWALNOSC = F ]
then
	# reads names of every set of input data
	NAZWY=$(ls |awk '$0 ~ ".fastq.gz" {print $0}' |awk -F "." '$2 !~ "1" && $2 !~ "2" '| awk -F "." '{print $1}')
	echo $NAZWY

	for i in $NAZWY;
	do

		mkdir $i
		mkdir ./$i/downsampling
		mkdir ./$i/cleaned

		if [ $alfa == A ];
		then
			clean_sing
			downsam_s2s
			mitfi_sing
			mitobim_sing
		elif [ $alfa == M ];
		then
			clean_sing
			downsam_s2s
			mitfi_sing
		elif [ $alfa == B ];
		then
			mitobim_sing
		else
			echo "program not chosen"
		fi
	done

fi

exit 1
