# Transcriptomics classifier

To run the notebook script, you have to first install the proper kernel

Install the images
```
docker build -t asthma_classifier ./containers/
```

From your terminal, install the kernel
```
R -e "IRkernel::installspec(user = FALSE)"
```

Select the available kernel in `notebook.ipynb`, you can now run it.
