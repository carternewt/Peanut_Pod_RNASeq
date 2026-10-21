#!/bin/bash
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=24G
#SBATCH --time=1-0:00:00
#SBATCH --mail-user=carter.newton@uga.edu
#SBATCH --mail-type=START,END,FAIL
#SBATCH --error=/work/lylab/cjn40747/10DAP_RNA/logs/%j.err
#SBATCH --output=/work/lylab/cjn40747/10DAP_RNA/logs/%j.out

OUT='/work/lylab/cjn40747/10DAP_RNA'
REF='https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/086/295/GCF_003086295.3_arahy.Tifrunner.gnm2.J5K5/GCF_003086295.3_arahy.Tifrunner.gnm2.J5K5_genomic.fna.gz'
GFF='https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/086/295/GCF_003086295.3_arahy.Tifrunner.gnm2.J5K5/GCF_003086295.3_arahy.Tifrunner.gnm2.J5K5_genomic.gff.gz'

ml Trimmomatic/0.39-Java-17
ml FastQC/0.12.1-Java-11
ml HISAT2/2.2.1-gompi-2023a
ml StringTie/3.0.0-GCC-13.3.0
ml gffread/0.12.7-GCCcore-12.3.0
ml SAMtools/1.23.1-GCC-13.3.0

#curl -s $REF | gunzip -c > $OUT/Tifrunner.fa
#hisat2-build -p 12 $OUT/Tifrunner.fa $OUT/Tifrunner_idx
#curl -s $GFF | gunzip -c > $OUT/Tifrunner.gff
#awk -F'\t' '!/^#/ && $7=="?"' Tifrunner.gff | cut -f3,9 | cut -c1-120
#grep -v 'gene=rps12' Tifrunner.gff > Tifrunner.fixed.gff #remove this gene annotation due to presence of '?' 
#gffread $OUT/Tifrunner.gff -T -o $OUT/Tifrunner.gtf

#mkdir -p $OUT/unzipped
#gunzip -k $OUT/10DAP_RNA_Seq/9064-0002-10052026_162631/*.fastq.gz
#mv $OUT/10DAP_RNA_Seq/9064-0002-10052026_162631/*.fastq $OUT/unzipped
#mkdir -p $OUT/fastqc
#fastqc $OUT/unzipped/*.fastq -o $OUT/fastqc

mkdir -p $OUT/trimmed_reads
mkdir -p $OUT/hisat2

for file_1 in $OUT/10DAP_RNA_Seq/9064-0002-10052026_162631/*_R1_001.fastq.gz; do
    prefix="${file_1%_R1_001.fastq.gz}"
    file_2="${prefix}_R2_001.fastq.gz"
    out_dir="$OUT/trimmed_reads/$(basename "$prefix")"
    name=$(basename "$prefix")
    mkdir -p "$out_dir"
    trimmomatic PE -threads 12 "$file_1" "$file_2" $out_dir/$name.1P.fastq.gz $out_dir/$name.1U.fastq.gz $out_dir/$name.2P.fastq.gz $out_dir/$name.2U.fastq.gz ILLUMINACLIP:/apps/eb/Trimmomatic/0.39-Java-17/adapters/TruSeq3-PE-2.fa:2:30:10:2:True LEADING:3 TRAILING:3 MINLEN:36
    gunzip -k $out_dir/*.gz
    hisat2 -p 12 --dta -x $OUT/Tifrunner_idx -1 "$out_dir/$name.1P.fastq" -2 "$out_dir/$name.2P.fastq" -S $out_dir/$name.sam
    samtools view -b -@ 12 $out_dir/$name.sam -o $out_dir/$name.bam
    samtools sort -@ 12 $out_dir/$name.bam -o $out_dir/$name.sorted.bam
    stringtie -p 12 -G $OUT/Tifrunner.gtf -o $out_dir/$name.gtf -l $name $out_dir/$name.sorted.bam
done