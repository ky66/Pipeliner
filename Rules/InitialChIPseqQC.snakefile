from snakemake.utils import R
from os.path import join
import re,os

from os import listdir


configfile: "run.json"
    
workpath = config['project']['workpath']    
filetype = config['project']['filetype']
readtype = config['project']['readtype']

se=""
pe=""
workpath = config['project']['workpath']

if config['project']['nends'] == 2 :
    pe="yes"
elif config['project']['nends'] == 1 :
    se="yes"

# extensions = [ "sorted.normalized", "sorted.Q5.normalized", "sorted.DD.normalized", "sorted.Q5DD.normalized"]
extensions = [ "sorted.normalized", "sorted.Q5DD.normalized"]
extensions2 = list(map(lambda x:re.sub(".normalized","",x),extensions))

trim_dir='trim'
kraken_dir='kraken'
bam_dir='bam'
bw_dir='bigwig'
ngsplot_dir='bam'
deeptools_dir='deeptools'
preseq_dir='preseq'

for d in [trim_dir,kraken_dir,bam_dir,bw_dir,ngsplot_dir,deeptools_dir,preseq_dir]:
	if not os.path.exists(join(workpath,d)):
		os.mkdir(join(workpath,d))


# 1 is yes and 0 is no... to remove blacklisted reads after trimming....output file is still ends with trim.fastq.gz
# remove_blacklist_reads=1
# remove_blacklist_reads=0

# trimming method to use
# trim_method=1	# this is trimgalore only ... this is the fastest
# trim_method=2	# this is cutadapt with condensed adapter set... it is NOT followed by afterqc to remove polyX like it was in the past... this is the slowest
# trim_method=3	# this is method1 followed by afterqc and then followed by BBDuk, idea being a) remove most blatant adapter b) remove polyX and then c) remove other primer/adapter contamination
# trim_method=4 # trimmomatic ... leaves traces of adapters at read ends


#print(samples)

if se == 'yes' :
    rule InitialChIPseqQC:
        params: 
            batch='--time=168:00:00'
        input: 
            # Multiqc Report
            join(workpath,"Reports","multiqc_report.html"),
            join(workpath,"rawQC"),
            join(workpath,"QC"),
            # FastqScreen
            expand(join(workpath,"FQscreen","{name}.R1.trim_screen.txt"),name=samples),
            expand(join(workpath,"FQscreen","{name}.R1.trim_screen.png"),name=samples),
            expand(join(workpath,"FQscreen2","{name}.R1.trim_screen.txt"),name=samples),
            expand(join(workpath,"FQscreen2","{name}.R1.trim_screen.png"),name=samples),
            # Trim and remove blacklisted reads
            expand(join(workpath,trim_dir,'{name}.R1.trim.fastq.gz'), name=samples),
            # Kraken
            expand(join(workpath,kraken_dir,"{name}.trim.fastq.kraken_bacteria.taxa.txt"),name=samples),
            expand(join(workpath,kraken_dir,"{name}.trim.fastq.kraken_bacteria.krona.html"),name=samples),
            join(workpath,kraken_dir,"kraken_bacteria.taxa.summary.txt"),
            # Align using BWA and dedup with Picard
            expand(join(workpath,bam_dir,"{name}.{ext}.bam"),name=samples,ext=extensions2),
            # BWA --> BigWig
            expand(join(workpath,bw_dir,"{name}.{ext}.bw",),name=samples,ext=extensions), 
            # PhantomPeakQualTools
            expand(join(workpath,bam_dir,"{name}.{ext}.ppqt"),name=samples,ext=extensions2),
            expand(join(workpath,bam_dir,"{name}.{ext}.pdf"),name=samples,ext=extensions2),
            # ngs.plot
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.tss.max.heatmap.pdf"),name=samples,ext=extensions2),
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.tss.km.heatmap.pdf"),name=samples,ext=extensions2),
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.tes.max.heatmap.pdf"),name=samples,ext=extensions2),
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.tes.km.heatmap.pdf"),name=samples,ext=extensions2),
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.genebody.max.heatmap.pdf"),name=samples,ext=extensions2),
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.genebody.km.heatmap.pdf"),name=samples,ext=extensions2),
            # deeptools
            expand(join(workpath,deeptools_dir,"spearman_heatmap.{ext}.pdf"),ext=extensions),
            expand(join(workpath,deeptools_dir,"pearson_heatmap.{ext}.pdf"),ext=extensions),
            expand(join(workpath,deeptools_dir,"spearman_scatterplot.{ext}.pdf"),ext=extensions),
            expand(join(workpath,deeptools_dir,"pearson_scatterplot.{ext}.pdf"),ext=extensions),
            expand(join(workpath,deeptools_dir,"pca.{ext}.pdf"),ext=extensions),
            # preseq
            expand(join(workpath,preseq_dir,"{name}.ccurve"),name=samples),
            # QC Table
            expand(join(workpath,"QC","{name}.nrf"), name=samples),
            expand(join(workpath,"QC","{name}.qcmetrics"), name=samples),
            join(workpath,"QCTable.txt"),
