rule maftools_mutect2:
  input: expand(config['project']['workpath']+"/mutect2_out/oncotator_out/{x}.maf",x=pairs),
  output: pre=temp(config['project']['workpath']+"/mutect2_out/oncotator_out/mutect2_variants.maf"),
          fin=config['project']['workpath']+"/mutect2_out/oncotator_out/final_filtered.maf",
          summary=config['project']['workpath']+"/mutect2_out/mutect2_maf_summary.pdf",
          oncoprint=config['project']['workpath']+"/mutect2_out/mutect2_oncoplot.pdf",
  params: dir=config['project']['workpath'],rname="pl:maftools"
  shell: "cat mutect2_out/oncotator_out/*.maf > mutect2_out/oncotator_out/mutect2_variants.maf; perl Scripts/prep_mafs.pl mutect2_out/oncotator_out/mutect2_variants.maf mutect2_out; module load R/3.5; Rscript Scripts/maftools.R {params.dir}/mutect2_out/oncotator_out/ final_filtered.maf {params.dir}/mutect2_out/mutect2_maf_summary.pdf {output.oncoprint}"

rule maftools_mutect:
  input: expand(config['project']['workpath']+"/mutect_out/oncotator_out/{x}.maf",x=pairs),
  output: pre=temp(config['project']['workpath']+"/mutect_out/oncotator_out/mutect_variants.maf"),
          fin=config['project']['workpath']+"/mutect_out/oncotator_out/final_filtered.maf",
          summary=config['project']['workpath']+"/mutect_out/mutect_maf_summary.pdf",
          oncoprint=config['project']['workpath']+"/mutect_out/mutect_oncoplot.pdf",
  params: dir=config['project']['workpath'],rname="pl:maftools"
  shell: "cat mutect_out/oncotator_out/*.maf > mutect_out/oncotator_out/mutect_variants.maf; perl Scripts/prep_mafs.pl mutect_out/oncotator_out/mutect_variants.maf mutect_out; module load R/3.5; Rscript Scripts/maftools.R {params.dir}/mutect_out/oncotator_out/ final_filtered.maf {params.dir}/mutect_out/mutect_maf_summary.pdf {output.oncoprint}"

rule maftools_strelka:
  input: expand(config['project']['workpath']+"/strelka_out/oncotator_out/{x}.maf",x=pairs),
  output: pre=temp(config['project']['workpath']+"/strelka_out/oncotator_out/strelka_variants.maf"),
          fin=config['project']['workpath']+"/strelka_out/oncotator_out/final_filtered.maf",
          summary=config['project']['workpath']+"/strelka_out/strelka_maf_summary.pdf",
          oncoprint=config['project']['workpath']+"/strelka_out/strelka_oncoplot.pdf",
  params: dir=config['project']['workpath'],rname="pl:maftools"
  shell: "cat strelka_out/oncotator_out/*.maf > strelka_out/oncotator_out/strelka_variants.maf; perl Scripts/prep_mafs.pl strelka_out/oncotator_out/strelka_variants.maf strelka_out; module load R/3.5; Rscript Scripts/maftools.R {params.dir}/strelka_out/oncotator_out/ final_filtered.maf {params.dir}/strelka_out/strelka_maf_summary.pdf {output.oncoprint}"

rule maftools_vardict:
  input: expand(config['project']['workpath']+"/vardict_out/oncotator_out/{x}.maf",x=pairs),
  output: pre=temp(config['project']['workpath']+"/vardict_out/oncotator_out/vardict_variants.maf"),
          fin=config['project']['workpath']+"/vardict_out/oncotator_out/final_filtered.maf",
          summary=config['project']['workpath']+"/vardict_out/vardict_maf_summary.pdf",
          oncoprint=config['project']['workpath']+"/vardict_out/vardict_oncoplot.pdf",
  params: dir=config['project']['workpath'],rname="pl:maftools"
  shell: "cat vardict_out/oncotator_out/*.maf > vardict_out/oncotator_out/vardict_variants.maf; perl Scripts/prep_mafs.pl vardict_out/oncotator_out/vardict_variants.maf vardict_out; module load R/3.5; Rscript Scripts/maftools.R {params.dir}/vardict_out/oncotator_out/ final_filtered.maf {params.dir}/vardict_out/vardict_maf_summary.pdf {output.oncoprint}"

rule maftools_merged:
  input: expand(config['project']['workpath']+"/merged_somatic_variants/oncotator_out/{x}.maf",x=pairs),
  output: pre=temp(config['project']['workpath']+"/merged_somatic_variants/oncotator_out/merged_variants.maf"),
          fin=config['project']['workpath']+"/merged_somatic_variants/oncotator_out/final_filtered.maf",
          summary=config['project']['workpath']+"/merged_somatic_variants/merged_maf_summary.pdf",
          oncoprint=config['project']['workpath']+"/merged_somatic_variants/merged_oncoplot.pdf",
  params: dir=config['project']['workpath'],rname="pl:maftools"
  shell: "cat mutect2_out/oncotator_out/*.maf > mutect2_out/oncotator_out/mutect2_variants.maf; perl Scripts/prep_mafs.pl mutect2_out/oncotator_out/mutect2_variants.maf mutect2; module load R/3.5; Rscript Scripts/maftools.R {params.dir}/mutect2_out/oncotator_out/ final_filtered.maf {params.dir}/mutect2_out/mutect2_maf_summary.pdf {output.oncoprint}"