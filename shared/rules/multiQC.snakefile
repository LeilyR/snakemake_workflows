
from os import path

def multiqc_input_check(return_value):
    infiles = []
    indir = ""

    if trim:
        infiles.append( expand("FastQC_trimmed/{sample}{read}_fastqc.html", sample = samples, read = reads) )
        indir += " FastQC_trimmed "
        infiles.append( expand(fastq_dir+"/{sample}{read}.fastq.gz", sample = samples, read = reads) )
        indir += fastq_dir + " "
    elif fastqc:
        infiles.append( expand("FastQC/{sample}{read}_fastqc.html", sample = samples, read = reads) )
        indir +=" FastQC "

    if mapping_prg == "Bowtie2":
        # pipeline is DNA-mapping
        infiles.append( expand("Bowtie2/{sample}.Bowtie2_summary.txt", sample = samples) +
                expand("Sambamba/{sample}.markdup.txt", sample = samples) + 
                expand("deepTools_qc/estimateReadFiltering/{sample}_filtering_estimation.txt",sample=samples))
        if paired:
            infiles.append( expand("Picard_qc/InsertSizeMetrics/{sample}.insert_size_metrics.txt", sample = samples) )
        indir += " Picard_qc"
	indir += " Sambamba"
	indir += " Bowtie2"
        indir += " deepTools_qc/estimateReadFiltering"
        if qualimap:
            infiles.append( expand("Qualimap_qc/{sample}.filtered.bamqc_results.txt", sample = samples) )
            indir += " Qualimap_qc "
    else:
        # must be RNA-mapping, add files as per the mode

        if not "mapping-free" in mode:
            infiles.append( expand(mapping_prg+"/{sample}.bam", sample = samples) +
                    expand("Sambamba/{sample}.markdup.txt", sample = samples) +
                    expand("deepTools_qc/estimateReadFiltering/{sample}_filtering_estimation.txt",sample=samples))
            indir += mapping_prg + " featureCounts "
            indir += " Sambamba "
            indir += " deepTools_qc/estimateReadFiltering"
            if "allelic-mapping" in mode:
                infiles.append( expand("featureCounts/{sample}.allelic_counts.txt", sample = samples) )
            else:
                infiles.append( expand("featureCounts/{sample}.counts.txt", sample = samples) )
        else:
            infiles.append( expand("Salmon/{sample}/quant.sf", sample = samples) )
            indir += " Salmon "

    if return_value == "infiles":
        return(infiles)
    else:
        return(indir)

rule multiQC:
    input:
        multiqc_input_check(return_value = "infiles")
    output: "multiQC/multiqc_report.html"
    params:
        indirs = multiqc_input_check(return_value = "indir")
    log: "multiQC/multiQC.log"
    shell:
        multiqc_path+"multiqc -o multiQC -f {params.indirs} &> {log}"