#         shell: """
# rm -rf {workpath}/*bam.cnt
#             """

                   

    rule fastq_screen:
        input: 
            join(workpath,trim_dir,"{name}.R1.trim.fastq.gz")
        output:
            join(workpath,"FQscreen","{name}.R1.trim_screen.txt"),
            join(workpath,"FQscreen","{name}.R1.trim_screen.png"),
            join(workpath,"FQscreen2","{name}.R1.trim_screen.txt"),
            join(workpath,"FQscreen2","{name}.R1.trim_screen.png"),
        params: 
            rname='pl:fqscreen',
            bowtie2ver=config['bin'][pfamily]['tool_versions']['BOWTIE2VER'],
            perlver=config['bin'][pfamily]['tool_versions']['PERLVER'],
            fastq_screen=config['bin'][pfamily]['tool_versions']['FASTQ_SCREEN'],
            fastq_screen_config=config['bin'][pfamily]['tool_parameters']['FASTQ_SCREEN_CONFIG'], 
            fastq_screen_config2=config['bin'][pfamily]['tool_parameters']['FASTQ_SCREEN_CONFIG2'], 
            outdir = "FQscreen",
            outdir2 = "FQscreen2",
        threads: 24
        shell: """
module load {params.bowtie2ver} ;
module load {params.perlver}; 
{params.fastq_screen} --conf {params.fastq_screen_config} \
    --outdir {params.outdir} --subset 1000000 \
    --aligner bowtie2 --force {input}
{params.fastq_screen} --conf {params.fastq_screen_config2} \
    --outdir {params.outdir2} --subset 1000000 \
    --aligner bowtie2 --force {input}
            """

    rule rawfastqc:
        input: 
            expand(join(workpath,"{name}.R1.fastq.gz"), name=samples), 
        output: 
            join(workpath,'rawQC'),
        priority: 2
        params: 
            rname='pl:rawfastqc',
            batch='--cpus-per-task=32 --mem=100g --time=48:00:00',
            fastqcver=config['bin'][pfamily]['tool_versions']['FASTQCVER']
        threads: 32
        shell: """
if [ ! -d {output} ]; then
mkdir {output};
fi
module load {params.fastqcver}; 
fastqc {input} -t {threads} -o {output}
            """
    
    rule trim: # actually trim, filter polyX and remove black listed reads
        input:
            infq=join(workpath,"{name}.R1.fastq.gz"),
        output:
            outfq=join(workpath,trim_dir,"{name}.R1.trim.fastq.gz"),
        params:
            rname="pl:trim",
            cutadaptver=config['bin'][pfamily]['tool_versions']['CUTADAPTVER'],
            workpath=config['project']['workpath'],
            adaptersfa=config['bin'][pfamily]['tool_parameters']['FASTAWITHADAPTERSETD'],
            blacklistbwaindex=config['references'][pfamily]['BLACKLISTBWAINDEX'],
            picardver=config['bin'][pfamily]['tool_versions']['PICARDVER'],
            bwaver=config['bin'][pfamily]['tool_versions']['BWAVER'],
            parallelver=config['bin'][pfamily]['tool_versions']['PARALLELVER'],
            samtoolsver=config['bin'][pfamily]['tool_versions']['SAMTOOLSVER'],
            minlen=config['bin'][pfamily]['tool_parameters']['MINLEN'],
            javaram="64g",
        threads: 32
        shell: """
module load {params.cutadaptver};
module load {params.parallelver};
if [ ! -e /lscratch/$SLURM_JOBID ]; then mkdir /lscratch/$SLURM_JOBID ;fi
cd /lscratch/$SLURM_JOBID
sample=`echo {input.infq}|awk -F "/" '{{print $NF}}'|awk -F ".R1.fastq" '{{print $1}}'`
cutadapt --nextseq-trim=2 --trim-n -n 5 -O 5 -q 10,10 -m {params.minlen} -b file:{params.adaptersfa} -j {threads} -o ${{sample}}.cutadapt.fastq {input.infq}
module load {params.bwaver};
module load {params.samtoolsver};
module load {params.picardver};
bwa mem -t {threads} {params.blacklistbwaindex} ${{sample}}.cutadapt.fastq | samtools view -@{threads} -f4 -b -o ${{sample}}.bam
java -Xmx{params.javaram} -jar $PICARDJARPATH/picard.jar SamToFastq VALIDATION_STRINGENCY=SILENT INPUT=${{sample}}.bam FASTQ=${{sample}}.cutadapt.noBL.fastq
pigz -p 16 ${{sample}}.cutadapt.noBL.fastq;
mv ${{sample}}.cutadapt.noBL.fastq.gz {output.outfq};
            """

               
    rule kraken_se:
        input:
            fq = join(workpath,trim_dir,"{name}.R1.trim.fastq.gz"),
        output:
            krakentaxa = join(workpath,kraken_dir,"{name}.trim.fastq.kraken_bacteria.taxa.txt"),
            kronahtml = join(workpath,kraken_dir,"{name}.trim.fastq.kraken_bacteria.krona.html"),
        params: 
            rname='pl:kraken',
            # batch='--cpus-per-task=32 --mem=200g --time=48:00:00', # does not work ... just add required resources in cluster.json ... make a new block for this rule there
            prefix="{name}",
            outdir=join(workpath,kraken_dir),
            bacdb=config['bin'][pfamily]['tool_parameters']['KRAKENBACDB'],
            krakenver=config['bin'][pfamily]['tool_versions']['KRAKENVER'],
            kronatoolsver=config['bin'][pfamily]['tool_versions']['KRONATOOLSVER'],
        threads: 32
        shell: """
module load {params.krakenver};
module load {params.kronatoolsver};
cd /lscratch/$SLURM_JOBID;
cp -rv {params.bacdb} /lscratch/$SLURM_JOBID/;
kraken --db /lscratch/$SLURM_JOBID/`echo {params.bacdb}|awk -F "/" '{{print \$NF}}'` --fastq-input --gzip-compressed --threads {threads} --output /lscratch/$SLURM_JOBID/{params.prefix}.krakenout --preload {input.fq}
kraken-translate --mpa-format --db /lscratch/$SLURM_JOBID/`echo {params.bacdb}|awk -F "/" '{{print \$NF}}'` /lscratch/$SLURM_JOBID/{params.prefix}.krakenout |cut -f2|sort|uniq -c|sort -k1,1nr > /lscratch/$SLURM_JOBID/{params.prefix}.krakentaxa
cut -f2,3 {params.prefix}.krakenout | ktImportTaxonomy - -o {params.prefix}.kronahtml
mv /lscratch/$SLURM_JOBID/{params.prefix}.krakentaxa {output.krakentaxa}
mv /lscratch/$SLURM_JOBID/{params.prefix}.kronahtml {output.kronahtml}
            """

    rule process_kraken:
        input:
            fq = expand(join(workpath,trim_dir,"{name}.R1.trim.fastq.gz"),name=samples),
            krakentaxa = expand(join(workpath,kraken_dir,"{name}.trim.fastq.kraken_bacteria.taxa.txt"),name=samples),
        output:
            kraken_taxa_summary = join(workpath,kraken_dir,"kraken_bacteria.taxa.summary.txt"),
        params:
            rname = "pl:krakenProcess",
        run:
            cmd="echo -ne \"Sample\tPercent\tBacteria\n\" > "+output.kraken_taxa_summary
            for f,t in zip(input.fq,input.krakentaxa):
                cmd="sh Scripts/kraken_process_taxa.sh "+f+" "+t+" >> "+output.kraken_taxa_summary
                shell(cmd)

    rule fastqc:  
        params:
            rname='pl:fastqc',
            batch='--cpus-per-task=32 --mem=110g --time=48:00:00',
            fastqcver=config['bin'][pfamily]['tool_versions']['FASTQCVER']
        input:
            expand(join(workpath,trim_dir,"{name}.R1.trim.fastq.gz"),name=samples),
        output: join(workpath,"QC")
        priority: 2
        threads: 32
        shell: 
            """
mkdir -p {output};
module load {params.fastqcver}; 
fastqc {input} -t {threads} -o {output}
            """

    rule BWA:
        input:
            infq=join(workpath,trim_dir,"{name}.R1.trim.fastq.gz"),
        params:
            d=join(workpath,bam_dir),
            rname='pl:bwa',
            reference=config['references'][pfamily]['BWA'],
            reflen=config['references'][pfamily]['REFLEN'],
            bwaver=config['bin'][pfamily]['tool_versions']['BWAVER'],
            samtoolsver=config['bin'][pfamily]['tool_versions']['SAMTOOLSVER'],
        output:
            outbam1=join(workpath,bam_dir,"{name}.sorted.bam"), 
            outbam2=temp(join(workpath,bam_dir,"{name}.sorted.Q5.bam")),
            flagstat1=join(workpath,bam_dir,"{name}.sorted.bam.flagstat"),
            flagstat2=join(workpath,bam_dir,"{name}.sorted.Q5.bam.flagstat"),
        threads: 32
        shell: """
module load {params.bwaver};
module load {params.samtoolsver};
bwa mem -t {threads} {params.reference} {input.infq} | \
samtools sort -@{threads} -o {output.outbam1}
samtools index {output.outbam1}
samtools flagstat {output.outbam1} > {output.flagstat1}
samtools view -b -q 6 {output.outbam1} -o {output.outbam2}
samtools index {output.outbam2}
samtools flagstat {output.outbam2} > {output.flagstat2}
            """  
                

    rule shiftstats:
        input: 
            if1 = "{name}.sorted.bam",
            if2 = "{name}.sorted.rmdup.bam" 
        output:
            of1 = "{name}.shifts",
            of2 = "{name}.rmdup.shifts"
        params:
            rname='pl:shiftstats',
            batch='--mem=24g --time=10:00:00 --gres=lscratch:800'
        shell: 
             """
             touch {output.of1}
             touch {output.of2}
             """

    rule stats:
        input:
            file1= join(workpath,bam_dir,"{name}.bwa_rg_added.sorted.dmark.bam"),
        output:
            outstar2=join(workpath,bam_dir,"{name}.flagstat.concord.txt"),
        params: 
            rname='pl:stats',
            batch='--mem=24g --time=10:00:00 --gres=lscratch:800',
            picardver=config['bin'][pfamily]['PICARDVER'],
        shell:
            """
            module load samtools/1.6; 
            samtools flagstat {input.file1} > {output.outstar2}; 
            echo 0 >> {output.outstar2};
            echo 0 >> {output.outstar2};
            #samtools view -f 0x2 {input.file1} | wc -l >>{output.outstar2}; 
            #samtools view {input.file1} | grep -w -c NH:i:1  >>{output.outstar2}
            """

    rule ppqt:
	    input:
		    bam1= join(workpath,bam_dir,"{name}.sorted.bam"),
		    bam4= join(workpath,bam_dir,"{name}.sorted.Q5DD.bam"),
	    output:
		    ppqt1= join(workpath,bam_dir,"{name}.sorted.ppqt"),
		    pdf1= join(workpath,bam_dir,"{name}.sorted.pdf"),
		    ppqt4= join(workpath,bam_dir,"{name}.sorted.Q5DD.ppqt"),
		    pdf4= join(workpath,bam_dir,"{name}.sorted.Q5DD.pdf"),
	    params:
		    rname="pl:ppqt",
		    batch='--mem=24g --time=10:00:00 --gres=lscratch:800',
		    samtoolsver=config['bin'][pfamily]['tool_versions']['SAMTOOLSVER'],
		    rver=config['bin'][pfamily]['tool_versions']['RVER'],
	    shell:
		    """
module load {params.samtoolsver};
module load {params.rver};
Rscript Scripts/phantompeakqualtools/run_spp.R \
-c={input.bam1} -savp={output.pdf1} -out={output.ppqt1} -tmpdir=/lscratch/$SLURM_JOBID -rf
Rscript Scripts/phantompeakqualtools/run_spp.R \
-c={input.bam4} -savp={output.pdf4} -out={output.ppqt4} -tmpdir=/lscratch/$SLURM_JOBID -rf
		"""

            
