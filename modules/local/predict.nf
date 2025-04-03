process PREDICT {
    tag "${meta}"

    container "community.wave.seqera.io/library/numpy_pandas_scikit-learn_xgboost:949c750fcff2a7a9"

    input:
    tuple val(meta), path(countdata)
    tuple val(meta), path(metadata)       
    tuple val(meta), path(xgboost_model)
    tuple val(meta), path(randomforest_model)

    output:

    script:
    """
    #!/usr/bin/env python3

    import pandas as pd
    import pickle
    import xgboost
    import numpy as np
    from sklearn.preprocessing import LabelEncoder
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import accuracy_score, roc_auc_score, roc_curve, auc

    countdata = pd.read_csv("${countdata}", index_col=0).T
    metadata = pd.read_csv("${metadata}", index_col=0)

    label_encoder = LabelEncoder()
    y_test = label_encoder.fit_transform(metadata.loc[:, "group"])

    with open("${xgboost_model}", 'rb') as pickle_file:
        xgboost_model = pickle.load(pickle_file)
        cols_when_model_builds = xgboost_model.get_booster().feature_names
        countdata = countdata[cols_when_model_builds]

        y_pred_xgb = xgboost_model.predict(countdata)
        accuracy = accuracy_score(y_test, y_pred_xgb)
        pd.DataFrame([accuracy], columns=["Accuracy"]).to_csv("xgboost_accuracy.csv", index=False)

    with open("${randomforest_model}", 'rb') as pickle_file:
        rf_model = pickle.load(pickle_file)
        y_pred_rf = rf_model.predict(countdata)
        accuracy = accuracy_score(y_test, y_pred_xgb)
        pd.DataFrame([accuracy], columns=["Accuracy"]).to_csv("rf_accuracy.csv", index=False)
    """
}