process NORMALIZE_COMBINE_COUNT {

    conda '/opt/miniconda/envs/asthma_classifier'

    input:
    tuple val(meta), path(combined_count_train)
    tuple val(meta), path(combined_count_test)

    output:
    tuple val(meta), path("*combined_cpm_train.csv")         , emit: combined_train_counts
    tuple val(meta), path("*combined_cpm_test.csv")          , emit: combined_test_counts

    script:
    """
    #!/usr/bin/env Rscript

    suppressMessages(library(edgeR))

    combined_traindata <- read.csv("${combined_count_train}", row.names=1)
    combined_testdata <- read.csv("${combined_count_test}", row.names=1)

    ctrd_obj <- DGEList(combined_traindata)
    ctrd_obj <- calcNormFactors(ctrd_obj)
    cpm_ctrd <- cpm(ctrd_obj)

    cted_obj <- DGEList(combined_testdata)
    cted_obj <- calcNormFactors(cted_obj)
    cpm_cted <- cpm(cted_obj)

    # Export CPM count
    write.csv(cpm_ctrd, "${meta}_combined_cpm_train.csv", row.names = TRUE)
    write.csv(cpm_cted, "${meta}_combined_cpm_test.csv", row.names = TRUE)
    """
}