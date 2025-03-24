FROM continuumio/miniconda3
WORKDIR /app
COPY environment.yml .
RUN conda env create -f environment.yml
RUN echo "conda activate asthma_classifier" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]
CMD ["bash"]
