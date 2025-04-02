process PREPROCESS {
    tag "${meta}"

     conda '/opt/miniconda/envs/asthma_classifier'

    input:
    val split_option
    tuple val(meta), path(metadata)
    tuple val(meta_human), path(countdata)  
    tuple val(meta_viral), path(viraldata)

    output:
    tuple val(meta_human), path("*meta_train.csv"), path("*human_count_train.csv"), path("*viral_count_train.csv")   , emit: train_set
    tuple val(meta_human), path("*meta_test.csv"), path("*human_count_test.csv"), path("*viral_count_test.csv")      , emit: test_set

    script:
    def sampling_ratio          = task.ext.sampling_ratio ?: 0.8
    def sampling_seed           = task.ext.sampling_seed ?: 42
    """
    #!/usr/bin/env python

    import pandas as pd
    import numpy as np
    from sklearn.model_selection import train_test_split

    metadata    = pd.read_csv("${metadata}", index_col=0)
    rawdata     = pd.read_csv("${countdata}", index_col=0)
    viraldata   = pd.read_csv("${viraldata}", index_col=0)

    rawdata     = rawdata[rawdata.sum(axis=1) > 10]
    viraldata   = viraldata[viraldata.sum(axis=1) > 10]

    if ("${split_option}" == "seed"):
        np.random.seed(${sampling_seed})

        train_idx, test_idx = train_test_split(metadata.index, 
                                            test_size=(1 - ${sampling_ratio}), 
                                            stratify=metadata["group"], 
                                            random_state=${sampling_seed})

        meta_train, meta_test = metadata.loc[train_idx], metadata.loc[test_idx]
        df_train, df_test = rawdata.loc[:, train_idx], rawdata.loc[:, test_idx]
        df_viral_train, df_viral_test = viraldata.loc[:, train_idx], viraldata.loc[:, test_idx]
    
    elif ("${split_option}" == "design"):
        train_idx = metadata[metadata["cohort"] == "train"].index
        test_idx = metadata[metadata["cohort"] == "test"].index

        meta_train, meta_test = metadata.loc[train_idx], metadata.loc[test_idx]
        df_train, df_test = rawdata.loc[:, train_idx], rawdata.loc[:, test_idx]
        df_viral_train, df_viral_test = viraldata.loc[:, train_idx], viraldata.loc[:, test_idx]

    meta_train.to_csv("meta_train.csv")
    meta_test.to_csv("meta_test.csv")
    df_train.to_csv(f"${meta_human}_count_train.csv")
    df_test.to_csv(f"${meta_human}_count_test.csv")
    df_viral_train.to_csv(f"${meta_viral}_count_train.csv")
    df_viral_test.to_csv(f"${meta_viral}_count_test.csv")
    """
}