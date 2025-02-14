// Gumble Copula model 
// For a best case "edge weights" P, one may need to initalize the structure. 

// Proposes graph structures (edge probabilities) and reports a tail dependence
// Intended to be used with extreme value distributions (e.g. flow data) where rare, extreme, populations are of primary interest

data {
  int<lower=0> N;           // Number of samples
  int<lower=0> P;           // Number of variables
  matrix[N, P] U;           // Transformed data (uniform marginals)
  real<lower=1> alpha;      // Hyperparameter for sparsity
}

parameters {
  matrix<lower=0, upper=1>[P, P] edge_probs_upper; // Upper triangular adjacency matrix
  real<lower=1> theta;       // Gumbel copula parameter (>1 for positive dependence)
}

transformed parameters {
  matrix<lower=0, upper=1>[P, P] edge_probs; // Symmetric adjacency matrix

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
  // Prior: Sparsity constraint on edges
  for (i in 1:(P - 1)) {
    for (j in (i + 1):P) {
      edge_probs_upper[i, j] ~ beta(alpha, 1); // Controls sparsity
    }
  }

  // Likelihood using Gumbel copula
  for (i in 1:P) {
    for (j in (i + 1):P) {
      if (edge_probs[i, j] > 0.5) { // Only consider strong edges
        for (n in 1:N) {
          real C_uv = exp(-((pow((-log(U[n, i])), theta) + pow((-log(U[n, j])), theta)) ^ (1 / theta)));
          target += log(C_uv); // Log-likelihood of the copula
        }
      }
    }
  }
}

generated quantities {
  matrix[P, P] sampled_graph; // Binary adjacency matrix
  vector[P] tail_dependence;  // Tail dependence for each variable

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

  // Compute tail dependence coefficient (lambda)
  for (i in 1:P) {
    real lambda_sum = 0;
    int count_edges = 0;

    for (j in 1:P) {
      if (sampled_graph[i, j] == 1) { // Consider only selected edges
        lambda_sum += 2 - 2^(1 / theta); // Gumbel tail dependence formula
        count_edges += 1;
      }
    }
    tail_dependence[i] = (count_edges > 0) ? lambda_sum / count_edges : 0; // Average lambda
  }
}