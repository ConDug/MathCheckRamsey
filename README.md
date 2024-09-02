# MathCheckRamsey: Ramsey Graph Generation and Verification

This repository contains a collection of scripts and tools for generating, solving, and verifying Ramsey graph problems using SAT solvers and Computer Algebra Systems (CAS).

## Components

- `gen_cubes`: Generates cubes for the cube-and-conquer approach.
- `gen_instance`: Contains scripts to generate SAT instances of a specific order with certain constraints.
- `maplesat-ks`: A modified MapleSAT solver with orderly generation (SAT + CAS).
- `cadical-ks`: A modified CaDiCaL solver with orderly generation (SAT + CAS).
- `simplification`: Scripts for the simplification process in the pipeline.
- `AlphaMapleSAT`: A MCTS-based cubing solver used in the pipeline.

## Key Scripts

- `cube-solve.sh`: Performs iterative cubing, merges cubes into the instance, simplifies with CaDiCaL+CAS, and solves with MapleSAT+CAS.
- `dependency-setup.sh`: Sets up all required dependencies. Run with `./dependency-setup.sh`
- `main.sh`: Main driver script that executes the entire pipeline. Usage: `./main.sh n` (where n is the graph order)

## Pipeline Overview

1. Instance Generation: Creates a SAT instance for a Ramsey graph problem.
2. Cube-and-Conquer: Uses a combination of cubing and SAT solving techniques.
3. Simplification: Reduces the complexity of the problem instance.
4. Solving: Utilizes modified SAT solvers (MapleSAT-ks, CaDiCaL-ks) with CAS integration.
5. Verification: Ensures the validity of the solutions found.

## Setup and Execution

1. Run `./dependency-setup.sh` to set up MapleSAT-ks, CaDiCaL-ks, and AlphaMapleSAT.
2. Execute `./main.sh n` to run the entire pipeline for a graph of order n.

For more detailed information on each component and script, refer to the individual directories and script documentation.
