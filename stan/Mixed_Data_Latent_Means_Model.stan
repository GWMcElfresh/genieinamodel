// Latent means model + adjacency probabilities


// This structure model uses a non-copula ("spiritually copulic") matrix of latent means 
// to store joint information (used colloquially) between variables and interpret those
// latent means as edge probabilities. 

// The data are represented "properly", using appropriate parametric distributions
// to evaluate the likelihoods (whose parameters are proportional to the latent means). 

// TODO: negative binomial likelihood evaluation doesn't sample dispersion, which it should. 
// TBD if an empirical bayes shrinkage should be used there (similar to Smyth's moderated statistics)

data {
  int<lower=1> N;                  // Number of observations
  int<lower=1> P;                  // Number of variables
  int<lower=1> K;                  // Number of ordinal categories
  matrix[N, P] continuous_data;    // Continuous data (Gaussian)
  array[N, P] int<lower=0, upper=1> binary_data; // Binary data
  array[N, P] int<lower=0, upper=K> ordinal_data; // Ordinal data
  array[N, P] int<lower=0> count_data;   // Count data (geometric)
}

parameters {
  matrix[P, P] Z;                  // Latent adjacency weights
  matrix[N, P] mu;                 // Node-specific mean parameters
  vector<lower=0>[P] sigma;        // Standard deviations for Gaussian
  ordered[K - 1] cutpoints;        // Cutpoints for ordinal data
}

transformed parameters {
  matrix[P, P] A;                  // Relaxed adjacency matrix
  A = inv_logit(Z);                // Sigmoid transformation
}

model {
  // Priors
  to_vector(Z) ~ normal(0, 1);         // Sparsity-inducing prior
  sigma ~ exponential(1);             // Half-Cauchy or Exponential prior
  cutpoints ~ normal(0, 1);           // Prior for ordinal cutpoints
  
  // Likelihood
  for (n in 1:N) {
    for (i in 1:P) {
      for (j in 1:P) {
        if (i != j) {
          // Continuous data likelihood
          target += normal_lpdf(continuous_data[n, i] | A[i, j] * mu[n, j], sigma[j]);
          
          // Binary data likelihood (logistic regression)
          target += bernoulli_logit_lpmf(binary_data[n, i] | A[i, j] * mu[n, j]);
          
          // Ordinal data likelihood
          target += ordered_logistic_lpmf(ordinal_data[n, i] | A[i, j] * mu[n, j], cutpoints);
          
          // Count data likelihood (geometric with log-link)
          target += neg_binomial_2_log_lpmf(count_data[n, i] | A[i, j] * mu[n, j], 1);  // 1 is dispersion parameter
        }
      }
    }
  }
}

