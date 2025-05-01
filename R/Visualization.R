library(copula)
library(GGally)
library(dplyr)

# sample copula 
Z_post <- posterior::as_draws_matrix(fit$draws("Z"))
# Average over draws to get posterior mean of Z
Z_hat <- matrix(colMeans(Z_post), nrow = N, ncol = P, byrow = FALSE)

# Compute pseudo-obs
U <- pnorm( scale(Z_hat) )

#pairs_
ggpairs(as.data.frame(U),
        columns = 1:P,
        upper = list(continuous = wrap("cor", size = 3)),
        diag  = list(continuous = "densityDiag"),
        lower = list(continuous = "points")) +
  theme_minimal()