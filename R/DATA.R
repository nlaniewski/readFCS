readDATA_Bin <- function(fcs.file.path){
  ## use the return of readHEADER()
  ### offsets[["DATA"]]'
  offsets <- readHEADER(fcs.file.path)[["DATA"]]
  ## open a connection to the file (.fcs); read binary mode
  con <- file(fcs.file.path, open = "rb")
  ## close the connection when the function exits
  on.exit(close(con))
  ## seek the byte position where the DATA segment/stream starts
  seek(con, offsets['start'])
  ## read data stream: binary --> numeric --> matrix
  matrix(
    data = readBin(
      con = con,
      what = "numeric",
      n = (diff(offsets) + 1)/(32/8),#list mode storage with floating point = 32 bit width / 8 bits = 4 bytes
      size = 32/8,#list mode storage with floating point = 32 bit width / 8 bits = 4 bytes,
      signed = TRUE,#positive and negative numbers,
      endian = switch(
        attributes(offsets)[['$BYTEORD']],
        '1,2,3,4' = 'little',
        '4,3,2,1' = "big"
      )
    ),
    nrow = attr(offsets, which = '$TOT'),
    ncol = attr(offsets, which = '$PAR'),
    byrow = TRUE,#row-major data stream
    dimnames = list(NULL, attr(offsets, which = 'parameter.names'))
  )
}

#' @title Read the DATA segment of an FCS file.
#'
#' @description
#' `readDATA` reads the DATA segment of an FCS file and returns a matrix of the linear measurement values. `readDATA` defaults to using compiled C++ code to:
#'  \itemize{
#'    \item read the entire binary stream into a flat buffer (float 32-bit)
#'    \item from the buffer, fill a matrix row-by-row (FSC list-mode data is row-major)
#'  }
#'
#' @param fcs.file.path Character string; an explicit file path, usually returned from [list.files].
#'
#' @references
#' Spidlen J, Moore W, Parks D, Goldberg M, Bray C, Bierre P, Gorombey P, Hyun B, Hubbard M, Lange S, Lefebvre R, Leif R, Novo D, Ostruszka L, Treister A, Wood J, Murphy RF, Roederer M, Sudar D, Zigon R, Brinkman RR. Data File Standard for Flow Cytometry, version FCS 3.1. Cytometry A. 2010 Jan;77(1):97-100. doi: 10.1002/cyto.a.20825. PMID: 19937951; PMCID: PMC2892967. <https://pmc.ncbi.nlm.nih.gov/articles/PMC2892967/>
#'
#' [FCS 3.1 Normative Standard](https://pmc.ncbi.nlm.nih.gov/articles/instance/2892967/bin/NIHMS203250-supplement-Supp_Fig_1.pdf) Sections:
#'  \itemize{
#'    \item 2.2.7
#'    \item 2.2.8
#'    \item 2.2.9
#'    \item 2.2.12
#'    \item 3.3
#'  }
#'
#' Original author of the C++ reader: [SamGG](https://github.com/SamGG) <https://github.com/i-cyto/flowCoreUtils>
#'
#' @returns A matrix of linear values; each row represents one event; each column represents one measurement (parameter). As only the '$PnN' names are guaranteed (in a compliant file) to be unique, they are used to name the columns.
#' @export
#'
#' @examples
#' fcs.file.path <- list.files(
#' system.file("extdata", package = "readFCS"),
#' full.names = TRUE,
#' pattern = ".fcs"
#' )
#'
#' ## read the DATA segment to get linear data
#' DATA <- readDATA(fcs.file.path)
#'
#' class(DATA)
#' str(DATA)
#' colnames(DATA)
#'
#' ## plot FSC-A vs SSC-A (linear)
#' plot(DATA[, c('FSC-A', 'SSC-A')], pch = '.')
#'
#' ## plot fluorescence (linear)
#' plot(DATA[, c('BUV496-A', 'FSC-A')], pch = '.')
#'
#' ## plot fluorescence (transformed)
#' plot(asinh(DATA[, 'BUV496-A']/500), DATA[, 'FSC-A'], pch = '.')
#'
readDATA <- function(fcs.file.path){
  ## use the return of readHEADER()
  ### offsets[["DATA"]]'
  offsets <- readHEADER(fcs.file.path)[["DATA"]]
  ##
  DATA <- readDATAcpp(
    file_path = fcs.file.path,
    byte_offset = offsets[['start']],
    TOT = attr(offsets, which = '$TOT'),
    PAR = attr(offsets, which = '$PAR'),
    swap = !identical(attr(offsets, which = '$BYTEORD'), "1,2,3,4")
  )
  ##
  colnames(DATA) <- attr(offsets, which = 'parameter.names')
  ##
  return(DATA)
}


