#!/bin/bash
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=24G
#SBATCH --time=2:00:00
#SBATCH --mail-user=carter.newton@uga.edu
#SBATCH --mail-type=START,END,FAIL
#SBATCH --error=/work/lylab/cjn40747/10DAP_RNA/project.log.%j.err
#SBATCH --output=/work/lylab/cjn40747/10DAP_RNA/project.log.%j.out

OUT='/work/lylab/cjn40747/10DAP_RNA'

ml Trimmomatic/0.39-Java-17
ml FastQC/0.12.1-Java-11

mkdir -p $OUT/unzipped
gunzip -k $OUT/10DAP_RNA_Seq/9064-0002-10052026_162631/*.fastq.gz
mv $OUT/10DAP_RNA_Seq/9064-0002-10052026_162631/*.fastq $OUT/unzipped
mkdir -p $OUT/fastqc
fastqc $OUT/unzipped/*.fastq -o $OUT/fastqc

#mkdir -p $OUT/trimmed_reads
#for file_1 in $OUT/10DAP_RNA_Seq/9064-0002-10052026_162631; do
#    prefix="${file_1%_R1_001.fastq.gz}"
#    file_2="${prefix}_R2_001.fastq.gz"
#    out_dir="$OUT/trimmed_reads/$(basename "$prefix")"
#    name=$(basename "$prefix")
#    mkdir -p "$out_dir"
#    trimmomatic PE -threads 12 "$file_1" "$file_2" $out_dir/$name.1P.fastq.gz $out_dir/$name.1U.fastq.gz $out_dir/$name.2P.fastq.gz $out_dir/$name.2U.fastq.gz ILLUMINACLIP: