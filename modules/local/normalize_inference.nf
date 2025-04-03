process NORMALIZE_INFERENCE_COUNT {

    conda '/opt/miniconda/envs/asthma_classifier'

    input:
    tuple val(meta_human), path(count_human)
    tuple val(meta_viral), path(count_viral)

    output:
    tuple val(meta_human), path("*human_cpm.csv")          , emit: human_set
    tuple val(meta_viral), path("*viral_cpm.csv")          , emit: viral_set

    script:
    """
    #!/usr/bin/env Rscript

    suppressMessages(library(edgeR))

    human_inferdata <- read.csv("${count_human}", row.names=1)
    viral_inferdata <- read.csv("${count_viral}", row.names=1)

    htrd_obj <- DGEList(human_inferdata)
    htrd_obj <- calcNormFactors(htrd_obj)
    cpm_htrd <- cpm(htrd_obj)

    vtrd_obj <- DGEList(viral_inferdata)
    vtrd_obj <- calcNormFactors(vtrd_obj)
    cpm_vtrd <- cpm(vtrd_obj)

    # Export CPM count
    write.csv(cpm_htrd, "${meta_human}_cpm.csv", row.names = TRUE)
    write.csv(cpm_vtrd, "${meta_viral}_cpm.csv", row.names = TRUE)
    """
}