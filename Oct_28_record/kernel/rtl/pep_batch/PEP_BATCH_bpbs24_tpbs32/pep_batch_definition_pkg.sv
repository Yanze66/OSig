// ==============================================================================================
// BSD 3-Clause Clear License
// Copyright © 2025 ZAMA. All rights reserved.
// ----------------------------------------------------------------------------------------------
// Description  :
// ----------------------------------------------------------------------------------------------
// /!\ Generated file : do not modify it /!\
//
// Parameters that defines the pe_pbs.
// Do not use this package directly in modules. Use pep_common_param_pkg instead.
// This purpose of this package is to ease the tests/synthesis with various localparam sets.
// ==============================================================================================

package pep_batch_definition_pkg;
  import common_definition_pkg::*;

  localparam int GRAM_NB = 4; // This value is the one that better overlaps the read and
                                        // write processes in the mmacc. Doesn't have to be a
                                        // power of two.

  // Number of batches in the processing pipe
  localparam int BATCH_NB = 1;
  localparam int TOTAL_BATCH_NB = 1;  // Should be a multiple of BATCH_NB

  // Maximum number of processed PBS per batch.
  // The optimal value depend on the NTT architecture and the keys loading bandwidth.
  // In HPU should be a multiple of GRAM_NB = 4.
  localparam int BATCH_PBS_NB = 24;

  // Total number of PBS that can be stored in HPU.
  // In HPU should be a multiple of GRAM_NB = 4.
  // Is >= BATCH_PBS_NB.
  localparam int TOTAL_PBS_NB = 32;
endpackage