rule sequenza:
    input: freeccnvs="freec_out/pass1/{x}.recal.bam_CNVs.p.value.txt",
    output: fit="sequenza_out/{x}"+"_alternative_solutions.txt",
    params: dir=config['project']['workpath'],tumorsample=lambda wildcards: config['project']['pairs'][wildcards.x][1],normalsample=lambda wildcards: config['project']['pairs'][wildcards.x][0],gc=config['references'][pfamily]['SEQUENZAGC'],rname="pl:sequenza"
    threads: 8
    shell: "mkdir -p sequenza_out; mkdir -p sequenza_out/{params.tumorsample}; module load sequenza-utils/2.2.0; module load samtools/1.9; gzip -c freec_out/pass1/{params.tumorsample}/{params.normalsample}.recal.bam_minipileup.pileup > sequenza_out/{params.tumorsample}/{params.normalsample}.recal.bam_minipileup.pileup.gz; gzip -c freec_out/pass1/{params.tumorsample}/{params.tumorsample}.recal.bam_minipileup.pileup > sequenza_out/{params.tumorsample}/{params.tumorsample}.recal.bam_minipileup.pileup.gz; sequenza-utils bam2seqz -p -gc {params.gc} -n sequenza_out/{params.tumorsample}/{params.normalsample}.recal.bam_minipileup.pileup.gz -t sequenza_out/{params.tumorsample}/{params.tumorsample}.recal.bam_minipileup.pileup.gz | gzip > sequenza_out/{params.tumorsample}/{params.tumorsample}.seqz.gz; sequenza-utils seqz_binning -w 100 -s sequenza_out/{params.tumorsample}/{params.tumorsample}.seqz.gz | gzip > sequenza_out/{params.tumorsample}/{params.tumorsample}.bin100.seqz.gz; module load R/3.5; Rscript Scripts/run_sequenza.R sequenza_out/{params.tumorsample}/{params.tumorsample}.bin100.seqz.gz {params.dir}/sequenza_out/{params.tumorsample} {threads} {params.normalsample}+{params.tumorsample}; mv {params.dir}/sequenza_out/{params.tumorsample}/{params.normalsample}+{params.tumorsample}_alternative_solutions.txt {output.fit}"