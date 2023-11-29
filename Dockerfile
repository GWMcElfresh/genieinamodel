FROM ghcr.io/bimberlabinternal/cellmembrane:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN R -e "install.packages('tidyverse')" && \
  R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))" && \
  R -e "install.packages('RcppParallel')" && \
  R -e "install.packages('MCMCglmm')" && \
  R -e "install.packages('brms')" && \
  R -e "devtools::install_github(repo = 'bimberlabinternal/Rdiscvr')" && \
  R -e "remotes::install_version('Seurat', version = '4.4.0')"

RUN R -e "library(cmdstanr);library(brms);dir.create('/cmdstan', showWarnings = FALSE);cmdstanr::install_cmdstan(dir='/cmdstan');cmdstanr::set_cmdstan_path(path = list.dirs('/cmdstan')[[2]])"

#RUN chmod -R 777 /cmdstan/*
#RUN R -e "library(cmdstanr);cmdstanr::set_cmdstan_path(path = list.dirs('/cmdstan')[[2]]);cpp_options <- list('CXX' = 'clang++','CXXFLAGS+'= '-march=native',PRECOMPILED_HEADERS = FALSE);rebuild_cmdstan()"
RUN git clone https://github.com/stan-dev/cmdstan.git -b v2.32.2 /home/cmdstan.github --recursive 
