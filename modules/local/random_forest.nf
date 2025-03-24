process RANDOM_FOREST {
    tag "${meta}"

    container "community.wave.seqera.io/library/matplotlib_numpy_pandas_scikit-learn:31137aeb82b94b3a"
    publishDir "result/", mode: 'copy'

    input:
    tuple val(meta), path(meta_train), path(count_train)
    tuple val(meta), path(normalized_counts)             
    tuple val(meta), path(deseq2_results)
    tuple val(meta), path(meta_test), path(count_test)   

    output:

    script:
    """
    #!/usr/bin/env python3
    import numpy as np
    import pandas as pd

    from sklearn.preprocessing import LabelEncoder
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import accuracy_score, roc_auc_score, roc_curve, auc

    X_train = pd.read_csv("${count_train}", index_col=0).T
    X_test = pd.read_csv("${count_test}", index_col=0).T
    y_train = pd.read_csv("${meta_train}", index_col=0).loc[:, "group"]
    y_test = pd.read_csv("${meta_test}", index_col=0).loc[:, "group"]

    print(y_train.value_counts())

    # Encode categorical data
    label_encoder = LabelEncoder()
    y_train = label_encoder.fit_transform(y_train)
    y_test = label_encoder.transform(y_test)

    print(X_train.shape)
    

    rf_model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
    rf_model.fit(X_train, y_train)

    # Make predictions
    y_pred = rf_model.predict(X_test)
    y_prob = rf_model.predict_proba(X_test) 

    # Evaluate performance
    accuracy = accuracy_score(y_test, y_pred)
    print(y_test, y_prob)
    roc_auc = roc_auc_score(y_test, y_prob[:, 1], multi_class="ovr")  

    print(f"Accuracy: {accuracy:.4f}")
    print(f"ROC-AUC Score: {roc_auc:.4f}")

    """

}