#include <Rcpp.h>
#include <fstream>
#include <stdexcept>
#include <vector>
#include <algorithm>

using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix readDATAcpp_indexed(
    const std::string& file_path,
    long byte_offset,
    long TOT,
    long PAR,
    bool swap,
    IntegerVector keep_cols // Added: 0-indexed vector of column indices to keep
) {
  // validate dimensions before allocating
  if (TOT <= 0) stop("TOT must be positive");
  if (PAR <= 0) stop("PAR must be positive");

  long NEW_PAR = keep_cols.size();
  if (NEW_PAR <= 0) stop("keep_cols must contain at least one column index");

  // Validate bounds of keep_cols to prevent segmentation faults
  for (int i = 0; i < NEW_PAR; ++i) {
    if (keep_cols[i] < 0 || keep_cols[i] >= PAR) {
      stop("Index in keep_cols out of bounds for matrix with " + std::to_string(PAR) + " columns.");
    }
  }

  // We still read the full row dimension from file to preserve sequential disk layout
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

  // Allocate a compacted matrix matching only the preserved column count
  NumericMatrix data_mat(TOT, NEW_PAR);
  double* out = data_mat.begin();
  const float* in = buf.data();

  // Optimized Cache-Blocking (Tiling) Loop Integration
  const long BLOCK_SIZE = 64;

  for (long r_block = 0; r_block < TOT; r_block += BLOCK_SIZE) {
    for (long c_block = 0; c_block < NEW_PAR; c_block += BLOCK_SIZE) {

      const long r_end = std::min(r_block + BLOCK_SIZE, TOT);
      const long c_end = std::min(c_block + BLOCK_SIZE, NEW_PAR);

      for (long row = r_block; row < r_end; ++row) {
        const float* row_start = in + row * PAR;

        for (long out_col = c_block; out_col < c_end; ++out_col) {
          // Map the output matrix position to the source column
          long in_col = keep_cols[out_col];

          // Write contiguously into the newly sized column-major Rcpp matrix
          out[out_col * TOT + row] = static_cast<double>(row_start[in_col]);
        }
      }
    }
  }

  return data_mat;
}
