process PREDICT {
    tag "${meta}"

    container "community.wave.seqera.io/library/matplotlib_numpy_pandas_python-graphviz_scikit-learn:13b8c32822c15757"

    input:
    tuple val(meta), path(countdata)
    tuple val(meta), path(metadata)
    tuple val(meta), path(selected_features)             
    tuple val(meta), path(xgboost_model)
    tuple val(meta), path(randomforest_model)

    output:

    script:
    """
    #!/usr/bin/env python3

    import pandas as pd
    import pickle
    from sklearn.preprocessing import LabelEncoder
    from sklearn.model_selection import cross_val_score
    from sklearn.metrics import accuracy_score, roc_auc_score, roc_curve, auc

    countdata = pd.read_csv("${countdata}", index_col=0)
    metadata = pd.read_csv("${metadata}", index_col=0)
    features = pd.read_csv("${selected_features}", index_col=0)
    weights = features[features["s0"] != 0]
    try:
        counts = countdata.loc[weights.index]
        y_pred_cl = weights["(Intercept)", ] + np.array(weights[1:, ]) * np.array(counts)
    except KeyError as e:
        raise KeyError(f"Unfound genes from signatures and inference set: {e}")

    with open("${xgboost_model}", 'rb') as pickle_file:
        xgboost_model = pickle.load(pickle_file)
        y_pred_xgb = xgboost_model.predict(countdata)
    with open("${randomforest_model}", 'rb') as pickle_file:
        rf_model = pickle.load(pickle_file)
        y_pred_rf = rf_model.predict(countdata)

    """
}