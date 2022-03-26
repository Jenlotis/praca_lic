#!/bin/bash

# install fastqc/seqkit
# 


# for i in 
#cleaning data
#-i input1, -I input2, -o output1, -O output2, -V log info every milion bases, -w amount of used threads
fastp -i ./in/*.1.fastq.gz -I ./in/*.2.fastq.gz -o ./cleanded/Out1.fasta -O ./cleanded/Out2.fasta -V -w 10

#downsampling i packing
#-s percent of the original , --interleave creates one file with paried ends, -r input files, \ gzip > packing and saving to file
./MITObim-1.9.1/downsample.py -s XXX --interleave -r ./Out1.fasta -r ./Out2.fasta | gzip > ./downsample/XXX_PENT/Downsam_XXX.fastaq.gz

#deinterlaving file
#in= input file(interlaved), out1= i out2= out files(seperated paired ends)
./BBMap_38.95/reformat.sh in=./downsample/XXX_PENT/Downsam_XXX.fastaq.gz out1=./downsample/XXX_PENT/Down_pair1_XXX.fastq.gz out2=./downsample/XXX_PENT/Down_pair2_XXX.fastq.gz 

#MITOfinder looking for mitRNA
#-j process name(internal ID), -1 i -2 input files pair end(-s allows for single end), -r reference sequence, -o which geneteci code to use(5-Invertebrate(bezkregowce))
mitofinder -j troch_XXX -1 ./downsample/XXX_PENT/Down_pair1_XXX.fastq.gz -2 ./downsample/XXX_PENT/Down_pair2_XXX.fastq.gz -r ./reference/MF491526.gb -o 5
