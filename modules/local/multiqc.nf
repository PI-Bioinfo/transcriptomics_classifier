process MULTIQC{
    tag "${meta}"

    container "community.wave.seqera.io/library/multiqc:1.27.1--cd23a7c8be3f507b"
    publishDir "result/", mode: 'copy'

    input:


    output:


    script:
    """

    """

}