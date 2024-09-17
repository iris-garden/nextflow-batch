process gwas {
    container "us-docker.pkg.dev/hail-vdc/1kg-gwas:latest"
    cpus { cores }

    input:
    val vcf
    val phenotypes
    val outputPrefix
    val cores

    output:
    path "${outputPrefix}.{bed,bim,fam,assoc}"

    """
    python3 /run_gwas.py \
        --vcf ${vcf} \
        --phenotypes ${phenotypes} \
        --output-file ${outputPrefix} \
        --cores ${cores}
    """
}

process clump {
    tag "${chr}"
    container "hailgenetics/genetics:0.2.37"

    input:
    val chr
    val outputPrefix

    output:
    path "${chr}.clumped"

    """
    plink \
        --bfile ${outputPrefix} \
        --clump ${outputPrefix} \
        --chr ${chr} \
        --clump-p1 0.01 \
        --clump-p2 0.01 \
        --clump-r2 0.5 \
        --clump-kb 1000 \
        --memory 1024 \
        --out ${chr}
    """
}

process merge {
    container "ubuntu:22.04"

    input:
    val outFile

    output:
    path "${outFile}"

    """
    head -n 1 1.clumped > ${outFile}
    for chr in \$(seq 1 23)
    do
        tail -n +2 \$chr.clumped >> ${outFile}
    done
    sed -i -e '/^$/d' ${outFile}
    """
}

workflow {
    inputBucket = "gs://hail-tutorial"
    outputPrefix = "out"
    gwas(
        "${inputBucket}/1kg.vcf.bgz",
        "${inputBucket}/1kg_annotations.txt",
        outputPrefix,
        2
    )
    channel.of(1..23) | { clump(it, outputPrefix) }
    merge("1kg-caffeine-consumption.clumped") | view
}
