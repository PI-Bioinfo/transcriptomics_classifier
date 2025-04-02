process XGBOOST {
    tag "${meta}"

    container "community.wave.seqera.io/library/numpy_pandas_scikit-learn_xgboost:949c750fcff2a7a9"
    publishDir "result/", mode: 'copy'

    input:
    tuple val(meta), path(meta_train)
    tuple val(meta), path(meta_test)
    tuple val(meta), path(count_train)
    tuple val(meta), path(count_test)   

    output:
    tuple val(meta), path("xgboost_classifier.pkl")                         , emit: model
    
    script:
    """
    #!/usr/bin/env python3
    import numpy as np
    import pandas as pd
    import xgboost as xgb
    import pickle
    from sklearn.preprocessing import LabelEncoder
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import accuracy_score, classification_report, f1_score

    X_train = pd.read_csv("${count_train}", index_col=0).T
    X_test = pd.read_csv("${count_test}", index_col=0).T
    y_train = pd.read_csv("${meta_train}", index_col=0).loc[:, "group"]
    y_test = pd.read_csv("${meta_test}", index_col=0).loc[:, "group"]

    label_encoder = LabelEncoder()
    y_train = label_encoder.fit_transform(y_train)
    y_test = label_encoder.transform(y_test)

    X_train, X_val, y_train, y_val=train_test_split(X_train, y_train, random_state=0)

    model = xgb.XGBClassifier(
        n_estimators = 500,
        learning_rate = 0.05,
        use_label_encoder = False,
        eval_metric = "logloss",
        early_stopping_rounds = 5,
        n_jobs = -1
    )

    model.fit(X_train, y_train,                    
            eval_set = [(X_val,y_val)],
            verbose = False)

    model_pkl_file = "xgboost_classifier.pkl"  

    with open(model_pkl_file, 'wb') as file:  
        pickle.dump(model, file)

    pred_test = model.predict(X_test)
    test_score = accuracy_score(pred_test, y_test)
    print("Test score:", np.round(test_score,2))
    """
}