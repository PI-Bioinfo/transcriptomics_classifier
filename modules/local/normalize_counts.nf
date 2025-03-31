process NORMALIZE_COUNT {

    conda '/opt/miniconda/envs/asthma_classifier'

    input:
    tuple val(meta_human), path(count_human_train)
    tuple val(meta_human), path(count_human_test)
    tuple val(meta_viral), path(count_viral_train)
    tuple val(meta_viral), path(count_viral_test)

    output:
    tuple val(meta_human), path("*human_cpm_train.csv")         , emit: human_train_set
    tuple val(meta_human), path("*human_cpm_test.csv")          , emit: human_test_set
    tuple val(meta_viral), path("*viral_cpm_train.csv")         , emit: viral_train_set
    tuple val(meta_viral), path("*viral_cpm_test.csv")          , emit: viral_test_set

    script:
    """
    #!/usr/bin/env Rscript

    suppressMessages(library(edgeR))

    human_traindata <- read.csv("${count_human_train}", row.names=1)
    viral_traindata <- read.csv("${count_viral_train}", row.names=1)
    human_testdata <- read.csv("${count_human_test}", row.names=1)
    viral_testdata <- read.csv("${count_viral_test}", row.names=1)

    htrd_obj <- DGEList(human_traindata)
    htrd_obj <- calcNormFactors(htrd_obj)
    cpm_htrd <- cpm(htrd_obj)

    hted_obj <- DGEList(human_testdata)
    hted_obj <- calcNormFactors(hted_obj)
    cpm_hted <- cpm(hted_obj)

    vtrd_obj <- DGEList(viral_traindata)
    vtrd_obj <- calcNormFactors(vtrd_obj)
    cpm_vtrd <- cpm(vtrd_obj)

    vted_obj <- DGEList(viral_testdata)
    vted_obj <- calcNormFactors(vted_obj)
    cpm_vted <- cpm(vted_obj)

    # Export CPM count
    write.csv(cpm_htrd, "${meta_human}_human_cpm_train.csv", row.names = TRUE)
    write.csv(cpm_hted, "${meta_human}_human_cpm_test.csv", row.names = TRUE)
    write.csv(cpm_vtrd, "${meta_viral}_viral_cpm_train.csv", row.names = TRUE)
    write.csv(cpm_vted, "${meta_viral}_viral_cpm_test.csv", row.names = TRUE)
    """
}