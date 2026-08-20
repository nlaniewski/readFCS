##
header <- paste0(
  sprintf("FCS3.1%4s", ""),#version
  sprintf("%08s", "256"), sprintf("%08s", "1545"),#TEXT
  sprintf("%08s", "1792"), sprintf("%08s", "202455"),#DATA
  sprintf("%08s", "0"), sprintf("%08s", "0"),#ANALYSIS
  sprintf("%08s", "202455"), sprintf("%08s", "20400")#OTHER
)

kw <- keywords_required
kw <- setNames(vector(mode = "character", length = length(kw)), nm = kw)
kw[grep("ANALYSIS", names(kw), value = T)] <- c(0, 0)
kw[['$BYTEORD']] <- '1,2,3,4'
kw[['$DATATYPE']] <- "F"
kw[['$MODE']] <- 'L'
kw[['$NEXTDATA']] <- '0'
kw[grep("TEXT", names(kw), value = T)] <- c(0, 0)


writeBin(header, "./inst/extdata/dummy.fcs")


par <- 64
tot <- 2E5
col.names <- paste0("detector", seq_len(par))

mat <- matrix(
  rnorm(n = par * tot),
  nrow = tot,
  ncol = par,
  byrow = FALSE,
  dimnames = list(NULL, col.names)
)

R <- ceiling(max(mat))

parameters.required <- c("B", "E", "N", "R")

parameters <- sapply(parameters.required, function(i){
  x <- switch(
    i,
    B = rep("32", par),
    E = rep("0,0", par),
    N = col.names,
    R = rep(as.character(R), par)
  )
  setNames(
    x,
    nm = paste0('$P', seq_len(par), i)
  )
}, simplify = F)

c(
  "$BEGINANALYSIS" = 0,
  "$BEGINDATA" = "",
  "$BEGINSTEXT" = 0,
  "$BYTEORD" = "1,2,3,4",
  "$DATATYPE" = 'F',
  "$ENDANALYSIS" = 0,
  "$ENDDATA",#Byte-offset to the last byte of the DATA segment.
  "$ENDSTEXT" = 0,
  "$MODE" = "L",
  "$NEXTDATA" = 0,
  "$PAR" = par,
  "$TOT" = tot
)

header <- paste0(
  sprintf("%-10s", "FCS3.1"),#version
  sprintf("%08s", "256"), sprintf("%08s", "1545"),#TEXT
  sprintf("%08s", "1792"), sprintf("%08s", "202455"),#DATA
  sprintf("%08s", "0"), sprintf("%08s", "0"),#ANALYSIS
  sprintf("%08s", "202455"), sprintf("%08s", "20400")#OTHER
)
