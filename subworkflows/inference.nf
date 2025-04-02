include { PREDICT                                          } from "${projectDir}/modules/local/predict.nf"

workflow INFERENCE {
    
    take:
        ch_inference_data
        ch_inference_meta
        classification_model
        xgboost_model
        random_forest_model

    main:

        PREDICT(
            ch_inference_data,
            ch_inference_meta,
            classification_model,
            xgboost_model,
            random_forest_model,
        )

}