if pe == 'yes':
    rule InitialChIPseqQC:
        params: 
            batch='--time=168:00:00'
        input: 
            # Multiqc Report
            join(workpath,"Reports","multiqc_report.html"),
            join(workpath,"rawQC"),
            join(workpath,"QC"),
            # FastqScreen
            expand(join(workpath,"FQscreen","{name}.R{rn}.trim_screen.txt"),name=samples,rn=[1,2]),
            expand(join(workpath,"FQscreen","{name}.R{rn}.trim_screen.png"),name=samples,rn=[1,2]),
            expand(join(workpath,"FQscreen2","{name}.R{rn}.trim_screen.txt"),name=samples,rn=[1,2]),
            expand(join(workpath,"FQscreen2","{name}.R{rn}.trim_screen.png"),name=samples,rn=[1,2]),
            	# Trim and remove blacklisted reads
            expand(join(workpath,trim_dir,'{name}.R{rn}.trim.fastq.gz'), name=samples,rn=[1,2]),
            # Kraken
            expand(join(workpath,kraken_dir,"{name}.trim.fastq.kraken_bacteria.taxa.txt"),name=samples),
            expand(join(workpath,kraken_dir,"{name}.trim.fastq.kraken_bacteria.krona.html"),name=samples),
            # join(workpath,kraken_dir,"kraken_bacteria.taxa.summary.txt"),
            # Align using BWA and dedup with Picard
            expand(join(workpath,bam_dir,"{name}.{ext}.bam"),name=samples,ext=extensions2),
            # BWA --> BigWig
            expand(join(workpath,bw_dir,"{name}.{ext}.bw",),name=samples,ext=extensions), 
            # PhantomPeakQualTools
            expand(join(workpath,bam_dir,"{name}.{ext}.ppqt"),name=samples,ext=extensions2),
            expand(join(workpath,bam_dir,"{name}.{ext}.pdf"),name=samples,ext=extensions2),
            # ngs.plot
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.tss.max.heatmap.pdf"),name=samples,ext=extensions2),
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.tss.km.heatmap.pdf"),name=samples,ext=extensions2),
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.tes.max.heatmap.pdf"),name=samples,ext=extensions2),
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.tes.km.heatmap.pdf"),name=samples,ext=extensions2),
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.genebody.max.heatmap.pdf"),name=samples,ext=extensions2),
            # expand(join(workpath,ngsplot_dir,"{name}.{ext}.genebody.km.heatmap.pdf"),name=samples,ext=extensions2),
            # deeptools
            expand(join(workpath,deeptools_dir,"spearman_heatmap.{ext}.pdf"),ext=extensions),
            expand(join(workpath,deeptools_dir,"pearson_heatmap.{ext}.pdf"),ext=extensions),
            expand(join(workpath,deeptools_dir,"spearman_scatterplot.{ext}.pdf"),ext=extensions),
            expand(join(workpath,deeptools_dir,"pearson_scatterplot.{ext}.pdf"),ext=extensions),
            expand(join(workpath,deeptools_dir,"pca.{ext}.pdf"),ext=extensions),
            # preseq
            expand(join(workpath,preseq_dir,"{name}.ccurve"),name=samples),
            # QC Table
            expand(join(workpath,"QC","{name}.nrf"), name=samples),
            expand(join(workpath,"QC","{name}.qcmetrics"), name=samples),
            join(workpath,"QCTable.txt"),
