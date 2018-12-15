if config['project']['annotation'] == "hg19":

  rule all_exomeseq_somatic:
    input:  expand("{s}"+".recal.bam",s=samples),
#            expand("{s}"+".g.vcf",s=samples),
            expand(config['project']['workpath']+"/mutect_out/{p}"+".FINAL.vcf",p=pairs),
            expand(config['project']['workpath']+"/mutect2_out/{p}"+".FINALmutect2.vcf",p=pairs),
            expand(config['project']['workpath']+"/strelka_out/{p}"+"_FINAL.vcf",p=pairs),
            expand(config['project']['workpath']+"/mutect2_out/oncotator_out/{p}"+".maf",p=pairs),
            expand(config['project']['workpath']+"/strelka_out/oncotator_out/{p}"+".maf",p=pairs),
            expand(config['project']['workpath']+"/mutect_out/oncotator_out/{p}"+".maf",p=pairs),
            config['project']['workpath']+"/mutect2_out/mutect2_maf_summary.pdf",
            config['project']['workpath']+"/mutect_out/mutect_maf_summary.pdf",
            config['project']['workpath']+"/strelka_out/strelka_maf_summary.pdf",
            expand(config['project']['workpath']+"/cnvkit_out/{p}_calls.cns", p=pairs),
            expand(config['project']['workpath']+"/cnvkit_out/{p}_gainloss.tsv", p=pairs),                        
            dynamic(expand(config['project']['workpath']+"/theta_out/{p}/{p}_thetaIN", p=pairs)),
            expand(config['project']['workpath']+"/conpair_out/{p}.conpair", p=pairs),
            config['project']['workpath']+"/cnvkit_out/CNVkit_summary_heatmap.pdf",
            "sample_network.bmp",
            config['project']['workpath']+"/mutect2_out/mutect2_variants.database",
            config['project']['workpath']+"/mutect_out/mutect_variants.database",
            config['project']['workpath']+"/strelka_out/strelka_variants.database",
            config['project']['workpath']+"/mutect2_out/oncotator_out/final_filtered.maf",
            config['project']['workpath']+"/mutect2_out/mutsigCV_out/somatic.sig_genes.txt",
            config['project']['workpath']+"/strelka_out/oncotator_out/final_filtered.maf",
            config['project']['workpath']+"/strelka_out/mutsigCV_out/somatic.sig_genes.txt",
            config['project']['workpath']+"/mutect_out/oncotator_out/final_filtered.maf",
            config['project']['workpath']+"/mutect_out/mutsigCV_out/somatic.sig_genes.txt",
            config['project']['workpath']+"/exome_targets.bed",
            expand("manta_out/{p}/results/variants/candidateSV.vcf.gz", p=pairs),
            "admixture_out/admixture_table.tsv",
            "QC/decoy"
    output:
    params: rname="final"
    shell:  """
             module load multiqc/1.4; multiqc -f -e featureCounts .; mv *.out slurmfiles/; perl Scripts/summarize_usage.pl; rm *realign.bai; mv distance.cluster0 distance.cluster1 distance.cluster2 distance.cluster3 distance.nosex samples.txt plink.map plink.ped logfiles/

            """
elif config['project']['annotation'] == "hg38":

  rule all_exomeseq_somatic:
    input:  expand("{s}"+".recal.bam",s=samples),
