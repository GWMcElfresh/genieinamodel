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
  R -e "install.packages(c('FNN', 'igraph', 'future.apply', 'kernlab', 'forcats', 'progressr', 'future', 'twosamples'))" && \
  pip install mofapy2 && \
  pip install scdef && \
  pip cache purge && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  mkdir /work/ && \
  R -e "library(cmdstanr);library(brms);dir.create('/work/cmdstan', showWarnings = FALSE);cmdstanr::install_cmdstan(dir='/work/cmdstan', version = '2.32.2');cmdstanr::set_cmdstan_path(path = list.dirs('/work/cmdstan')[[2]])" && \
  gzip -r /work/cmdstan

#ENTRYPOINT ["/bin/bash", "-l", "-c"]

#RUN chmod -R 777 /cmdstan/*
#RUN R -e "library(cmdstanr);cmdstanr::set_cmdstan_path(path = list.dirs('/cmdstan')[[2]]);cpp_options <- list('CXX' = 'clang++','CXXFLAGS+'= '-march=native',PRECOMPILED_HEADERS = FALSE);rebuild_cmdstan()"
#RUN git clone https://github.com/stan-dev/cmdstan.git -b v2.32.2 /home/cmdstan.github --recursive 