#         shell: """
# rm -rf {workpath}/*.bam.cnt
# """

    rule rawfastqc:
        input: 
            expand(join(workpath,"{name}.R{rn}.fastq.gz"), name=samples,rn=[1,2]), 
        output: 
            join(workpath,"rawQC")
        priority: 2
        params: 
            rname='pl:rawfastqc',
            batch='--cpus-per-task=32 --mem=110g --time=48:00:00',
            fastqcver=config['bin'][pfamily]['tool_versions']['FASTQCVER'],
        threads: 32
        shell: """
mkdir -p {output};
module load {params.fastqcver};
fastqc {input} -t {threads} -o {output}; 
        """
    
    rule trim: # trim, remove PolyX and remove BL reads
        input:
            file1=join(workpath,"{name}.R1.fastq.gz"),
            file2=join(workpath,"{name}.R2.fastq.gz"),
        output:
            outfq1=join(workpath,trim_dir,"{name}.R1.trim.fastq.gz"),
            outfq2=join(workpath,trim_dir,"{name}.R2.trim.fastq.gz"),
        params:
            rname="pl:trim",
            cutadaptver=config['bin'][pfamily]['tool_versions']['CUTADAPTVER'],
            workpath=config['project']['workpath'],
            fastawithadaptersetd=config['bin'][pfamily]['tool_parameters']['FASTAWITHADAPTERSETD'],
            blacklistbwaindex=config['references'][pfamily]['BLACKLISTBWAINDEX'],
            picardver=config['bin'][pfamily]['tool_versions']['PICARDVER'],
            parallelver=config['bin'][pfamily]['tool_versions']['PARALLELVER'],
            bwaver=config['bin'][pfamily]['tool_versions']['BWAVER'],
            samtoolsver=config['bin'][pfamily]['tool_versions']['SAMTOOLSVER'],
            minlen=config['bin'][pfamily]['tool_parameters']['MINLEN'],
            javaram="64g",
        threads: 32
        shell: """
module load {params.cutadaptver};
module load {params.parallelver};
if [ ! -e /lscratch/$SLURM_JOBID ]; then mkdir /lscratch/$SLURM_JOBID ;fi
cd /lscratch/$SLURM_JOBID
sample=`echo {input.file1}|awk -F "/" '{{print $NF}}'|awk -F ".R1.fastq" '{{print $1}}'`
cutadapt --pair-filter=both --nextseq-trim=2 --trim-n -n 5 -O 5 -q 10,10 -m {params.minlen}:{params.minlen} -b file:{params.fastawithadaptersetd} -B file:{params.fastawithadaptersetd} -j {threads} -o ${{sample}}.R1.cutadapt.fastq -p ${{sample}}.R2.cutadapt.fastq {input.file1} {input.file2}
module load {params.bwaver};
module load {params.samtoolsver};
module load {params.picardver};
bwa mem -t {threads} {params.blacklistbwaindex} ${{sample}}.R1.cutadapt.fastq ${{sample}}.R2.cutadapt.fastq | samtools view -@{threads} -f4 -b -o ${{sample}}.bam
java -Xmx{params.javaram} -jar $PICARDJARPATH/picard.jar SamToFastq \
VALIDATION_STRINGENCY=SILENT \
INPUT=${{sample}}.bam \
FASTQ=${{sample}}.R1.cutadapt.noBL.fastq \
SECOND_END_FASTQ=${{sample}}.R2.cutadapt.noBL.fastq \
UNPAIRED_FASTQ=${{sample}}.unpaired.noBL.fastq
pigz -p 16 ${{sample}}.R1.cutadapt.noBL.fastq;
pigz -p 16 ${{sample}}.R2.cutadapt.noBL.fastq;
mv /lscratch/$SLURM_JOBID/${{sample}}.R1.cutadapt.noBL.fastq.gz {output.outfq1};
mv /lscratch/$SLURM_JOBID/${{sample}}.R2.cutadapt.noBL.fastq.gz {output.outfq2};
"""

    rule fastqc:
        input: 
            expand(join(workpath,trim_dir,"{name}.R{rn}.trim.fastq.gz"), name=samples,rn=[1,2]), 
        output: 
            join(workpath,"QC")
        priority: 2
        params: 
            rname='pl:rawfastqc',
            batch='--cpus-per-task=32 --mem=110g --time=48:00:00',
            fastqcver=config['bin'][pfamily]['tool_versions']['FASTQCVER'],
        threads: 32
        shell: """
mkdir -p {output};
module load {params.fastqcver};
fastqc {input} -t {threads} -o {output}; 
        """

    rule fastq_screen:
        input: 
            infq1 = join(workpath,trim_dir,"{name}.R1.trim.fastq.gz"),
            infq2 = join(workpath,trim_dir,"{name}.R2.trim.fastq.gz"),
        output:
            join(workpath,"FQscreen","{name}.R1.trim_screen.txt"),
            join(workpath,"FQscreen","{name}.R1.trim_screen.png"),
            join(workpath,"FQscreen","{name}.R2.trim_screen.txt"),
            join(workpath,"FQscreen","{name}.R2.trim_screen.png"),
            join(workpath,"FQscreen2","{name}.R1.trim_screen.txt"),
            join(workpath,"FQscreen2","{name}.R1.trim_screen.png"),
            join(workpath,"FQscreen2","{name}.R2.trim_screen.txt"),
            join(workpath,"FQscreen2","{name}.R2.trim_screen.png"),
        params: 
            rname='pl:fqscreen',
            bowtie2ver=config['bin'][pfamily]['tool_versions']['BOWTIE2VER'],
            perlver=config['bin'][pfamily]['tool_versions']['PERLVER'],
            fastq_screen=config['bin'][pfamily]['tool_versions']['FASTQ_SCREEN'],
            fastq_screen_config=config['bin'][pfamily]['tool_parameters']['FASTQ_SCREEN_CONFIG'], 
            outdir = "FQscreen",
            fastq_screen_config2=config['bin'][pfamily]['tool_parameters']['FASTQ_SCREEN_CONFIG2'], 
            outdir2 = "FQscreen2",
        threads: 24
        shell: """
module load {params.bowtie2ver} ;
module load {params.perlver}; 
{params.fastq_screen} --conf {params.fastq_screen_config} \
    --outdir {params.outdir} --subset 1000000 \
    --aligner bowtie2 --force {input.infq1}
{params.fastq_screen} --conf {params.fastq_screen_config} \
    --outdir {params.outdir} --subset 1000000 \
    --aligner bowtie2 --force {input.infq2}
{params.fastq_screen} --conf {params.fastq_screen_config2} \
    --outdir {params.outdir2} --subset 1000000 \
    --aligner bowtie2 --force {input.infq1}
{params.fastq_screen} --conf {params.fastq_screen_config2} \
    --outdir {params.outdir2} --subset 1000000 \
    --aligner bowtie2 --force {input.infq2}
            """


    rule kraken_pe:
        input:
            fq1 = rules.trim.output.outfq1,
            fq2 = rules.trim.output.outfq2,
        output:
            krakentaxa = join(workpath,kraken_dir,"{name}.trim.fastq.kraken_bacteria.taxa.txt"),
            kronahtml = join(workpath,kraken_dir,"{name}.trim.fastq.kraken_bacteria.krona.html"),
        params: 
            rname='pl:kraken',
            # batch='--cpus-per-task=32 --mem=200g --time=48:00:00', # does not work ... just add required resources in cluster.json ... make a new block for this rule there
            prefix="{name}",
            outdir=join(workpath,kraken_dir),
            bacdb=config['bin'][pfamily]['tool_parameters']['KRAKENBACDB'],
            krakenver=config['bin'][pfamily]['tool_versions']['KRAKENVER'],
            kronatoolsver=config['bin'][pfamily]['tool_versions']['KRONATOOLSVER'],
        threads: 32
        shell: """
module load {params.krakenver};
module load {params.kronatoolsver};
if [ ! -d {params.outdir} ];then mkdir {params.outdir};fi
cd /lscratch/$SLURM_JOBID;
cp -rv {params.bacdb} /lscratch/$SLURM_JOBID/;
kraken --db /lscratch/$SLURM_JOBID/`echo {params.bacdb}|awk -F "/" '{{print \$NF}}'` --fastq-input --gzip-compressed --threads {threads} --output /lscratch/$SLURM_JOBID/{params.prefix}.krakenout --preload --paired {input.fq1} {input.fq2}
kraken-translate --mpa-format --db /lscratch/$SLURM_JOBID/`echo {params.bacdb}|awk -F "/" '{{print \$NF}}'` /lscratch/$SLURM_JOBID/{params.prefix}.krakenout |cut -f2|sort|uniq -c|sort -k1,1nr > /lscratch/$SLURM_JOBID/{params.prefix}.krakentaxa
cut -f2,3 /lscratch/$SLURM_JOBID/{params.prefix}.krakenout | ktImportTaxonomy - -o /lscratch/$SLURM_JOBID/{params.prefix}.kronahtml
mv /lscratch/$SLURM_JOBID/{params.prefix}.krakentaxa {output.krakentaxa}
mv /lscratch/$SLURM_JOBID/{params.prefix}.kronahtml {output.kronahtml}
"""

    rule BWA:
        input:
            infq1 = rules.trim.output.outfq1,
            infq2 = rules.trim.output.outfq2,
        params:
            d=join(workpath,bam_dir),
            rname='pl:bwa',
            reference=config['references'][pfamily]['BWA'],
            reflen=config['references'][pfamily]['REFLEN'],
            bwaver=config['bin'][pfamily]['tool_versions']['BWAVER'],
            samtoolsver=config['bin'][pfamily]['tool_versions']['SAMTOOLSVER'],
        output:
            outbam1=join(workpath,bam_dir,"{name}.sorted.bam"), 
            outbam2=temp(join(workpath,bam_dir,"{name}.sorted.Q5.bam")),
            flagstat1=join(workpath,bam_dir,"{name}.sorted.bam.flagstat"),
            flagstat2=join(workpath,bam_dir,"{name}.sorted.Q5.bam.flagstat"),
        threads: 32
        shell: """
module load {params.bwaver};
module load {params.samtoolsver};
bwa mem -t {threads} {params.reference} {input.infq1} {input.infq2} | \
samtools sort -@{threads} -o {output.outbam1}
samtools index {output.outbam1}
samtools flagstat {output.outbam1} > {output.flagstat1}
samtools view -b -q 6 {output.outbam1} -o {output.outbam2}
samtools index {output.outbam2}
samtools flagstat {output.outbam2} > {output.flagstat2}
            """  

    rule ppqt:
	    input:
		    bam1= join(workpath,bam_dir,"{name}.sorted.bam"),
		    bam4= join(workpath,bam_dir,"{name}.sorted.Q5DD.bam"),
	    output:
		    ppqt1= join(workpath,bam_dir,"{name}.sorted.ppqt"),
		    pdf1= join(workpath,bam_dir,"{name}.sorted.pdf"),
		    ppqt4= join(workpath,bam_dir,"{name}.sorted.Q5DD.ppqt"),
		    pdf4= join(workpath,bam_dir,"{name}.sorted.Q5DD.pdf"),
	    params:
		    rname="pl:ppqt",
		    batch='--mem=24g --time=10:00:00 --gres=lscratch:800',
		    samtoolsver=config['bin'][pfamily]['tool_versions']['SAMTOOLSVER'],
		    rver=config['bin'][pfamily]['tool_versions']['RVER'],
	    shell:
		    """
module load {params.samtoolsver};
module load {params.rver};
samtools view -b -f 66 -o /lscratch/$SLURM_JOBID/bam1.f66.bam {input.bam1}
samtools index /lscratch/$SLURM_JOBID/bam1.f66.bam
Rscript Scripts/phantompeakqualtools/run_spp.R \
-c=/lscratch/$SLURM_JOBID/bam1.f66.bam -savp={output.pdf1} -out={output.ppqt1} -tmpdir=/lscratch/$SLURM_JOBID -rf
samtools view -b -f 66 -o /lscratch/$SLURM_JOBID/bam4.f66.bam {input.bam4}
samtools index /lscratch/$SLURM_JOBID/bam4.f66.bam
Rscript Scripts/phantompeakqualtools/run_spp.R \
-c=/lscratch/$SLURM_JOBID/bam4.f66.bam -savp={output.pdf4} -out={output.ppqt4} -tmpdir=/lscratch/$SLURM_JOBID -rf
		"""


