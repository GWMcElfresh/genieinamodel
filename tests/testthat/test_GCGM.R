library(cmdstanr)
library(testthat)
library(posterior)

test_that("Stan syntax is valid", {
  mod <- cmdstan_model(system.file("stan/GCGM_With_Imputation.stan", package = "genieinamodel"), compile = FALSE)
  expect_true(mod$check_syntax())
})

test_that("model compiles to an executable", {
  mod <- cmdstan_model(system.file("stan/GCGM_With_Imputation.stan", package = "genieinamodel"))
  expect_true(file.exists(mod$exe_file()))
})

# helper function to simulate minimal data (N=5, D=2)
simulate_data <- function() {
  # Basic dimensions
  N    <- 5
  D    <- 2
  type <- c(1L, 5L)          # 1=gaussian, 5=poisson
  K    <- c(1L, 1L)          # #levels (only matters for nominal/ordinal)
  
  # Compute latent‑dimension count P: 1 per non‑nominal, (K[j]-1) per nominal
  P <- sum(ifelse(type == 4L, K - 1L, 1L))
  
  # maxK is the largest number of levels across all variables
  maxK <- max(K)
  
  # If you’re not fixing any correlations, supply R_fixed as identity
  # (zeros off‑diag mean “no entries forced” )
  R_fixed <- diag(1, P)
  
  # Build your observed matrices (use the same patterns as before)
  Y_cont <- matrix(0.0, N, D)
  Y_bin  <- matrix(0L, N, D)
  Y_ord  <- matrix(1L, N, D)
  Y_nom  <- matrix(1L, N, D)
  Y_poi  <- matrix(0L, N, D)
  Y_nb   <- matrix(0L, N, D)
  miss   <- matrix(0L, N, D)

  Y_cont[,1] <- rnorm(N)               # gaussian for var1
  Y_poi[,2]  <- rpois(N, lambda = 2)   # poisson for var2
  
  list(
    N       = N,
    D       = D,
    P       = P,
    maxK    = maxK,
    type    = type,
    K       = K,
    R_fixed = R_fixed,
    Y_cont  = Y_cont,
    Y_bin   = Y_bin,
    Y_ord   = Y_ord,
    Y_nom   = Y_nom,
    Y_poi   = Y_poi,
    Y_nb    = Y_nb,
    miss    = miss
  )
}


#sampling & output structure
test_that("sampling runs and returns correct structure", {
  stan_data <- simulate_data()
  mod <- cmdstan_model(system.file("stan/GCGM_With_Imputation.stan", package = "genieinamodel"))
  fit <- mod$sample(data = stan_data, chains = 1, iter_warmup = 50,
                    iter_sampling = 50, seed = 123, refresh = 0)
  expect_s3_class(fit, "CmdStanMCMC")
  draws_rvars <- as_draws_rvars(fit$draws())
  Z_rvar <- draws_rvars$Z
  expect_equal(dim(Z_rvar), c(stan_data$N, stan_data$D))
  expect_equal(nchains(Z_rvar), 1)
  expect_equal(ndraws(Z_rvar), 50)
})

#missing‑data imputation
test_that("missing data entries are imputed", {
  set.seed(123)
  sd <- simulate_data()
  sd$miss[1,1] <- 1
  sd$Y_cont[1,1] <- 0
  mod <- cmdstan_model(system.file("stan/GCGM_With_Imputation.stan", package = "genieinamodel"))
  expect_error(fit <- mod$sample(data = sd, chains = 1, iter_sampling = 500,
                                 iter_warmup = 500, seed = 123, refresh = 0),
               NA)
  expect_false(any(is.na(fit$draws("Z"))))
  draws_rvars <- as_draws_rvars(fit$draws())
  Z_rvar <- draws_rvars$Z
  print(mean(Z_rvar[1,1]))
  print(posterior::sd(Z_rvar[1,1]))
  #expect that the mean is pretty small for an imputed variable
  expect_true(mean(Z_rvar[1,1]) < 0.1)
  expect_true(posterior::sd(Z_rvar[1,1]) > 0.5)
})

#fixed correlations
test_that("Fixed correlations are honored", {
  stan_data <- simulate_data()
  
  #define correlated variables
  r_fixed <- 0.7
  stan_data$R_fixed <- matrix(c(1, r_fixed, r_fixed, 1), nrow = 2)
  
  
  mod <- cmdstan_model(system.file("stan/GCGM_With_Imputation.stan", package = "genieinamodel"))
  fit <- mod$sample(
    data          = stan_data,
    chains        = 1,
    iter_warmup   = 1000,
    iter_sampling = 1000,
    seed          = 123,
    refresh       = 0
  )
  
  # Extract posterior draws for Sigma[1,2]
  corr_draws <- fit$draws("corr_12")
  # Check the empirical mean of the correlation matches the fixed value
  expect_true(abs(mean(corr_draws) - r_fixed) < 0.05)
})


test_that("Horseshoe Prior works", {
  stan_data <- simulate_data()
  
  mod <- cmdstan_model(system.file("stan/GCGM_with_horseshoe_priors.stan", package = "genieinamodel"))
  fit <- mod$sample(
    data          = stan_data,
    chains        = 1,
    iter_warmup   = 1000,
    iter_sampling = 1000,
    seed          = 123,
    refresh       = 0
  )
})