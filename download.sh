#!/bin/bash
#SBATCH --partition=batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=24G
#SBATCH --time=1-0:00:00
#SBATCH --mail-user=carter.newton@uga.edu
#SBATCH --mail-type=START,END,FAIL
#SBATCH --error=/work/lylab/cjn40747/10DAP_RNA/Other_RNA_Seq/logs/%j.err
#SBATCH --output=/work/lylab/cjn40747/10DAP_RNA/Other_RNA_Seq/logs/%j.out

OUT='/work/lylab/cjn40747/10DAP_RNA'

cd $OUT/Other_RNA_Seq/SRP167771/fastq
sed 's#^#ftp://#' $OUT/Other_RNA_Seq/SRP167771/urls_SRP167771.txt | xargs -n 1 -P 12 wget -c -nv 

cd $OUT/Other_RNA_Seq/PRJNA470988/fastq
sed 's#^#ftp://#' $OUT/Other_RNA_Seq/SRP167771/urls.txt | xargs -n 1 -P 12 wget -c -nv