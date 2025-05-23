% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{WriteSeuratToAnnData}
\alias{WriteSeuratToAnnData}
\title{WriteSeuratToAnnData}
\usage{
WriteSeuratToAnnData(
  seuratObj,
  outputPath = "./seuratToAnnDataOutput",
  assayName = "RNA",
  layer = "counts",
  overwrite = FALSE
)
}
\arguments{
\item{seuratObj}{Seurat object to write.}

\item{outputPath}{Path to the output directory.}

\item{assayName}{Name of the Seurat assay to write to AnnData.}

\item{layer}{Seurat layer to write to AnnData.}

\item{overwrite}{Overwrite the file if it already exists.}
}
\description{
Write Seurat object to an AnnData-digestable format.
}
