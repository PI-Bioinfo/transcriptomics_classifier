process FEATURE_SELECTION_KBEST {
    tag "${meta}"

    conda "community.wave.seqera.io/library/matplotlib_numpy_pandas_scikit-learn:31137aeb82b94b3a"
    publishDir "result/", mode: 'copy'

    input:
    tuple val(meta), path(meta_train), path(count_train)

    output:

    script:
    """
    #!/usr/bin/env python3
    import numpy as np
    import pandas as pd

    from sklearn.preprocessing import LabelEncoder
    from sklearn.feature_selection import SelectKBest, chi2
    from sklearn.metrics import accuracy_score, roc_auc_score, roc_curve, auc

    
    """

}