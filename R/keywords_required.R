keywords_required <- c(
  "$BEGINANALYSIS",#Byte-offset to the beginning of the ANALYSIS segment.
  "$BEGINDATA",#Byte-offset to the beginning of the DATA segment.
  "$BEGINSTEXT",#Byte-offset to the beginning of a supplemental TEXT segment.
  "$BYTEORD",#Byte order for data acquisition computer.
  "$DATATYPE",#Type of data in DATA segment (ASCII, integer, floating point).
  "$ENDANALYSIS",#Byte-offset to the last byte of the ANALYSIS segment.
  "$ENDDATA",#Byte-offset to the last byte of the DATA segment.
  "$ENDSTEXT",#Byte-offset to the last byte of a supplemental TEXT segment.
  "$MODE",#Data mode (list mode - preferred, histogram - deprecated).
  "$NEXTDATA",#Byte offset to next data set in the file.
  "$PAR",#Number of parameters in an event.
  "$PnB",#Number of bits reserved for parameter number n.
  "$PnE",#Amplification type for parameter n.
  "$PnN",#Short name for parameter n.
  "$PnR",#Range for parameter number n.
  "$TOT"#Total number of events in the data set.
)
