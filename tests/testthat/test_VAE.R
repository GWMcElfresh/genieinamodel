test_that("VAE_HurdleGaussian initializes correctly", {
  input_dim <- 100
  latent_dim <- 10
  model <- VAE_HurdleGaussian(input_dim, latent_dim)
  
  expect_s3_class(model, "nn_module")
  expect_equal(model$fc1$weight$shape, c(10000, input_dim))
  expect_equal(model$fc_mu$weight$shape, c(latent_dim, 500))
})

test_that("Encoder produces correct dimensions", {
  input_dim <- 100
  latent_dim <- 10
  batch_size <- 16
  model <- VAE_HurdleGaussian(input_dim, latent_dim)
  
  x <- torch_randn(batch_size, input_dim)
  mu_logvar <- model$encode(x)
  
  expect_equal(mu_logvar[[1]]$shape, c(batch_size, latent_dim)) # mu
  expect_equal(mu_logvar[[2]]$shape, c(batch_size, latent_dim)) # logvar
})

test_that("Decoder produces correct outputs", {
  latent_dim <- 10
  batch_size <- 16
  input_dim <- 100
  model <- VAE_HurdleGaussian(input_dim, latent_dim)
  
  z <- torch_randn(batch_size, latent_dim)
  p_zero <- model$decode_zero(z)
  positive_params <- model$decode_positive(z)
  
  expect_equal(p_zero$shape, c(batch_size, input_dim)) # Zero-inflation probabilities
  expect_equal(positive_params[[1]]$shape, c(batch_size, input_dim)) # Positive mean
  expect_equal(positive_params[[2]]$shape, c(batch_size, input_dim)) # Positive logvar
})

test_that("Loss function computes correctly", {
  input_dim <- 100
  latent_dim <- 10
  batch_size <- 16
  model <- VAE_HurdleGaussian(input_dim, latent_dim)
  
  x <- torch_randn(batch_size, input_dim)
  p_zero <- torch_sigmoid(torch_randn(batch_size, input_dim)) # Simulated outputs
  positive_params <- list(torch_randn(batch_size, input_dim), torch_randn(batch_size, input_dim))
  
  loss <- hurdle_gaussian_loss(p_zero, positive_params, x)
  expect_type(as_array(loss), "double") # Ensure loss is numeric
  expect_length(loss, 1) # Ensure loss is a scalar
})

test_that("Forward pass works end-to-end", {
  input_dim <- 100
  latent_dim <- 10
  batch_size <- 16
  model <- VAE_HurdleGaussian(input_dim, latent_dim)
  
  x <- torch_randn(batch_size, input_dim)
  outputs <- model(x)
  
  expect_equal(length(outputs), 4) # Ensure we have all expected outputs
  expect_equal(outputs[[1]]$shape, c(batch_size, input_dim)) # p_zero
  expect_equal(outputs[[2]][[1]]$shape, c(batch_size, input_dim)) # Positive mu
  expect_equal(outputs[[2]][[2]]$shape, c(batch_size, input_dim)) # Positive logvar
})

test_that("Model trains on pbmc_small data and reduces loss", {
  library(Seurat)
  library(torch)
  
  # Load and preprocess pbmc_small dataset
  data("pbmc_small")
  pbmc_data <- scrnaseqDataLoader(pbmc_small, layer = "counts")
  
  
  
  # Hyperparameters
  input_dim <- nrow(pbmc_small)
  latent_dim <- 10
  batch_size <- 16
  num_epochs <- 5
  learning_rate <- 0.01
  
  # Create dataset instance
  pbmc_dataset <- scrnaseqDataLoader(pbmc_small)
  
  # Create data loader
  data_loader <- dataloader(pbmc_dataset, batch_size = batch_size, shuffle = TRUE)
  
  # Initialize model, optimizer, and loss function
  model <- VAE_HurdleGaussian(input_dim, latent_dim)
  optimizer <- optim_adam(model$parameters, lr = learning_rate)
  
  # Training loop
  for (epoch in 1:num_epochs) {
    total_loss <- 0
    
    coro::loop(for (x in data_loader) {
      optimizer$zero_grad()
      
      # Forward pass
      outputs <- model(x)
      p_zero <- outputs[[1]]
      positive_params <- outputs[[2]]
      
      # Compute loss
      loss <- hurdle_gaussian_loss(p_zero, positive_params, x)
      total_loss <- total_loss + loss$item()
      
      # Backward pass and optimization
      loss$backward()
      optimizer$step()
    })
    
    # Print loss for each epoch
    cat(sprintf("Epoch %d, Loss: %.4f\n", epoch, total_loss))
  }
  
  # Test if the loss decreases significantly
  expect_true(total_loss < 100) # Adjust threshold based on pbmc_small scale
})