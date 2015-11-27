# do\_ldpred

Polygenic scores are linear combinations of SNPs  with weights given by a GWAS or meta analysis (MA).
[LDpred](http://biorxiv.org/content/early/2015/03/04/015859) computes updated weights for polygenic scores correcting for linkage disequilibrium (LD)
 and using a Bayesian point-normal mixture prior for the expected effect sizes. 

`do_ldpred` is a BASH script providing an LDpred workflow for many phenotypes. It is designed to work in a cluster environment (in particular SGE) to enable distributed computation of LDpred weights for sets of phenotypes while minimizing memory footprint and recomputation, and allows continuous monitoring of progress. 

## Installation

Install [LDPred](https://bitbucket.org/bjarni_vilhjalmsson/ldpred). Then just download/clone/copy the scripts for `do_ldpred`.

    git clone git@github.com:patr1ckm/do_ldpred.git 
    chmod +x do_ldpred

`do_ldpred` expects the following directories: 

    0_ma contains raw summary statistics files for phenotypes (.tbl)
    1_plink contains genetic data in plink binary format (bed/bim/fam). 

The variables in `do_ldpred` will likely need to be modified. The important ones are noted in the workflow below.

## Workflow

Invocation

    qsub do_ldpred phenoname

This will submit a job running the LDpred workflow on each of the files `1_plink` as a separate SGE job (mapped to `$SGE_TASK_ID`). 

    ./do_ldpred phenoname 1

Will run `do_ldpred` locally on plink file 1.

The following steps are performed:

### 0. Setup

Will create the following folders to store intermediate results of the steps.

    2_ssf/ contains *.ssf
    3_coord/  contains *.coord
    4_pred/  contains weights (*.txt, *.raw)
    5_scores/  
    logs/  contains log files to monitor progress

The relative location of the files can be specified in the script by setting the `loc` variable.

### 1. Cleaning

`do_ldpred` can incorporate cleaning the raw MA files for LDpred into the workflow. A sample file (`clean.R`) is included here for demonstration.
It adds C-BP positions for RS numbers in the MA files from the plink genetic files, and reorders the columns according to `ldpred` STANDARD format.
The user will likely need to write a custom script for this. The results should be placed in `2_ssf`, with filenames of the format `phenoname.ssf`.

### 2. `ldcoord`

Runs `ldcoord` on `phenoname.ssf` on each plink data set in `1_plink`. The `ldcoord parameter` '--N' can be either set in the script, or 
read from a file `ns.txt`, as follows:

    phenoname n
    pheno1    10000
    pheno2    15033

The results are placed in `3_coord`, and are in the format `phenoname.coord`. 

If `clean=true` the `.coord` files are deleted after a _successful_ run of `ldpred`. They are usually large, so this should be considered when running ldpred
for many phenotypes in parallel.

### 3. `ldpred`

Runs `ldpred` on `pheno.coord`, with the given sample size. The ld radius, and ld prefix arguments can be set in the bash script.
The weights are placed in `4_pred`. Since it takes a long time to calculate LD, the \*.pickled.gz LD files for the phenotypes are stored in `4_pred/g\*`. The default LDpred values are used for causal fraction.

### 4. Scores

If `scores=true`, computes polygenic scores for the ldpred weights (and original weights) using `plink2` (that is, [Plink 1.9](https://www.cog-genomics.org/plink2) mapped to the command `plink2`)  to `5_scores` 

## Monitoring Progress

The log files contain the standard output and standard error from the commands that were run. They accurately capture the state of the program while it is running, in contrast to the SGE buffered output files which is only written after completion.

Errors in any step will cause the program to terminate. 

## Disclaimer

Of course, use at your own risk, as it stands you will probably need to modify heavily. It is currently under active development.



