FROM ghcr.io/bimberlabinternal/cellmembrane:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN R -e "install.packages('tidyverse')" && \
  R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))" && \
  R -e "install.packages('RcppParallel')" && \
  R -e "install.packages('brms')" 

RUN R -e "library(cmdstanr);library(brms);dir.create('/cmdstan', showWarnings = FALSE);cmdstanr::install_cmdstan(dir='/cmdstan');cmdstanr::set_cmdstan_path(path = list.dirs('/cmdstan')[[2]])"

RUN chmod 777 /cmdstanr/*

