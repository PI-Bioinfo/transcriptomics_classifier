process RANDOM_FOREST {
    tag "${meta}"

    container "community.wave.seqera.io/library/matplotlib_numpy_pandas_python-graphviz_scikit-learn:13b8c32822c15757"

    input:
    tuple val(meta), path(meta_train), path(count_train)
    tuple val(meta), path(meta_test), path(count_test)   

    output:

    script:
    """
    #!/usr/bin/env python3
    import numpy as np
    import pandas as pd
    from sklearn.preprocessing import LabelEncoder
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import cross_val_score
    from sklearn.metrics import accuracy_score, roc_auc_score, roc_curve, auc

    X_train = pd.read_csv("${count_train}", index_col=0).T
    X_test = pd.read_csv("${count_test}", index_col=0).T
    y_train = pd.read_csv("${meta_train}", index_col=0).loc[:, "group"]
    y_test = pd.read_csv("${meta_test}", index_col=0).loc[:, "group"]

    label_encoder = LabelEncoder()
    y_train = label_encoder.fit_transform(y_train)
    y_test = label_encoder.transform(y_test)

    model = RandomForestClassifier(
        n_estimators=50, 
        max_depth=5, 
        random_state=42
    )
    model.fit(X_train, y_train)
    cv_scores = cross_val_score(model, X_train, y_train, cv=5, scoring="accuracy")

    y_pred = model.predict(X_test)
    y_prob = model.predict_proba(X_test) 

    accuracy = accuracy_score(y_test, y_pred)
    roc_auc = roc_auc_score(y_test, y_prob[:, 1], multi_class="ovr")  

    print(f"Cross-validation accuracy: {cv_scores.mean():.4f} ± {cv_scores.std():.4f}")
    print(f"Accuracy: {accuracy:.4f}")
    print(f"ROC-AUC Score: {roc_auc:.4f}")

    """

}