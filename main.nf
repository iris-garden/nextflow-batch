// TODO
// * output file/resource group equivalent?
process GWAS {
    container 'us-docker.pkg.dev/hail-vdc/1kg-gwas:latest'
    cpus 2

    """
    python3 /run_gwas.py \
        --vcf {vcf} \
        --phenotypes {phenotypes} \
        --output-file {g.ofile} \
        --cores {cores}
    """
}

process clump {
    container 'hailgenetics/genetics:0.2.37'

    """
    plink --bfile {bfile} \
        --clump {assoc} \
        --chr {chr} \
        --clump-p1 0.01 \
        --clump-p2 0.01 \
        --clump-r2 0.5 \
        --clump-kb 1000 \
        --memory 1024

    mv plink.clumped {c.clumped}
    """
}

process merge {
    container 'ubuntu:22.04'

    """
    head -n 1 {results[0]} > {merger.ofile}
    for result in {" ".join(results)}
    do
        tail -n +2 "$result" >> {merger.ofile}
    done
    sed -i -e '/^$/d' {merger.ofile}
    """
}

workflow {
    GWAS | clump | merge | view { it.trim() }
}