rule picard_dedup:
    input: 
        bam2=join(workpath,bam_dir,"{name}.sorted.Q5.bam")
    output:
        out4=temp(join(workpath,bam_dir,"{name}.bwa_rg_added.sorted.Q5.bam")), 
        out5=join(workpath,bam_dir,"{name}.sorted.Q5DD.bam"),
        out5f=join(workpath,bam_dir,"{name}.sorted.Q5DD.bam.flagstat"),
        out6=join(workpath,bam_dir,"{name}.bwa.Q5.duplic"), 
    params:
        rname='pl:dedup',
        batch='--mem=98g --time=10:00:00 --gres=lscratch:800',
        picardver=config['bin'][pfamily]['tool_versions']['PICARDVER'],
        samtoolsver=config['bin'][pfamily]['tool_versions']['SAMTOOLSVER'],
        javaram='96g',
    shell: 
            """
module load {params.samtoolsver};
module load {params.picardver}; 
java -Xmx{params.javaram} \
  -jar $PICARDJARPATH/picard.jar AddOrReplaceReadGroups \
  INPUT={input.bam2} \
  OUTPUT={output.out4} \
  TMP_DIR=/lscratch/$SLURM_JOBID \
  RGID=id \
  RGLB=library \
  RGPL=illumina \
  RGPU=machine \
  RGSM=sample; 
java -Xmx{params.javaram} \
  -jar $PICARDJARPATH/picard.jar MarkDuplicates \
  INPUT={output.out4} \
  OUTPUT={output.out5} \
  TMP_DIR=/lscratch/$SLURM_JOBID \
  VALIDATION_STRINGENCY=SILENT \
  REMOVE_DUPLICATES=true \
  METRICS_FILE={output.out6}
samtools index {output.out5}
samtools flagstat {output.out5} > {output.out5f}
            """

                                    
