
<!-- README.md is generated from README.Rmd. Please edit that file -->

# readFCS

<!-- badges: start -->

<!-- badges: end -->

`readFCS` is a single dependency
([Rcpp](https://github.com/RcppCore/Rcpp)) FCS 3.1 reader; comprised of
three sensibly named primary functions, an FCS file can be fully read
using:

| function     | Segment | Description                                    |
|--------------|---------|------------------------------------------------|
| readHEADER() | HEADER  | Contains byte offsets for reading all segments |
| readTEXT()   | TEXT    | Keyword-value pairs                            |
| readDATA()   | DATA    | linear (raw) measurement values                |

By design, `readFCS` does not modify the source .fcs data other than
reading it into memory for assignment; once available in an environment,
users/developers can then access and structure the data as they see fit
(e.g., a list of matrices or concatenated data.table).

## Installation

Install `readFCS` from source
([RTools](https://cran.r-project.org/bin/windows/Rtools/) needed to
build from source (Windows))

``` r
pak::pak("nlaniewski/readFCS")
```

## Read FCS file segments

Included in the package is a single .fcs file for the purpose of
examples:

``` r
fcs.file.path <- system.file("extdata", "CD4 BUV496 (Beads).fcs", package = "readFCS")
```

### readHEADER

`readHEADER()` reads the **HEADER** segment of the FCS file, returning
the byte offsets needed to read all primary file segments (namely,
**TEXT** and **DATA**). A `delimiter` attribute is attached to the
`TEXT` offsets, specifying how the segment (string) will be split to
generate the keyword-value pairs. `$BYTEORD`, `$PAR`, `$TOT`, and
`parameter.names` attributes are attached to the `DATA` offsets,
specifying how the segment (binary stream) will be converted to matrix
and then named (columns).

``` r
offsets <- readFCS::readHEADER(fcs.file.path)
```

``` r
offsets[['version']]
#> [1] "FCS3.1"
offsets[['TEXT']]
#> start   end 
#>   256  7606 
#> attr(,"delimiter")
#> [1] "\f"
offsets[['DATA']]
#>  start    end 
#>   9608 829607 
#> attr(,"$BYTEORD")
#> [1] "1,2,3,4"
#> attr(,"$PAR")
#> [1] 41
#> attr(,"$TOT")
#> [1] 5000
#> attr(,"parameter.names")
#>  [1] "Time"               "SSC-W"              "SSC-H"             
#>  [4] "SSC-A"              "FSC-W"              "FSC-H"             
#>  [7] "FSC-A"              "SSC-B-W"            "SSC-B-H"           
#> [10] "SSC-B-A"            "BUV395-A"           "LIVE DEAD Blue-A"  
#> [13] "BUV496-A"           "BUV563-A"           "BUV615-A"          
#> [16] "BUV661-A"           "BUV737-A"           "BUV805-A"          
#> [19] "BV421-A"            "eFluor 450-A"       "BV480-A"           
#> [22] "BV510-A"            "BV570-A"            "BV605-A"           
#> [25] "BV650-A"            "Super Bright 702-A" "BV750-A"           
#> [28] "BV785-A"            "cFluor B532-A"      "RB613-A"           
#> [31] "PerCP-eFluor 710-A" "RB780-A"            "PE-A"              
#> [34] "Alexa Fluor 594-A"  "RY703-A"            "RY743-A"           
#> [37] "APC-A"              "Alexa Fluor 647-A"  "R718-A"            
#> [40] "APC-H7-A"           "AF-A"
```

### readTEXT

`readTEXT()` reads the **TEXT** segment of the FCS file, splitting the
string by the delimiter and returning a list of keyword-value pairs.

``` r
keywords.values <- readFCS::readTEXT(fcs.file.path)
## index the list using keyword names to access their values
keywords.values[['$CYT']]
#> [1] "Aurora"
keywords.values[['TUBENAME']]
#> [1] "CD4 BUV496 (Beads)"
keywords.values[['$DATE']]
#> [1] "14-Aug-2026"
## index -- list structure
keywords.values[c('$P1N', '$P2N')]
#> $`$P1N`
#> [1] "Time"
#> 
#> $`$P2N`
#> [1] "SSC-W"
## index -- named vector
unlist(keywords.values[c('$P1N', '$P2N')])
#>    $P1N    $P2N 
#>  "Time" "SSC-W"
```

### readDATA

`readDATA()` reads the **DATA** segment of the FCS file, converting the
binary stream (list mode/row-major) into a matrix of linear (raw)
measurement values.

``` r
DATA <- readFCS::readDATA(fcs.file.path)
## linear measurement values -- forward and side scatter
head(DATA[, c('FSC-A', 'SSC-A')])
#>          FSC-A     SSC-A
#> [1,] 1850359.1 1149611.8
#> [2,] 1054235.5  816852.8
#> [3,]  926830.8  891861.3
#> [4,]  943503.2  880870.8
#> [5,] 2187248.5 2047286.0
#> [6,] 1020709.9  884062.8
## linear measurement values -- fluorescence
head(DATA[, 'BUV496-A', drop = FALSE])
#>       BUV496-A
#> [1,]  37913.93
#> [2,]  19391.14
#> [3,]  22474.95
#> [4,]  19690.58
#> [5,] 104084.89
#> [6,]  21660.25
```

## Utility

Combining the return of both `readTEXT()` and `readDATA()` allows for
the creation of structured objects (named lists of matrices with
attached metadata, class-based S3 objects, etc.); those operations are
beyond the scope of this package but `readFCS` should allow
users/developers to achieve that utility.

## References

Spidlen J, Moore W, Parks D, Goldberg M, Bray C, Bierre P, Gorombey P,
Hyun B, Hubbard M, Lange S, Lefebvre R, Leif R, Novo D, Ostruszka L,
Treister A, Wood J, Murphy RF, Roederer M, Sudar D, Zigon R, Brinkman
RR. Data File Standard for Flow Cytometry, version FCS 3.1. Cytometry A.
2010 Jan;77(1):97-100. doi: 10.1002/cyto.a.20825. PMID: 19937951; PMCID:
PMC2892967. <https://pmc.ncbi.nlm.nih.gov/articles/PMC2892967/>

[FCS 3.1 Normative
Standard](https://pmc.ncbi.nlm.nih.gov/articles/instance/2892967/bin/NIHMS203250-supplement-Supp_Fig_1.pdf)

Original author of the C++ reader: [SamGG](https://github.com/SamGG)
(<https://github.com/i-cyto/flowCoreUtils>)
