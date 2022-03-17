#!/bin/bash

# for i in 
echo "What is thread count you want to use: "
read THREADS
echo "We will be using $THREADS"

# cleaning data
# -i input1, -I input2, -o output1, -O output2, -V log info every milion bases, -w amount of used threads
# fastp -i  -I  -o ./cleanded/Out1.fasta -O ./cleanded/Out2.fasta -V -w $THREADS

# chcecking size of the file for downsapling
#XXX=$( seqkit stats ./cleaned/Out1.fasta -j $THREADS | awk '$1~"./cleaned/Out1.fasta" {print $4}' | sed 's/,//g' | awk '{print 7000000/$1*100}' )
echo $XXX "this is percent of reads that is closest to the highest for mitofinder, we suggest using " $(printf '%.0f' $XXX) " it is however possible to use lower value(int only)"
echo "To what percent you want to dowsample(recomended $(printf '%.0f' $XXX)): "
read XXX
echo "We will downsaple to $XXX % of the original"

# downsampling i packing
# -s percent of the original , --interleave creates one file with paried ends, -r input files, \ gzip > packing and saving to file
./MITObim-1.9.1/misc_scripts/downsample.py -s $XXX --interleave -r ./cleaned/Out1.fasta -r ./cleaned/Out2.fasta | gzip > ./downsampling/Downsam_$XXX.fastaq.gz

# deinterlaving file
# in= input file(interlaved), out1= i out2= out files(seperated paired ends)
./BBMap_38.95/reformat.sh in=./downsampling/Downsam_$XXX.fastaq.gz out1=./downsampling/Down_pair1_$XXX.fastq.gz out2=./downsampling/Down_pair2_$XXX.fastq.gz 

# MITOfinder looking for mitRNA
# -j process name(internal ID), -1 i -2 input files pair end(-s allows for single end), -r reference sequence, -o which geneteci code to use(5-Invertebrate(bezkregowce))
mitofinder -j troch_$XXX -1 ./downsampling/Down_pair1_$XXX.fastq.gz -2 ./downsampling/Down_pair2_$XXX.fastq.gz -r ./reference/MF491526.gb -o 5
