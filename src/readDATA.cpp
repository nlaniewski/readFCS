// https://github.com/i-cyto/flowCoreUtils (SamGG ; Samuel Granjeaud)

#include <Rcpp.h>
#include <fstream>
#include <stdexcept>

using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix readDATAcpp(
    const std::string& file_path,
    long byte_offset,
    long TOT,
    long PAR,
    bool swap
) {
  // validate dimensions before allocating
  if (TOT <= 0) stop("TOT must be positive");
  if (PAR <= 0) stop("PAR must be positive");

  // use long throughout to avoid int overflow on large files
  // (e.g. 5M events x 50 params = 250M values, overflows int32)
  long n_vals = TOT * PAR;

  // open file in binary mode; ifstream closes itself on scope exit (RAII)
  std::ifstream con(file_path, std::ios::binary);
  if (!con.is_open())
    stop("Cannot open file: " + file_path);

  // seek to data segment offset
  con.seekg(byte_offset, std::ios::beg);
  if (con.fail())
    stop("Failed to seek to offset " + std::to_string(byte_offset));

  // read n_vals float32 values into a flat buffer
  std::vector<float> buf(n_vals);
  con.read(reinterpret_cast<char*>(buf.data()), n_vals * sizeof(float));

  // detect partial reads (truncated file or wrong offset)
  if (con.gcount() != static_cast<std::streamsize>(n_vals * sizeof(float)))
    stop("Short read — file may be truncated or byte_offset/TOT/PAR are incorrect. "
           "Expected " + std::to_string(n_vals * sizeof(float)) + " bytes, "
           "got " + std::to_string(con.gcount()));

  // byte-swap if file endian differs from host (big-endian FCS on little-endian host)
  if (swap) {
    for (long k = 0; k < n_vals; k++) {
      char* p = reinterpret_cast<char*>(&buf[k]);
      std::swap(p[0], p[3]);
      std::swap(p[1], p[2]);
    }
  }

  // fill NumericMatrix from row-major float buffer
  // Rcpp matrices are column-major, so we must index (row, col) explicitly —
  // a flat std::copy would transpose the data incorrectly
  NumericMatrix data_mat(TOT, PAR);
  double* out = data_mat.begin();
  const float* in = buf.data();

  for (long row = 0; row < TOT; row++) {
    const float* row_start = in + row * PAR;
    for (long col = 0; col < PAR; col++) {
      // data_mat(row, col) in column-major storage = out[col * TOT + row]
      out[col * TOT + row] = static_cast<double>(row_start[col]);
    }
  }

  return data_mat;

}
