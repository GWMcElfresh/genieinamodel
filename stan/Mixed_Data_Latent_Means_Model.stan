// Latent means model + adjacency probabilities


// This structure model uses a non-copula ("spiritually copulic") matrix of latent means 
// to store joint information (used colloquially) between variables and interpret those
// latent means as edge probabilities. 

// The data are represented "properly", using appropriate parametric distributions
// to evaluate the likelihoods (whose parameters are proportional to the latent means). 

// TODO: negative binomial likelihood evaluation doesn't sample dispersion, which it should. 
// TBD if an empirical bayes shrinkage should be used there (similar to Smyth's moderated statistics)

data {
  int<lower=0> N;           // Number of samples
  int<lower=0> P;           // Number of variables
  int<lower=0> P_continuous; // Number of continuous variables
  int<lower=0> P_binary; // Number of binary variables
  int<lower=0> P_count;  // Number of count variables
  int<lower=0> P_ordinal; //Number of ordinal variables
  int<lower=1> O; // Number of categories that the ordinal variable can take on
  matrix[N,P_continuous] continuous_data; // Continuous variables
  array[N,P_binary] int<lower=0, upper=1> binary_data; // Binary variables
  array[N,P_ordinal] int<lower=1> ordinal_data; // Ordinal variables
  array[N,P_count] int<lower=0> count_data; // Count variables
  array[P] int<lower=1, upper=4> var_types; // Variable types: 1=continuous, 2=binary, 3=ordinal
}

parameters {
  matrix<lower=0, upper=1>[P, P] edge_probs_upper; // Upper triangular edge probabilities
  vector[P] latent_means;      // Latent variable means
  real<lower=0> latent_sd;     // Latent variable standard deviation
  ordered[O] thresholds;       // Ordered thresholds for ordinal data
  real<lower=0> phi;          // Dispersion parameter for Negative Binomial
}

transformed parameters {
  matrix<lower=0, upper=1>[P, P] edge_probs; // Symmetric edge probabilities
  
  // Fill edge_probs with the upper triangular matrix and enforce symmetry
  for (i in 1:P) {
    for (j in 1:P) {
      if (i < j) {
        edge_probs[i, j] = edge_probs_upper[i, j];
        edge_probs[j, i] = edge_probs_upper[i, j];
      } else if (i == j) {
        edge_probs[i, j] = 0; // No self-loops
      }
    }
  }
}

model {
  // Prior on edge probabilities
  for (i in 1:(P - 1)) {
    for (j in (i + 1):P) {
      edge_probs_upper[i, j] ~ beta(2, 2); // Example prior
    }
  }

  // Likelihood for mixed data conditioned on graph connectivity
  // Continuous variables
  for (p in 1:P_continuous) {
    for (n in 1:N) {
      continuous_data[n, p] ~ normal(latent_means[p], latent_sd);
    }
  }

  // Binary variables
  for (p in 1:P_binary) {
    for (n in 1:N) {
      binary_data[n, p] ~ bernoulli_logit(latent_means[P_continuous + p]);
    }
  }

  // Ordinal variables
  for (p in 1:P_ordinal) {
    for (n in 1:N) {
      ordinal_data[n, p] ~ ordered_logistic(latent_means[p], thresholds);
    }
  }
  
  for (p in 1:P_count) {
    for (n in 1:N) {
      count_data[n, p] ~ neg_binomial_2(latent_means[p], phi);  // Negative Binomial likelihood
    }
  }
}


  generated quantities {
    matrix[P, P] sampled_graph; // Binary adjacency matrix
    for (i in 1:P) {
      for (j in 1:P) {
        if (i < j) {
          sampled_graph[i, j] = bernoulli_rng(edge_probs[i, j]);
          sampled_graph[j, i] = sampled_graph[i, j]; // Symmetry
        } else {
          sampled_graph[i, j] = 0; // No self-loops
        }
      }
    }
  }