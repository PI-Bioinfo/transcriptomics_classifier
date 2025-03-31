process COMBINE_RAW_COUNTS {
    tag "${meta}"
    
    conda '/opt/miniconda/envs/asthma_classifier'

    input:
    val meta
    tuple val(meta_human), path(human_count)
    tuple val(meta_viral), path(viral_count)

    output:
    tuple val(meta), path("*merged_count.csv"),       emit: merged

    script:
    """
    python3 ${projectDir}/bin/merge_raw_counts.py --meta ${meta} --human_count ${human_count} --viral_count ${viral_count}
    """
}