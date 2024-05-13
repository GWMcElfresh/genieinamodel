FROM ghcr.io/bimberlabinternal/cellmembrane:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN R -e "install.packages('tidyverse')" && \
  R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))" && \
  R -e "install.packages('RcppParallel')" && \
  R -e "install.packages('MCMCglmm')" && \
  R -e "devtools::install_github('paul-buerkner/brms')" && \
  R -e "devtools::install_github(repo = 'bimberlabinternal/Rdiscvr', upgrade = 'never')" && \
  R -e "remotes::install_github(repo = 'ChangSuBiostats/CS-CORE')" && \
  R -e "remotes::install_github(repo = 'jishnu-lab/SLIDE')" && \
  R -e "devtools::install_github('rcastelo/GSVA')" && \
  R -e "remotes::install_github(repo = 'saezlab/MOFAcellulaR')" && \
  R -e "install.packages('fastDummies')" && \
  pip install mofapy2 && \
  pip install scdef && \
  pip cache purge && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  R -e "library(cmdstanr);library(brms);dir.create('/cmdstan', showWarnings = FALSE);cmdstanr::install_cmdstan(dir='/cmdstan', version = '2.32.2');cmdstanr::set_cmdstan_path(path = list.dirs('/cmdstan')[[2]])" && \
  gzip -r /cmdstan
  
RUN mkdir /GW_Python && \
  cd /GW_Python && \
  wget http://www.python.org/ftp/python/3.8.10/Python-3.8.10.tgz && \
  tar -zxvf Python-3.8.10.tgz && \
  cd Python-3.8.10 && \
  ./configure --prefix=/GW_Python && \
  pip uninstall -y torch torchvision torchaudio
RUN cd /GW_Python/Python-3.8.10 && \
  make && \
  make install && \
  /GW_Python/bin/pip3 install pykan && \
  /GW_Python/bin/pip3 install onnxruntime && \
  chmod -R 777 /GW_Python

#reset ENVS that might be lost in singularity (in writable work directory)
ENV RETICULATE_PYTHON=/usr/bin/python3

# NOTE: this is required when running as non-root. Setting MPLCONFIGDIR removes a similar warning.
ENV NUMBA_CACHE_DIR=/work/numba_cache
ENV MPLCONFIGDIR=/work/mpl_cache

ENV CONGA_PNG_TO_SVG_UTILITY=inkscape
ENV INKSCAPE_PROFILE_DIR=/work/inkscape
ENV USE_GMMDEMUX_SEED=1

# Create location for BioConductor AnnotationHub/ExperimentHub caches:
ENV ANNOTATION_HUB_CACHE=/work/BiocFileCache
ENV EXPERIMENT_HUB_CACHE=/work/BiocFileCache
ENV BFC_CACHE=/work/BiocFileCache

ENV CELLTYPIST_FOLDER=/tmp

#ENTRYPOINT ["/bin/bash", "-l", "-c"]

#RUN chmod -R 777 /cmdstan/*
#RUN R -e "library(cmdstanr);cmdstanr::set_cmdstan_path(path = list.dirs('/cmdstan')[[2]]);cpp_options <- list('CXX' = 'clang++','CXXFLAGS+'= '-march=native',PRECOMPILED_HEADERS = FALSE);rebuild_cmdstan()"
#RUN git clone https://github.com/stan-dev/cmdstan.git -b v2.32.2 /home/cmdstan.github --recursive 
