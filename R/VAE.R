#' @title Variational Autoencoder (VAE) with Hurdle Gaussian Decoder
#' @description This module defines a VAE with a hurdle Gaussian decoder.
#' @param input_dim The number of input features.
#' @param latent_dim The number of latent dimensions.
#' @return A VAE module with a hurdle Gaussian decoder.
#' @export
#' @import torch luz
#' 


#Define the VAE model with a hurdle Gaussian decoder
VAE_HurdleGaussian <- nn_module(
  "VAE_HurdleGaussian",
  initialize = function(input_dim, latent_dim) {
    #encoder layers
    self$fc1 <- nn_linear(input_dim, 10000)
    self$fc2 <- nn_linear(10000, 2000)
    self$fc3 <- nn_linear(2000, 500)
    self$fc_mu <- nn_linear(500, latent_dim)
    self$fc_logvar <- nn_linear(500, latent_dim)
    
    #decoder layers for zero-inflation component
    self$fc4_zero <- nn_linear(latent_dim, 500)
    self$fc5_zero <- nn_linear(500, 2000)
    self$fc6_zero <- nn_linear(2000, 10000)
    self$output_zero <- nn_linear(10000, input_dim)  #bernoulli probability
    
    #decoder layers for positive values
    self$fc4_positive <- nn_linear(latent_dim, 500)
    self$fc5_positive <- nn_linear(500, 2000)
    self$fc6_positive <- nn_linear(2000, 10000)
    self$output_mu <- nn_linear(10000, input_dim)  #mean for gaussian
    self$output_logvar <- nn_linear(10000, input_dim)  #log-variance for gaussian
    
    #dropout
    self$dropout <- nn_dropout(0.3)
    
    #initialize weights in all of the layers
    torch::nn_init_xavier_uniform_(self$fc1$weight)
    torch::nn_init_xavier_uniform_(self$fc2$weight)
    torch::nn_init_xavier_uniform_(self$fc3$weight)
    torch::nn_init_xavier_uniform_(self$fc_mu$weight)
    torch::nn_init_xavier_uniform_(self$fc_logvar$weight)
    torch::nn_init_xavier_uniform_(self$fc4_zero$weight)
    torch::nn_init_xavier_uniform_(self$fc5_zero$weight)
    torch::nn_init_xavier_uniform_(self$fc6_zero$weight)
    torch::nn_init_xavier_uniform_(self$output_zero$weight)
    torch::nn_init_xavier_uniform_(self$fc4_positive$weight)
    torch::nn_init_xavier_uniform_(self$fc5_positive$weight)
    torch::nn_init_xavier_uniform_(self$fc6_positive$weight)
    torch::nn_init_xavier_uniform_(self$output_mu$weight)
    torch::nn_init_xavier_uniform_(self$output_logvar$weight)
  },
  
  #encoder forward pass
  encode = function(x) {
    h1 <- nnf_relu(self$fc1(x))
    h2 <- nnf_relu(self$fc2(h1))
    h3 <- nnf_relu(self$fc3(h2))
    mu <- self$fc_mu(h3)
    logvar <- self$fc_logvar(h3)
    return(list(mu, logvar))
  },
  
  #reparameterization 'trick' to ensure back-propagation 
  reparameterize = function(mu, logvar) {
    std <- torch_exp(0.5 * logvar)
    eps <- torch_randn_like(std)
    return(mu + eps * std)
  },
  
  #decoder forward pass for zero-inflation
  decode_zero = function(z) {
    h4 <- nnf_relu(self$fc4_zero(z))
    h5 <- nnf_relu(self$fc5_zero(h4))
    h6 <- nnf_relu(self$fc6_zero(h5))
    return(torch_sigmoid(self$output_zero(h6)))
  },
  
  #decoder forward pass for positive values
  decode_positive = function(z) {
    h4 <- nnf_relu(self$fc4_positive(z))
    h5 <- nnf_relu(self$fc5_positive(h4))
    h6 <- nnf_relu(self$fc6_positive(h5))
    mu <- self$output_mu(h6)
    logvar <- self$output_logvar(h6)
    return(list(mu, logvar))
  },
  
  #forward pass
  forward = function(x) {
    mu_logvar <- self$encode(x)
    mu <- mu_logvar[[1]]
    logvar <- mu_logvar[[2]]
    z <- self$reparameterize(mu, logvar)
    p_zero <- self$decode_zero(z)
    positive_params <- self$decode_positive(z)
    return(list(p_zero, positive_params, mu, logvar))
  }
)

#hurdle gaussian loss
hurdle_gaussian_loss <- function(p_zero, positive_params, x) {
  #Separate zero and non-zero parts of x
  is_zero <- (x == 0)
  non_zero <- (x > 0)
  
  #bernoulli loss for zero-inflation
  bernoulli_loss <- nnf_binary_cross_entropy(p_zero, is_zero$float(), reduction = "sum")
  
  #gaussian loss for positive values
  mu <- positive_params[[1]]
  logvar <- positive_params[[2]]
  gaussian_loss <- 0.5 * torch_sum(logvar[non_zero]) +
    torch_sum((x[non_zero] - mu[non_zero])^2 / torch_exp(logvar[non_zero]))
  
  #combine losses
  #TODO: weight the losses?
  return(bernoulli_loss + gaussian_loss)
}