rule bam2bw:
    input:
        bam1= join(workpath,bam_dir,"{name}.sorted.bam"),
        bam4= join(workpath,bam_dir,"{name}.sorted.Q5DD.bam"),
    output:
        outbw1=join(workpath,bw_dir,"{name}.sorted.normalized.bw"), 
        outbw4=join(workpath,bw_dir,"{name}.sorted.Q5DD.normalized.bw"),
    params:
        rname="pl:bam2bw",
        batch='--mem=24g --time=10:00:00 --gres=lscratch:800',
        reflen=config['references'][pfamily]['REFLEN'],
        deeptoolsver=config['bin'][pfamily]['tool_versions']['DEEPTOOLSVER'],
    run:
        lines=list(map(lambda x:x.strip().split("\t"),open(params.reflen).readlines()))
        genomelen=0
        chrs=[]
        includedchrs=[]
        excludedchrs=[]
        for chrom,l in lines:
            chrs.append(chrom)
            if not "_" in chrom and chrom!="chrX" and chrom!="chrM" and chrom!="chrY":
                includedchrs.append(chrom)
                genomelen+=int(l)
        excludedchrs=list(set(chrs)-set(includedchrs))
        commoncmd="module load {params.deeptoolsver};"
        cmd1="bamCoverage --bam "+input.bam1+" -o "+output.outbw1+" --binSize 2 --smoothLength 5 --ignoreForNormalization "+" ".join(excludedchrs)+" --numberOfProcessors 32 --normalizeUsing RPGC --effectiveGenomeSize "+str(genomelen)
        shell(commoncmd+cmd1)
        cmd4="bamCoverage --bam "+input.bam4+" -o "+output.outbw4+" --binSize 2 --smoothLength 5 --ignoreForNormalization "+" ".join(excludedchrs)+" --numberOfProcessors 32 --normalizeUsing RPGC --effectiveGenomeSize "+str(genomelen)
        if pe=="yes":
            cmd4+=" --centerReads"
        shell(commoncmd+cmd4)

