#' @title Single Cell RNASeq Dataset Loader
#' @description This module defines a dataset loader for single cell RNASeq data.
#' @param data A matrix of single cell RNASeq data.
#' @return A dataset loader for single cell RNASeq data.
#' @export

scrnaseqDataLoader <- function(seuratObj, layer = 'data') {
  seuratDataset <- dataset(
    initialize = function(seuratObj) {
      self$data <- Seurat::GetAssayData(seuratObj, slot = layer) %>% 
        as.matrix() %>% 
        Matrix::t() %>% 
        torch_tensor(., dtype = torch_float())
    },
    
    .getitem = function(index) {
      self$data[index, , drop = FALSE]
    },
    
    .length = function() {
      self$data$size(1)
    }
  )
  
  return(seuratDataset(seuratObj))
}
