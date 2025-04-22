#' @title WriteSeuratToAnnData
#' @description Write Seurat object to an AnnData-digestable format.
#' @param seuratObj Seurat object to write.
#' @param ouputPath Path to the output directory.
#' @param assayName Name of the Seurat assay to write to AnnData.
#' @param layer Seurat layer to write to AnnData.
#' @param overwrite Overwrite the file if it already exists.
#' @export

WriteSeuratToAnnData <- function(seuratObj,
                                 outputPath = "./seuratToAnnDataOutput",
                                 assayName = "RNA",
                                 layer = 'counts',
                                 overwrite = FALSE) {
  #create the directory if it doesn't exist
  if (!dir.exists(outputPath)) {
    dir.create(outputPath, recursive = T)
  }
  #write the desired layer in 10X format
  DropletUtils::write10xCounts(x = Seurat::GetAssayData(seuratObj, 
                                                        assay = assayName, 
                                                        layer = layer),
                               path = R.utils::getAbsolutePath(paste0(outputPath, "/GEX.h5"), 
                                                               mustWork = FALSE),
                               overwrite = TRUE)
}