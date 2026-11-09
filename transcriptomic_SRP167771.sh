#!/bin/bash
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=24G
#SBATCH --time=1-0:00:00
#SBATCH --mail-user=carter.newton@uga.edu
#SBATCH --mail-type=START,END,FAIL
#SBATCH --error=/work/lylab/cjn40747/10DAP_RNA/Other_RNA_Seq/SRP167771/logs/%j.err
#SBATCH --output=/work/lylab/cjn40747/10DAP_RNA/Other_RNA_Seq/SRP167771/logs/%j.out

OUT='/work/lylab/cjn40747/10DAP_RNA'
OUT2='/work/lylab/cjn40747/10DAP_RNA/Other_RNA_Seq/SRP167771'
REF='https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/086/295/GCF_003086295.3_arahy.Tifrunner.gnm2.J5K5/GCF_003086295.3_arahy.Tifrunner.gnm2.J5K5_genomic.fna.gz'
GFF='https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/086/295/GCF_003086295.3_arahy.Tifrunner.gnm2.J5K5/GCF_003086295.3_arahy.Tifrunner.gnm2.J5K5_genomic.gff.gz'
FAA='https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/086/295/GCF_003086295.3_arahy.Tifrunner.gnm2.J5K5/GCF_003086295.3_arahy.Tifrunner.gnm2.J5K5_protein.faa.gz'

ml Trimmomatic/0.39-Java-17
ml FastQC/0.12.1-Java-11
ml HISAT2/2.2.1-gompi-2023a
ml StringTie/3.0.0-GCC-13.3.0
ml gffread/0.12.7-GCCcore-12.3.0
ml SAMtools/1.23.1-GCC-13.3.0
ml eggnog-mapper/2.1.12-foss-2023a
ml InterProScan/5.76-107.0-GCC-13.3.0
ml MultiQC/1.28-foss-2024a

gunzip -k $OUT2/fastq/*.fastq.gz
mkdir -p $OUT2/fastqc/pre_trim 
fastqc $OUT2/fastq/*.fastq -o $OUT2/fastqc/pre_trim
multiqc $OUT2/fastqc/pre_trim --outdir $OUT2/fastqc/pre_trim

mkdir -p $OUT2/trimmed_reads
for file_1 in $OUT2/fastq/*_1.fastq.gz; do
    prefix="${file_1%_1.fastq.gz}"
    file_2="${prefix}_2.fastq.gz"
    out_dir="$OUT2/trimmed_reads/$(basename "$prefix")"
    name=$(basename "$prefix")
    mkdir -p "$out_dir"
    trimmomatic PE -threads 12 "$file_1" "$file_2" $out_dir/$name.1P.fastq.gz $out_dir/$name.1U.fastq.gz $out_dir/$name.2P.fastq.gz $out_dir/$name.2U.fastq.gz ILLUMINACLIP:/apps/eb/Trimmomatic/0.39-Java-17/adapters/TruSeq3-PE-2.fa:2:30:10:2:True LEADING:3 TRAILING:3 MINLEN:36
    gunzip -k $out_dir/*.gz
    hisat2 -p 12 --dta -x $OUT/Tifrunner_idx -1 "$out_dir/$name.1P.fastq" -2 "$out_dir/$name.2P.fastq" -S $out_dir/$name.sam
    samtools view -b -@ 12 $out_dir/$name.sam -o $out_dir/$name.bam
    samtools sort -@ 12 $out_dir/$name.bam -o $out_dir/$name.sorted.bam
    stringtie -e -B -p 12 --rf -G $OUT/Tifrunner.gtf -o $out_dir/$name.gtf -l $name $out_dir/$name.sorted.bam
    samtools index -@ 12 $out_dir/$name.sorted.bam -o $out_dir/$name.sorted.bai
done

mkdir -p $OUT2/fastqc/post_trim
fastqc $OUT2/trimmed_reads/*/*P.fastq -o $OUT2/fastqc/post_trim
multiqc $OUT2/fastqc/post_trim --outdir $OUT2/fastqc/post_trim

for bam in $OUT2/trimmed_reads/*/*.sorted.bam; do
    echo "$bam"
    samtools flagstat -@ 12 "$bam" | grep -E "primary mapped|properly paired"
done

prepDE.py3 -i $OUT2/trimmed_reads -l 150 -g $OUT2/gene_count_matrix.csv -t $OUT2/transcript_count_matrix.csv