rule deeptools_prep:
    input:
        expand(join(workpath,bw_dir,"{name}.{ext}.bw"),name=samples,ext=extensions),
    output:
        expand(join(workpath,bw_dir,"{ext}.deeptools_prep"),ext=extensions),
    params:
        rname="pl:deeptools_prep",
        batch="--mem=10g --time=1:00:00",
    threads: 1
    run:
        for x in extensions:
            bws=list(filter(lambda z:z.endswith(x+".bw"),input))
            labels=list(map(lambda z:re.sub("."+x+".bw","",z),list(map(lambda z:os.path.basename(z),bws))))
            o=open(join(workpath,bw_dir,x+".deeptools_prep"),'w')
            o.write("%s\n"%(x))
            o.write("%s\n"%(" ".join(bws)))
            o.write("%s\n"%(" ".join(labels)))
            o.close()            

            

rule deeptools:
    input:
        join(workpath,bw_dir,"{ext}.deeptools_prep"),
    output:
        join(workpath,deeptools_dir,"spearman_heatmap.{ext}.pdf"),
        join(workpath,deeptools_dir,"pearson_heatmap.{ext}.pdf"),
        join(workpath,deeptools_dir,"spearman_scatterplot.{ext}.pdf"),
        join(workpath,deeptools_dir,"pearson_scatterplot.{ext}.pdf"),
        join(workpath,deeptools_dir,"pca.{ext}.pdf"),        
    params:
        rname="pl:deeptools",
        deeptoolsver=config['bin'][pfamily]['tool_versions']['DEEPTOOLSVER'],
    threads: 32
    run:
        import re
        commoncmd="module load {params.deeptoolsver}; module load python;"
        listfile=list(map(lambda z:z.strip().split(),open(input[0],'r').readlines()))
        ext=listfile[0][0]
        bws=listfile[1]
        labels=listfile[2]
        cmd="multiBigwigSummary bins -b "+" ".join(bws)+" -l "+" ".join(labels)+" -out "+join(deeptools_dir,ext+".npz")
        shell(commoncmd+cmd)
        for cm in ["spearman", "pearson"]:
            for pt in ["heatmap", "scatterplot"]:
                cmd="plotCorrelation -in "+join(deeptools_dir,ext+".npz")+" -o "+join(deeptools_dir,cm+"_"+pt+"."+ext+".pdf")+" -c "+cm+" -p "+pt+" --skipZeros --removeOutliers"
                if pt=="heatmap":
                    cmd+=" --plotNumbers"
                shell(commoncmd+cmd)
        cmd="plotPCA -in "+join(deeptools_dir,ext+".npz")+" -o "+join(deeptools_dir,"pca."+ext+".pdf")
        shell(commoncmd+cmd)
        shell("rm -rf "+input[0])

