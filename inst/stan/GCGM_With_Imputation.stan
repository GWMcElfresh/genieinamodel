data {
  int<lower=1> P;                    // total latent dims
  matrix[P,P] R_fixed;               // user‐specified correlations
  int<lower=1> N;                 // obs
  int<lower=1> D;                 // variables
  int<lower=1> maxK;              // max categories
  array[D] int<lower=1,upper=6> type;   // 1=gauss,2=bin,3=ord,4=nom,5=pois,6=nb
  array[D] int<lower=1> K;              // #levels (1 if not factor)
  matrix[N,D] Y_cont;             // sentinel 0 if missing
  array[N, D] int<lower=0, upper=1> Y_bin;// binary 0/1 (0 if missing)
  array[N, D] int<lower=1> Y_ord;        // 1…K[j] ≥1 (set 1 if missing)
  array[N, D] int<lower=1> Y_nom;        // 1…K[j] (set 1 if missing)
  array[N, D] int<lower=0> Y_poi;        // Poisson counts
  array[N, D] int<lower=0> Y_nb;         // NegBin counts
  array[N, D] int<lower=0, upper=1> miss; // 1 if missing
}

transformed data {
  array[D] int start;
  array[D] int end;
  int idx = 1;
  for (j in 1:D) {
    if (type[j] == 4) {
      // Nominal variable: allocate K[j]-1 latent dimensions
      start[j] = idx;
      end[j]   = idx + (K[j] - 1) - 1;
      idx += (K[j] - 1);    // compound assignment is fine
    } else {
      // Other variable types: just one latent dimension
      start[j] = idx;
      end[j]   = idx;
      idx += 1;             // increment by 1 explicitly
    }
  }
}

parameters {
  cholesky_factor_corr[P] L_corr ;    // free correlations
  vector<lower=0>[P]     tau;       // positive scales (std devs) per latent dim
  matrix[N, P]           Z;         // latent utilities for all observations
  vector<lower=0>[D]     sigma;     // continuous response sds
  vector<lower=0>[D]     phi;       // NegBin overdispersion params
  array[D] ordered[max(K) - 1] cuts;   // ordinal thresholds per variable
}

transformed parameters {
  matrix[P,P] L;                     // full covariance Cholesky
  for (i in 1:P) {
    for (j in 1:P)
      // Change condition to != 0 to allow fixing any non-zero correlation
      L[i,j] = (R_fixed[i,j] != 0 ?  // if user fixed
                R_fixed[i,j] :
                (i >= j ? L_corr [i,j] : 0));
  }
  L = diag_pre_multiply(tau, L);
}

model {
  // Priors on covariance structure
  L_corr  ~ lkj_corr_cholesky(1);   // LKJ(1) on correlation 
  tau    ~ cauchy(0, 1);           // global/local shrinkage
  
  //L_corr [i,j] ~ normal(fixed_value, 1e-6); #optionally, use tight priors on specific correlations
  
  // Priors on margins
  sigma  ~ normal(1, 0.5);
  phi    ~ cauchy(0, 2);

  // Latent Gaussian copula via Cholesky
  for (n in 1:N)
    Z[n] ~ multi_normal_cholesky(rep_vector(0, P), L);

  // 3) Observation Likelihood
  for (n in 1:N) {
    for (j in 1:D) {
      if (miss[n,j]==0) {
        if (type[j]==1) {
          target += normal_lpdf(Y_cont[n,j] | Z[n,start[j]], sigma[j]);
        } else if (type[j]==2) {
          target += bernoulli_logit_lpmf(Y_bin[n,j] | Z[n,start[j]]);
        } else if (type[j]==3) {
          target += ordered_logistic_lpmf(Y_ord[n,j] | Z[n,start[j]], cuts[j]);
        } else if (type[j]==4) {
          vector[K[j]] utils;
          utils[1] = 0;
          for (k in 2:K[j])
            utils[k] = Z[n, start[j]+k-2];
          target += categorical_logit_lpmf(Y_nom[n,j] | utils);
        } else if (type[j]==5) {
          // Poisson via log-rate latent
          target += poisson_log_lpmf(Y_poi[n,j] | Z[n,start[j]]);
        } else {
          // Negative Binomial via log-mean + overdispersion
          target += neg_binomial_2_log_lpmf(Y_nb[n,j] |
                                            Z[n,start[j]], phi[j]);
        }
      }
    }
  }
}
generated quantities {
  // Reconstruct full covariance and correlation matrices
  matrix[P,P] Sigma_out = multiply_lower_tri_self_transpose(L);
  matrix[P,P] Corr_out;
  for (i in 1:P) {
    for (j in 1:P) {
      Corr_out[i,j] = Sigma_out[i,j] / (tau[i] * tau[j]);
    }
  }
  // Extract the correlation of interest
  real corr_12 = Corr_out[1,2];
}
