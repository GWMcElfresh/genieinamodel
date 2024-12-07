utils::globalVariables(c("self"))

#' @title Single Cell RNASeq Dataset Loader
#' @description This module defines a dataset loader for single cell RNASeq data.
#' @param seuratObj Seurat Object containing single cell RNASeq data.
#' @param assay The name of the assay containing the data. 
#' @param layer Seurat object's layer. 
#' @return A dataset loader for single cell RNASeq data.
#' @export

scrnaseqDataLoader <- function(seuratObj, 
                               assay = 'RNA', 
                               layer = 'data') {
  seuratDataset <- dataset(
    initialize = function(seuratObj) {
      self$data <- Seurat::GetAssayData(seuratObj, 
                                        assay = assay, 
                                        layer = layer) %>% 
        as.matrix() %>% 
        Matrix::t() %>% 
        torch_tensor(dtype = torch_float())
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
