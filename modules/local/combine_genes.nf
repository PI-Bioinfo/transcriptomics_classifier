process COMBINE_GENES {
    tag "${meta}"
    
    conda '/opt/miniconda/envs/asthma_classifier'

    input:
    val meta
    tuple val(meta_human), path(human_top_genes)
    tuple val(meta_viral), path(viral_top_genes)

    output:
    tuple val(meta), path("*merged_genes.csv"),       emit: merged

    script:
    """
    python3 ${projectDir}/bin/merge_genes.py --human_genes ${human_top_genes} --viral_genes ${viral_top_genes}
    """
}