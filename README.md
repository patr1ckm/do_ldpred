# do\_ldpred

The primary purpose of do\_ldpred is to provide an ldpred workflow in a cluster environment (e.g. SGE) that enables distributed computation of ldpred weights for sets of phenotypes 
while minimizing memory footprint and recomputation. 

Installation: just copy the scripts, setting the appropriate variables in do\_ldpred (please check!).

Requires all of the LDPred requirements (e.g. hdf5, plinkio, etc).

Expects a directory structure like the following:

- 0\_ma contains raw summary statistics files for phenotypes. 
- 1\_plink contains genetic data in plink binary format (bed/bim/fam). LDpred will be run on each of these files in separate SGE jobs (mapped to $SGE\_TASK\_ID)

## Workflow

Invocation

    do\_ldpred phenoname

### 1. Cleaning

do\_ldpred can incorporate cleaning the raw MA files for LDpred into the workflow. A sample file (clean.R) is included here for demonstration.
It adds C-BP positions for RS numbers in the MA files from the plink genetic files, and puts them in standard format.
The user will likely need to do their own cleaning (sorry...). The results should be placed in 2\_ssf, in the format phenoname.ssf.

### 2. ldcoord

Runs ldcoord on phenoname.ssf on each plink data set in 1\_plink. The ldcoord parameter '--N' can be either set in the script, or 
read from a file ns.txt, as follows:

    phenoname n
    pheno1    10000
    pheno2    15033

The results are placed in 3\_coord, and are in the format phenoname.coord. 

If the variable clean=true, the .coord files are deleted after a successful run of ldpred. They are usually large, so this should be considered.

### 3. ldpred

Runs ldpred on pheno.coord, with the given sample size. The ld radius, and ld prefix arguments can be set in the bash script.
The weights are placed in 4\_pred. Since it takes a long time to calculate LD, the \*.pickled.gz LD files for the phenotypes are stored in 4\_pred/g\* 
and can be referenced by setting the ld\_pref variable in do\_ldpred. The default ldpred values are used for causal fraction.

### 4. Scores

Computes polygenic scores for the ldpred weights (and original weights) using plink (\*.raw) to 5\_scores.

Of course, use at your own risk, as it stands you will probably need to modify heavily. It is currently under active development.



