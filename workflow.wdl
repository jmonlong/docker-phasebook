version 1.0

workflow phasebook {
    meta {
	    author: "Jean Monlong"
        email: "jmonlong@ucsc.edu"
        description: "Build a phased de novo assembly with Phasebook (https://github.com/phasebook/phasebook)"
    }

    parameter_meta {
        READS_FILES: "Array of sequencing reads. All files should be the same type, e.g. all gzipped FASTQ, or all FASTA."
        PLATFORM: "Platform: ont, hifi, or pb. Default is ont."
        GENOME_SIZE: "Genome size: small or large. Default is large."
        PRESET: "Use preset parameters. Default is True"
    }

    input {
        Array[File] READS_FILES
        String PLATFORM="ont"
        String GENOME_SIZE="large"
        Int MIN_READ_LENGTH=1000
        Boolean PRESET=true
    }
    
    call prepareReads {
        input:
        reads=READS_FILES,
        min_length=MIN_READ_LENGTH
    }

    call overlapReads {
        input:
        reads=prepareReads.filtered_reads
    }

    call runPhasebook {
        input:
        reads=prepareReads.filtered_reads,
        paf=overlapReads.paf,
        platform=PLATFORM,
        genome_size=GENOME_SIZE,
        preset=PRESET
    }

    output {
        File contigs = runPhasebook.contigs
        File log = runPhasebook.log
        File gfa = runPhasebook.gfa
    }
}

task prepareReads {
    input {
        Array[File] reads
        Int min_length = 1000
        Int memSizeGB = 4
        Int threadCount = 2
        String dockerContainer = "quay.io/jmonlong/phasebook:v0.1"
    }

    Int diskSizeGB = 5 * round(size(reads, "GB")) + 50
    
	command <<<
        set -eux -o pipefail

        if [[ ~{select_first(reads)} == *.gz ]]
        then
            zcat ~{sep=" " reads} | python3 /build/phasebook/filterReads.py -l ~{min_length} | gzip > reads.fastx.gz            
        else
            cat ~{sep=" " reads} | python3 /build/phasebook/filterReads.py -l ~{min_length} | gzip > reads.fastx.gz
        fi
	>>>

	output {
		File filtered_reads = "reads.fastx.gz"
	}

    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: dockerContainer
        preemptible: 1
    }
}

task overlapReads {
    input {
        File reads
        Int memSizeGB = 128
        Int threadCount = 96
        String min_ovlp_len = 1000
        String min_identity = 0.75
        String dockerContainer = "quay.io/jmonlong/phasebook:v0.1"
    }

    Int diskSizeGB = 5 * round(size(reads, "GB")) + 50
    
	command <<<
        set -eux -o pipefail

        minimap2 -k 17 -x ava-ont -t ~{threadCount} ~{reads} ~{reads} | \
            cut -f 1-12 |awk '$11 >= ~{min_ovlp_len} && $10/$11 >= ~{min_identity}' | \
            fpa drop -i -m | gzip > out.paf.gz
	>>>

	output {
		File paf = "out.paf.gz"
	}

    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: dockerContainer
        preemptible: 1
    }
}

task runPhasebook {
    input {
        File reads
        File paf
        String platform = "ont"
        String genome_size = "large"
        Boolean preset = true
        Int memSizeGB = 256
        Int threadCount = 96
        Int diskSizeGB = 20 * round(size(paf, "GB") + size(reads, "GB")) + 50
        String dockerContainer = "quay.io/jmonlong/phasebook:v0.1"
    }

    
	command <<<
        set -eux -o pipefail

        zcat ~{paf} > ovl.paf
        
        python /build/phasebook/scripts/phasebook.py -o results -i ~{reads} --rename False --overlaps ovl.paf -t ~{threadCount} -p ~{platform} -g ~{genome_size} ~{true="-x" false="" preset}
	>>>

	output {
		File contigs = "results/contigs.fa"
        File log = "phasebook.log"
        File gfa = "results/4.asm_supereads/graph_trimmed.gfa"
	}

    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: dockerContainer
        preemptible: 1
    }
}