#            expand("{s}"+".g.vcf",s=samples),
            expand(config['project']['workpath']+"/mutect_out/{p}"+".FINAL.vcf",p=pairs),
            expand(config['project']['workpath']+"/mutect2_out/{p}"+".FINALmutect2.vcf",p=pairs),
            expand(config['project']['workpath']+"/strelka_out/{p}"+"_FINAL.vcf",p=pairs),
            expand(config['project']['workpath']+"/mutect2_out/oncotator_out/{p}"+".maf",p=pairs),
            expand(config['project']['workpath']+"/strelka_out/oncotator_out/{p}"+".maf",p=pairs),
            expand(config['project']['workpath']+"/mutect_out/oncotator_out/{p}"+".maf",p=pairs),
            config['project']['workpath']+"/mutect2_out/mutect2_maf_summary.pdf",
            config['project']['workpath']+"/mutect_out/mutect_maf_summary.pdf",
            config['project']['workpath']+"/strelka_out/strelka_maf_summary.pdf",
            expand(config['project']['workpath']+"/cnvkit_out/{p}_calls.cns", p=pairs),
            expand(config['project']['workpath']+"/cnvkit_out/{p}_gainloss.tsv", p=pairs),                        
            dynamic(expand(config['project']['workpath']+"/theta_out/{p}/{p}_thetaIN", p=pairs)),
            expand(config['project']['workpath']+"/conpair_out/{p}.conpair", p=pairs),
            config['project']['workpath']+"/cnvkit_out/CNVkit_summary_heatmap.pdf",
            "sample_network.bmp",
            config['project']['workpath']+"/mutect2_out/mutect2_variants.database",
            config['project']['workpath']+"/mutect_out/mutect_variants.database",
            config['project']['workpath']+"/strelka_out/strelka_variants.database",
            config['project']['workpath']+"/mutect2_out/oncotator_out/final_filtered.maf",
            config['project']['workpath']+"/mutect2_out/mutsigCV_out/somatic.sig_genes.txt",
            config['project']['workpath']+"/strelka_out/oncotator_out/final_filtered.maf",
            config['project']['workpath']+"/strelka_out/mutsigCV_out/somatic.sig_genes.txt",
            config['project']['workpath']+"/mutect_out/oncotator_out/final_filtered.maf",
            config['project']['workpath']+"/mutect_out/mutsigCV_out/somatic.sig_genes.txt",
            config['project']['workpath']+"/exome_targets.bed",
            expand("manta_out/{p}/results/variants/candidateSV.vcf.gz", p=pairs),
            "admixture_out/admixture_table.tsv",
            "QC/decoy"
    output:
    params: rname="final"
    shell:  """
             module load multiqc/1.4; multiqc -f -e featureCounts .; mv *.out slurmfiles/; perl Scripts/summarize_usage.pl; rm *realign.bai; mv distance.cluster0 distance.cluster1 distance.cluster2 distance.cluster3 distance.nosex samples.txt plink.map plink.ped logfiles/

            """

elif config['project']['annotation'] == "mm10":

  rule all_exomeseq_somatic:
    input:  expand("{s}"+".recal.bam",s=samples),
            expand(config['project']['workpath']+"/mutect_out/{p}"+".FINAL.vcf",p=pairs),
            expand(config['project']['workpath']+"/mutect2_out/{p}"+".FINALmutect2.vcf",p=pairs),
            expand(config['project']['workpath']+"/strelka_out/{p}"+"_FINAL.vcf",p=pairs),
            expand(config['project']['workpath']+"/mutect2_out/oncotator_out/{p}"+".maf",p=pairs),
            expand(config['project']['workpath']+"/strelka_out/oncotator_out/{p}"+".maf",p=pairs),
            expand(config['project']['workpath']+"/mutect_out/oncotator_out/{p}"+".maf",p=pairs),
            expand(config['project']['workpath']+"/cnvkit_out/{p}_calls.cns", p=pairs),
            expand(config['project']['workpath']+"/cnvkit_out/{p}_gainloss.tsv", p=pairs),                        
            dynamic(expand(config['project']['workpath']+"/theta_out/{p}/{p}_thetaIN", p=pairs)),
            expand(config['project']['workpath']+"/conpair_out/{p}.conpair", p=pairs),
            config['project']['workpath']+"/cnvkit_out/CNVkit_summary_heatmap.pdf",
            config['project']['workpath']+"/mutect2_out/mutect2_variants.database",
            config['project']['workpath']+"/mutect_out/mutect_variants.database",
            config['project']['workpath']+"/strelka_out/strelka_variants.database",
            "sample_network.bmp",
            config['project']['workpath']+"/mutect2_out/oncotator_out/final_filtered.maf",
            config['project']['workpath']+"/mutect2_out/mutsigCV_out/somatic.sig_genes.txt",
            config['project']['workpath']+"/strelka_out/oncotator_out/final_filtered.maf",
            config['project']['workpath']+"/strelka_out/mutsigCV_out/somatic.sig_genes.txt",
            config['project']['workpath']+"/mutect_out/oncotator_out/final_filtered.maf",
            config['project']['workpath']+"/mutect_out/mutsigCV_out/somatic.sig_genes.txt",
            config['project']['workpath']+"/exome_targets.bed",
            expand("manta_out/{p}/results/variants/candidateSV.vcf.gz", p=pairs),
            "admixture_out/admixture_table.tsv",
            "QC/decoy"
    output:
    params: rname="final"
    shell:  """
             module load multiqc/1.4; multiqc -f -e featureCounts .; mv *.out slurmfiles/; perl Scripts/summarize_usage.pl; rm *realign.bai; mv distance.cluster0 distance.cluster1 distance.cluster2 distance.cluster3 distance.nosex samples.txt plink.map plink.ped logfiles/

            """