process COMBINE_COUNTS {
    tag "${meta}"
    
    conda '/opt/miniconda/envs/asthma_classifier'

    input:
    tuple val(meta), path(human_count)
    tuple val(meta), path(viral_count)

    output:
    tuple val(meta), path("merged_count.csv"),       emit: merged_counts 

    script:
    """
    python3 ${projectDir}/bin/merge_counts.py --human_count ${human_count} --viral_count ${viral_count}
    """
}