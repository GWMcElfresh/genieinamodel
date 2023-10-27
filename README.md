# cmdstanr-brms-image
A docker image for running cmdstanr via brms on exacloud. 

Features tidyverse, brms, and cmdstanr backend on top of cellmembrane. 

Specifics: the cmdstanr package is installed in /cmdstanr/. Current errors on exacloud suggest these need to be non-read only, so I'm demoing chmod 777.
