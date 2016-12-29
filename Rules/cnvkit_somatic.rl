rule cnvkit_somatic:
    input: normal=lambda wildcards: config['project']['pairs'][wildcards.x][0]+".recal.bam",
           tumor=lambda wildcards: config['project']['pairs'][wildcards.x][1]+".recal.bam",
           targets="cnvkit_targets.bed",
    output: calls="cnvkit_out/{x}_calls.cns",
            gainloss="cnvkit_out/{x}_gainloss.tsv",
            dir="cnvkit_out/{x}_cnvkit"
    params: tumorsample=lambda wildcards: config['project']['pairs'][wildcards.x][1],normalsample=lambda wildcards: config['project']['pairs'][wildcards.x][0],access=config['references'][pfamily]['CNVKITACCESS'],targets="cnvkit_targets.bed",antitargets="cnvkit_antitargets.bed",genome=config['references'][pfamily]['CNVKITGENOME'],rname="pl:cnvkit_somatic"
    shell: "module load cnvkit/0.8.1; mkdir {output.dir}; cnvkit.py coverage {input.tumor} {params.targets} -o {output.dir}/{params.tumorsample}.targetcoverage.cnn; cnvkit.py coverage {input.tumor} {params.antitargets} -o {output.dir}/{params.tumorsample}.antitargetcoverage.cnn; cnvkit.py coverage {input.normal} {params.targets} -o {output.dir}/{params.normalsample}.targetcoverage.cnn; cnvkit.py coverage {input.normal} {params.antitargets} -o {output.dir}/{params.normalsample}.antitargetcoverage.cnn; cnvkit.py reference {output.dir}/{params.normalsample}.targetcoverage.cnn {output.dir}/{params.normalsample}.antitargetcoverage.cnn -f {params.genome} -o {output.dir}/{params.normalsample}.reference.cnn; cnvkit.py fix {output.dir}/{params.tumorsample}.targetcoverage.cnn {output.dir}/{params.tumorsample}.antitargetcoverage.cnn {output.dir}/{params.normalsample}.reference.cnn -o {output.dir}/{params.tumorsample}.cnr; cnvkit.py segment {output.dir}/{params.tumorsample}.cnr -v germline_vcfs/{params.normalsample}.vcf --drop-low-coverage -o {output.dir}/{params.tumorsample}.cns; cnvkit.py scatter {output.dir}/{params.tumorsample}.cnr -s {output.dir}/{params.tumorsample}.cns -v germline_vcfs/{params.normalsample}.vcf -o {output.dir}/{params.tumorsample}.pdf; cnvkit.py call -o {output.calls} {output.dir}/{params.tumorsample}.cns; cnvkit.py gainloss -s {output.dir}/{params.tumorsample}.cns -t 0.3 --drop-low-coverage -o {output.gainloss} {output.dir}/{params.tumorsample}.cnr; cnvkit.py segmetrics -s {output.dir}/{params.tumorsample}.cns --drop-low-coverage -o {output.dir}/{params.tumorsample}.segmetrics --mean --median --mode --stdev --sem --mad --mse --iqr --bivar --ci --pi -b 1000 {output.dir}/{params.tumorsample}.cnr"