rule NGSPLOT:
    input:
        bam= join(workpath,bam_dir,"{name}.bam"),
    output:
        tssmax=join(workpath,ngsplot_dir,"{name}.tss.max.heatmap.pdf"),
        tsskm=join(workpath,ngsplot_dir,"{name}.tss.km.heatmap.pdf"),
        tesmax=join(workpath,ngsplot_dir,"{name}.tes.max.heatmap.pdf"),
        teskm=join(workpath,ngsplot_dir,"{name}.tes.km.heatmap.pdf"),
        genebodymax=join(workpath,ngsplot_dir,"{name}.genebody.max.heatmap.pdf"),
        genebodykm=join(workpath,ngsplot_dir,"{name}.genebody.km.heatmap.pdf"),
    params:
        rname="pl:ngsplot",
        batch='--mem=48g --time=10:00:00 --gres=lscratch:800',
        genome = config['project']['annotation'],
        ngsplotver = config['bin'][pfamily]['tool_versions']['NGSPLOTVER'],
    threads: 32
    shell:
        """
        sh Scripts/plotngsplot.sh {params.ngsplotver} {input.bam} {params.genome}
        """               


rule preseq:
    params:
        rname = "pl:preseq",
        preseqver=config['bin'][pfamily]['tool_versions']['PRESEQVER'],
    input:
        bam = join(workpath,bam_dir,"{name}.sorted.bam"),
    output:
        ccurve = join(workpath,preseq_dir,"{name}.ccurve"),
    shell:
        """
module load {params.preseqver};
preseq c_curve -B -o {output.ccurve} {input.bam}            
        """
rule NRF:
    input:
        bam=join(workpath,bam_dir,"{name}.sorted.bam"),
    params:
        rname='pl:NRF',
        samtoolsver=config['bin'][pfamily]['tool_versions']['SAMTOOLSVER'],
        rver=config['bin'][pfamily]['tool_versions']['RVER'],
        preseqver=config['bin'][pfamily]['tool_versions']['PRESEQVER'],
        nrfscript=join(workpath,"Scripts","atac_nrf.py "),            

    output:
        preseq=join(workpath,"QC","{name}.preseq.dat"),
        preseqlog=join(workpath,"QC","{name}.preseq.log"),
        nrf=join(workpath,"QC","{name}.nrf"),
    threads: 16
    shell: """
module load {params.preseqver};

preseq lc_extrap -P -B -o {output.preseq} {input.bam} -seed 12345 -v -l 100000000000 2> {output.preseqlog}
python {params.nrfscript} {output.preseqlog} > {output.nrf}
        """

rule QCstats:
    input:
        flagstat=join(workpath,bam_dir,"{name}.sorted.bam.flagstat"),
        infq=join(workpath,"{name}.R1.fastq.gz"),	
        ddflagstat=join(workpath,bam_dir,"{name}.sorted.Q5DD.bam.flagstat"),
        nrf=join(workpath,"QC","{name}.nrf"),
        ppqt=join(workpath,bam_dir,"{name}.sorted.Q5DD.ppqt"),
    params:
        rname='pl:QCstats',
        filterCollate=join(workpath,"Scripts","filterMetrics"),   

    output:
        sampleQCfile=join(workpath,"QC","{name}.qcmetrics"),
    threads: 16
    shell: """
# Number of reads
#grep 'in total' {input.flagstat} | awk '{{print $1,$3}}' | {params.filterCollate} {wildcards.name} tnreads > {output.sampleQCfile}
zcat {input.infq} | wc -l | {params.filterCollate} {wildcards.name} tnreads > {output.sampleQCfile}
# Number of mapped reads
grep 'mapped (' {input.flagstat} | awk '{{print $1,$3}}' | {params.filterCollate} {wildcards.name} mnreads >> {output.sampleQCfile}
# Number of uniquely mapped reads
grep 'mapped (' {input.ddflagstat} | awk '{{print $1,$3}}' | {params.filterCollate} {wildcards.name} unreads >> {output.sampleQCfile}
# NRF, PCB1, PCB2
cat {input.nrf} | {params.filterCollate} {wildcards.name} nrf >> {output.sampleQCfile}
# NSC, RSC, Qtag
awk '{{print $(NF-2),$(NF-1),$NF}}' {input.ppqt} | {params.filterCollate} {wildcards.name} ppqt >> {output.sampleQCfile}
            """

rule QCTable:
    input:
        expand(join(workpath,"QC","{name}.qcmetrics"), name=samples),
    params:
        rname='pl:QCTable',
        inputstring=" ".join(expand(join(workpath,"QC","{name}.qcmetrics"), name=samples)),
        filterCollate=join(workpath,"Scripts","createtable"),

    output:
        qctable=join(workpath,"QCTable.txt"),
    threads: 16
    shell: """
cat {params.inputstring} | {params.filterCollate} > {output.qctable}
            """

rule multiqc:
    input: 
        expand(join(workpath,bam_dir,"{name}.bwa.Q5.duplic"), name=samples),
        expand(join(workpath,"FQscreen","{name}.R1.trim_screen.txt"),name=samples),
        expand(join(workpath,preseq_dir,"{name}.ccurve"), name=samples),
        expand(join(workpath,bam_dir,"{name}.sorted.Q5DD.bam.flagstat"), name=samples),
        expand(join(workpath,bam_dir,"{name}.sorted.Q5.bam.flagstat"), name=samples),
        join(workpath,"QCTable.txt"),
        join(workpath,"rawQC"),
        join(workpath,"QC"),         
    output:
        join(workpath,"Reports","multiqc_report.html")
    params:
        rname="pl:multiqc",
        multiqc=config['bin'][pfamily]['tool_versions']['MULTIQCVER'],
	qcconfig=config['bin'][pfamily]['CONFMULTIQC'],
    threads: 1
    shell: """
module load {params.multiqc}
cd Reports && multiqc -f -c {params.qcconfig} --interactive -e cutadapt -d ../
"""


