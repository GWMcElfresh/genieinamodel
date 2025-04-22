library(cmdstanr)
library(testthat)
library(posterior)

context("GCGM sparse counts missing")


test_that("Stan syntax is valid", {
  mod <- cmdstan_model(system.file("stan/GCGM_With_Imputation.stan", package = "genieinamodel"), compile = FALSE)
  expect_true(mod$check_syntax())
})


test_that("model compiles to an executable", {
  mod <- cmdstan_model(system.file("stan/GCGM_With_Imputation.stan", package = "genieinamodel"))
  expect_true(file.exists(mod$exe_file()))
})

#skip heavy sampling on CRAN/CI
skip_on_cran()
skip_on_ci()

# helper funciton to simulate minimal data (N=5, D=2)
simulate_data <- function() {
  list(
    N = 5, D = 2, maxK = 1,
    type = c(1L, 5L),  # gaussian, poisson
    K = c(1L, 1L),
    Y_cont = matrix(rnorm(5*2), 5, 2),
    Y_bin  = matrix(0L, 5, 2),
    Y_ord  = matrix(1L, 5, 2),
    Y_nom  = matrix(1L, 5, 2),
    Y_poi  = matrix(rpois(5*2, lambda = 2), 5, 2),
    Y_nb   = matrix(0L, 5, 2),
    miss   = matrix(0L, 5, 2)
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
  expect_equal(dim(Z_rvar), c(stan_data$N, P))
  expect_equal(nchains(Z_rvar), 1)
  expect_equal(ndraws(Z_rvar), 50)
})

#missing‑data imputation
test_that("missing data entries are imputed", {
  sd <- simulate_data()
  sd$miss[1,1] <- 1
  sd$Y_cont[1,1] <- 0
  mod <- cmdstan_model(system.file("stan/GCGM_With_Imputation.stan", package = "genieinamodel"))
  expect_error(fit <- mod$sample(data = sd, chains = 1, iter_sampling = 50,
                                 iter_warmup = 50, seed = 123, refresh = 0),
               NA)
  expect_false(any(is.na(fit$draws("Z"))))
  #expect a high sd from the missing value
  draws_rvars <- as_draws_rvars(fit$draws())
  Z_rvar <- draws_rvars$Z
  expect_true(posterior::sd(Z_rvar[1,1]) > 3)
})
