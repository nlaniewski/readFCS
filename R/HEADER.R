#' @title Read the HEADER segment of an FCS file.
#'
#' @description
#' `readHEADER` reads the HEADER segment of an FCS file and returns the necessary byte offsets to read all segments contained within the file:
#'  \itemize{
#'    \item [`TEXT`][readTEXT]
#'    \item [`DATA`][readDATA]
#'    \item `ANALYSIS`
#'    \item `OTHER`
#'    }
#'
#' @param fcs.file.path Character string; an explicit file path, usually returned from [list.files].
#' @param drop.empty Logical -- default `TRUE`; drop empty offsets/segments.
#'
#' @note
#' `readHEADER` will return appropriate byte offsets (and attached attributes) for **COMPLIANT** FCS files; in some cases, instrument manufacturers and third-party (proprietary) software have been known to violate the FCS 3.1 standard, resulting in a non-compliant file that could fail to read.
#'
#' @references
#' Spidlen J, Moore W, Parks D, Goldberg M, Bray C, Bierre P, Gorombey P, Hyun B, Hubbard M, Lange S, Lefebvre R, Leif R, Novo D, Ostruszka L, Treister A, Wood J, Murphy RF, Roederer M, Sudar D, Zigon R, Brinkman RR. Data File Standard for Flow Cytometry, version FCS 3.1. Cytometry A. 2010 Jan;77(1):97-100. doi: 10.1002/cyto.a.20825. PMID: 19937951; PMCID: PMC2892967. <https://pmc.ncbi.nlm.nih.gov/articles/PMC2892967/>
#'
#' [FCS 3.1 Normative Standard](https://pmc.ncbi.nlm.nih.gov/articles/instance/2892967/bin/NIHMS203250-supplement-Supp_Fig_1.pdf) Sections:
#'  \itemize{
#'    \item 2.2.4
#'    \item 3.1
#'  }
#'
#' @returns A list containing the necessary byte offsets to read the primary segments of the .fcs file.
#' @export
#'
#' @examples
#' fcs.file.path <- list.files(
#' system.file("extdata", package = "readFCS"),
#' full.names = TRUE,
#' pattern = ".fcs"
#' )
#'
#' ## read the HEADER segment to get byte offsets
#' offsets <- readHEADER(fcs.file.path)
#' names(offsets)
#'
#' ## version
#' offsets[['version']]
#'
#' ## byte offsets to read the TEXT segment
#' ### delimiter attached as an attribute
#' #### used to split the TEXT string into keyword-value pairs
#' offsets[['TEXT']]
#'
#' ## byte offsets to read the DATA segment
#' ### '$BYTEORD', '$PAR', '$TOT', and 'parameter.names' attached as attributes
#' #### used to read the binary stream and convert row-major values into matrix
#' offsets[['DATA']]
#'
readHEADER <- function(fcs.file.path, drop.empty = TRUE){
  ## open a connection to the file
  con <- file(fcs.file.path, open = "rb")
  ## close the connection when the function exits
  on.exit(close(con))

  ## HEADER segment
  ### version:          (6 + 4) bytes
  ### TEXT segment:     (8*2) bytes
  ### DATA segment:     (8*2) bytes
  ### ANALYSIS segment: (8*2) bytes
  ### OTHER segment:    ...
  ### (6 + 4) + 8*2 + 8*2 + 8*2 = 58 bytes

  ## .fcs HEADER: version
  ### first 10 bytes (6 (version identifier) + 4 space characters (ASCII 32))
  version <- readChar(con, 6)
  right.padding <- readChar(con, 4)
  if (!version %in% sprintf("FCS3.%d", 0:2)) {
    stop("Is this a .fcs file (version 3.0, 3.1, or 3.2)?")
  }
  if (right.padding != sprintf("%4s", "")) {
    stop("Non-conformant .fcs HEADER (version).")
  }
  ## initialize a list for storing byte offsets
  offsets <- stats::setNames(
    vector(mode = "list", length = 4L),
    nm = c("version", "TEXT", "DATA", "ANALYSIS")
  )
  ##
  offsets[['version']] <- version
  ## byte offsets for TEXT, DATA, and ANALYSIS
  ### character strings; 8 bytes; right-justified with space padding
  ### start and end positions
  for(i in c("TEXT", "DATA", "ANALYSIS")){
    offsets[[i]] <- c(
      start = as.integer(readChar(con, 8)),
      end = as.integer(readChar(con, 8))
    )
  }
  ## byte offsets for OTHER segment -- if it exists
  ### Fluidigm CyTOF/Helios .fcs files have XML after DATA
  if(offsets[['TEXT']][['start']] > 58){
    n <- offsets[['TEXT']][['start']] - 58
    seek(con, 58)
    string.binary <- readBin(con, what = "raw", n = n)
    string.character <- rawToChar(string.binary)
    m <- gregexpr('[0-9]+', string.character)
    offsets[['OTHER']] <- as.numeric(unlist(regmatches(string.character, m)))
  }
  ## TEXT segment
  ### store the delimiter as an attribute
  seek(con, offsets[['TEXT']]['start'])
  attr(offsets[['TEXT']], 'delimiter') <- readChar(con, nchars = 1)
  ## DATA segment
  ### if larger than 99,999,999 bytes: offsets will be '0'
  ### update DATA offsets using keyword-value pairs stored in TEXT segment
  ### need '$BEGINDATA' and '$ENDDATA' to update offsets
  ### store as attributes:
  #### '$BYTEORD' ('endianness');
  #### '$PAR' (number of parameters in an event -- columns);
  #### '$TOT' (total number of events -- rows);
  #### 'parameter.names' ('$P[0-9]+N'; required keyword-value pair; unique name)
  kv <- readTEXT(con = con, offsets = offsets[['TEXT']])
  offsets[['DATA']] <- replace(
    offsets[['DATA']],
    values = as.numeric(unlist(kv[c('$BEGINDATA', '$ENDDATA')]))
  )
  attr(offsets[['DATA']], '$BYTEORD') <- kv[['$BYTEORD']]
  attr(offsets[['DATA']], '$PAR') <- as.numeric(kv[['$PAR']])
  attr(offsets[['DATA']], '$TOT') <- as.numeric(kv[['$TOT']])
  ##
  parameter.names <- unlist(kv[grep("\\$P\\d+N", names(kv), value = T)])
  i <- order(as.numeric(gsub("\\D", "", names(parameter.names))))
  parameter.names <- as.vector(parameter.names[i])
  attr(offsets[['DATA']], 'parameter.names') <- parameter.names
  ## drop empty offsets; namely, 'ANALYSIS' and 'OTHER'
  if(drop.empty){
    offsets <- offsets[!sapply(offsets, function(i){all(i == 0)})]
  }
  ##
  return(offsets)
}
