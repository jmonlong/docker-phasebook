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
    
    call runPhasebook {
        input:
        reads=READS_FILES,
        platform=PLATFORM,
        genome_size=GENOME_SIZE,
        min_length=MIN_READ_LENGTH,
        preset=PRESET
    }

    output {
        File contigs = runPhasebook.contigs
        File log = runPhasebook.log
        File gfa = runPhasebook.gfa
    }
}

task runPhasebook {
    input {
        Array[File] reads
        String platform = "ont"
        String genome_size = "large"
        Int min_length = 1000
        Boolean preset = true
        Int memSizeGB = 64
        Int threadCount = 16
        String dockerContainer = "quay.io/jmonlong/phasebook:latest"
    }

    Int diskSizeGB = 10 * round(size(reads, "GB")) + 50
    
	command <<<
        # Set the exit code of a pipeline to that of the rightmost command
        # to exit with a non-zero status, or zero if all commands of the pipeline exit
        set -o pipefail
        # cause a bash script to exit immediately when a command fails
        set -e
        # cause the bash shell to treat unset variables as an error and exit immediately
        set -u
        # echo each line of the script to stdout so we can see what is happening
        # to turn off echo do 'set +o xtrace'
        set -o xtrace

        ## merge reads
        READS=reads.fastx
        if [[ ~{select_first(reads)} == *.gz ]]
        then
            READS=reads.fastx.gz
        fi
        cat ~{sep=" " reads} > $READS
        
        python /build/phasebook/scripts/phasebook.py -i $READS -t ~{threadCount} -p ~{platform} -g ~{genome_size} --min_read_len ~{min_length} ~{true="-x" false="" preset}
	>>>

	output {
		File contigs = "contigs.fa"
        File log = "phasebook.log"
        File gfa = "4.asm_supereads/graph_trimmed.gfa"
	}

    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: dockerContainer
        preemptible: 1
    }
}
