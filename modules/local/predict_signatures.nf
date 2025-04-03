process PREDICT_SIGNATURES {
    tag "${meta}"

    container "community.wave.seqera.io/library/numpy_pandas_scikit-learn_xgboost:949c750fcff2a7a9"

    input:
    tuple val(meta), path(countdata)
    tuple val(meta), path(metadata)
    tuple val(meta), path(selected_features)             

    output:

    script:
    """

    """
}
