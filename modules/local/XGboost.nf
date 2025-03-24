process XGBOOST {
    tag "${meta}"

    container "community.wave.seqera.io/library/numpy_pandas_scikit-learn_xgboost:949c750fcff2a7a9"
    publishDir "result/", mode: 'copy'

    input:
    tuple val(meta), path(meta_train), path(count_train)
    tuple val(meta), path(normalized_counts)             
    tuple val(meta), path(deseq2_results)
    tuple val(meta), path(meta_test), path(count_test)   

    output:
    tuple val(meta), path("*")
    
    script:
    """
    #!/usr/bin/env python3
    import numpy as np
    import pandas as pd
    import xgboost as xgb
    from sklearn.preprocessing import LabelEncoder
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import accuracy_score, f1_score

    X_train = pd.read_csv("${count_train}", index_col=0).T
    X_test = pd.read_csv("${count_test}", index_col=0).T
    y_train = pd.read_csv("${meta_train}", index_col=0).loc[:, "group"]
    y_test = pd.read_csv("${meta_test}", index_col=0).loc[:, "group"]

    # Encode categorical data
    label_encoder = LabelEncoder()
    y_train = label_encoder.fit_transform(y_train)
    y_test = label_encoder.transform(y_test)

    print(X_train.shape)
    print(y_train.shape)

    dtrain = xgb.DMatrix(X_train, label=y_train)
    dtest = xgb.DMatrix(X_test, label=y_test)

    # XGBoost parameters (for classification)
    params = {
        "objective": "multi:softmax", 
        "num_class": len(np.unique(y_train)),  
        "eval_metric": "mlogloss", 
        "max_depth": 6,  # Tree depth
        "eta": 0.1,  # Learning rate
        "subsample": 0.8,  # Row sampling
        "colsample_bytree": 0.8,  # Feature sampling
        "seed": 42,
    }

    # Train XGBoost classifier
    num_rounds = 100
    model = xgb.train(params, dtrain, num_rounds)

    # Make predictions
    y_pred = model.predict(dtest)

    # Evaluate performance
    accuracy = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred, average="weighted")  # Weighted F1 for imbalanced classes

    print(f"Accuracy: {accuracy:.4f}")
    print(f"F1-score: {f1:.4f}")
    """
}