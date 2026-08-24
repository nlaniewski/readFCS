#' @title Read the TEXT segment of an FCS file.
#'
#' @description
#' `readTEXT` reads the TEXT segment of an FCS file and returns all keyword-value pairs.
#'
#' @param fcs.file.path Character string; an explicit file path, usually returned from [list.files].
#' @param return.string Logical -- default `FALSE`; if `TRUE`, return the full (unparsed/split) string.
#' @param con `NULL`; a [file] connection -- used internally.
#' @param offsets  `NULL`; the return of [readHEADER] -- used internally.
#'
#' @references
#' Spidlen J, Moore W, Parks D, Goldberg M, Bray C, Bierre P, Gorombey P, Hyun B, Hubbard M, Lange S, Lefebvre R, Leif R, Novo D, Ostruszka L, Treister A, Wood J, Murphy RF, Roederer M, Sudar D, Zigon R, Brinkman RR. Data File Standard for Flow Cytometry, version FCS 3.1. Cytometry A. 2010 Jan;77(1):97-100. doi: 10.1002/cyto.a.20825. PMID: 19937951; PMCID: PMC2892967. <https://pmc.ncbi.nlm.nih.gov/articles/PMC2892967/>
#'
#' [FCS 3.1 Normative Standard](https://pmc.ncbi.nlm.nih.gov/articles/instance/2892967/bin/NIHMS203250-supplement-Supp_Fig_1.pdf) Sections:
#'  \itemize{
#'    \item 2.2.6
#'    \item 2.2.15
#'    \item 3.2
#'  }
#'
#' @returns A list of keyword-value pairs.
#' @export
#'
#' @examples
#' fcs.file.path <- list.files(
#' system.file("extdata", package = "readFCS"),
#' full.names = TRUE,
#' pattern = ".fcs"
#' )
#'
#' ## read the TEXT segment to get keyword-value pairs
#' keywords.values <- readTEXT(fcs.file.path)
#'
#' ## index the list to return specific values
#' keywords.values[['$CYT']]#cytometer
#' keywords.values[['$FIL']]#filename
#'
#' ## grep to search (e.g., '$PnN')
#' parameter.names <- grep("\\$P[0-9]+N", names(keywords.values))
#' unlist(keywords.values[parameter.names])
#'
#' ## build a data.frame to include specific metadata
#' data.frame(
#'   cytometer = keywords.values[['$CYT']],
#'   serial.number = keywords.values[['$CYTSN']],
#'   sample.id = keywords.values[['TUBENAME']],
#'   data.acquired = keywords.values[['$DATE']]
#' )
#'
readTEXT <- function(fcs.file.path, return.string = FALSE, con = NULL, offsets = NULL){
  if(is.null(con) & is.null(offsets)){
    ## use the return of readHEADER()
    ### offsets[["TEXT"]]'
    offsets <- readHEADER(fcs.file.path)[["TEXT"]]
    ## open a connection to the file (.fcs); read binary mode
    con <- file(fcs.file.path, open = "rb")
    ## close the connection when the function exits
    on.exit(close(con))
  }
  ## seek the byte position where the TEXT segment starts
  seek(con, where = offsets['start'])
  ## hex/ASCII encoded keyword-value pairs
  txt <- readBin(
    con = con,
    what = "raw",
    n = diff(offsets) + 1
  )
  ## convert
  txt <- rawToChar(txt)
  ## return the unparsed TEXT as a string
  if(return.string){
    return(txt)
  }
  ## delimiter
  delimiter <- substr(txt, 1, 1)
  ## split the string; start at position 2
  kv <- strsplit(substr(txt, 2, nchar(txt)), delimiter, fixed = TRUE)[[1]]
  ## keyword value pairs; keyword name (odd) and value (even)
  kv <- stats::setNames(
    kv[seq_along(kv) %% 2 != 1],
    nm = kv[seq_along(kv) %% 2 == 1]
  )
  ## as a list
  kv <- as.list(kv)
  ##
  return(kv)
}

parameters <- function(fcs.file.path, return.type = c('list', 'data.frame')){
  ## use the return of readTEXT()
  kv <- readTEXT(fcs.file.path)
  ## number of parameters in an event
  par.n <- as.numeric(kv[['$PAR']])
  ## regex pattern to find '$P#' and 'P#
  par.pattern <- "^\\$?P\\d+"
  parameter.names <- grep(
    pattern = par.pattern,
    x = names(kv),
    value = TRUE
  )
  ## parameters; named vector
  pars <- trimws(unlist(kv[parameter.names]))
  ## split parameters vector into 'types'; list
  par.types <- split(x = pars, f = factor(sub(par.pattern, "", names(pars))))
  ## return
  switch(
    match.arg(return.type),
    list = par.types,
    data.frame = parameter.frame(par.types)
  )
}

parameter.frame <- function(par.types){
  ## maximum number of parameters
  par.n <- max(sapply(par.types, length))
  ## empty data.frame
  parameter.frame <- data.frame(
    matrix(character(), nrow = par.n, ncol = length(par.types) + 1)
  )
  ## set column names
  colnames(parameter.frame) <- c('par', names(par.types))
  ## fill the 'par' column
  parameter.frame[['par']] <- paste0("$P", seq_len(par.n))
  ## fill based on parameter type
  for (j in names(par.types)) {
    par.vec <- par.types[[j]]
    par.i <- as.integer(gsub("\\D+", "", names(par.vec)))
    parameter.frame[[j]][par.i] <- par.vec
  }
  ##
  return(parameter.frame)
}

spill <- function(fcs.file.path){
  ## use the return of readTEXT()
  kv <- readTEXT(fcs.file.path)
  ## spill/spillover keyword name
  spill.name <- grep('spill', names(kv), ignore.case = TRUE, value = T)
  ## parse the spillover string
  if(length(spill.name) == 1){
    spillover.string <- kv[[spill.name]]
    spill.split <- unlist(strsplit(spillover.string, ","))
    n.cols <- as.numeric(spill.split[1])
    col.names <- spill.split[2:(n.cols + 1)]
    vals <- as.numeric(spill.split[(n.cols + 2):length(spill.split)])
    ##
    matrix(
      data = vals,
      nrow = n.cols,
      ncol = n.cols,
      byrow = TRUE,
      dimnames = list(col.names, col.names)
    )
  }else{
    NULL
  }
}
