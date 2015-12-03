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

  - `0_ma/` contains raw summary statistics files for phenotypes `phenoname.tbl`
  - `1_plink/` contains genetic data in plink binary format (bed/bim/fam). 

The variables in `do_ldpred` will likely need to be modified. The important ones are noted in the workflow below. The script has been used extensively with LDpred v0.5.

## Workflow

This will submit a job running the LDpred workflow on each of the files `1_plink` as a separate SGE job (mapped to `$SGE_TASK_ID`). 

    qsub do_ldpred phenoname

If SGE is not available, `do_ldpred` can also be run as follows (here for plink file 1):

    ./do_ldpred phenoname 1


Here `phenoname` is just the name of the phenotype. It can contain dashes, digits, ., etc (probably no spaces though).

The following steps are performed:

### 0. Setup

Will create the following folders to store intermediate results of the steps.

    2_ssf/ contains phenoname.ssf
    3_coord/  contains phenoname.coord
    4_pred/  contains weights (phenoname.txt, phenoname.raw)
    5_scores/  
    logs/  contains log files to monitor progress

The location of the files can be specified in the script by setting the `loc` variable. This might be different from the place the scripts are run.

### 1. Cleaning

`do_ldpred` can incorporate cleaning the raw MA files for LDpred into the workflow.  A sample cleaning script (`clean.R`) is included here for demonstration. It adds C-BP positions for RS numbers in `0_ma/` (ending in the convention `phenoname.tbl`) from the plink genetic files, and reorders the columns according to `LDpred.py` STANDARD format. The results are a plain text file placed in `2_ssf` with a filename of the format `phenome.ssf` (SummaryStatisticsFile).

The user will likely need to write a custom script for cleaning the GWAS summary statistic files. If called `clean.R`, such a script can be used directly by `do_ldpred`. Otherwise, the script can be run separately. The results (plain text files with summary statistics in STANDARD format) should be placed in `2_ssf`, with filenames of the format `phenoname.ssf`.

### 2. `coord_genotypes.py`

Runs `coord_genotypes.py` on `phenoname.ssf` on each plink data set in `1_plink`. The sample size for each phenotype is determined by the parameter `--N`, and can be fixed across all phenotypes by setting it specifically in `do_ldpred`, or it can be read separately for each phenotype from a file `ns.txt`, as follows:

    phenoname n
    pheno1    10000
    pheno2    15033

`ns.txt` should be placed in the directory from which `do_ldpred` is run. The results are placed in `3_coord`, and are in the format `phenoname.coord`. These are not plain text files, but binary HDF5 files. 

If `clean=true` the `.coord` files are deleted after a _successful_ run of `ldpred`. They are usually large as they contain a copy of the genetic data, so this should be considered when running ldpred for many phenotypes in parallel.

### 3. `LDpred.py`

Runs `LDpred.py` on `phenoname.coord`, with the given sample size. The ld radius, and ld prefix arguments can be set in the bash script.
The weights are placed in `4_pred`. Since it takes a very long time to calculate LD (>12hrs genomewide) the \*.pickled.gz LD files for the phenotypes are stored in `4_pred/g\*` and should not be removed. The default `LDpred.py` values are used for causal fraction.

### 4. Scores via `plink2`

If `scores=true`, computes polygenic scores for the ldpred weights (and original weights) using `plink2` (that is, [Plink 1.9](https://www.cog-genomics.org/plink2) mapped to the command `plink2`)  to `5_scores` 

## Monitoring Progress

The log files contain the standard output and standard error from the commands that were run. They accurately capture the state of the program while it is running, in contrast to the SGE buffered output files which is only written after completion.

Errors in any step will cause the program to terminate. 

## Disclaimer

Of course, use at your own risk, as it stands you will probably need to modify heavily. `do_ldpred` may also work for other schedulers with a few changes. Suggestions and contributions are welcome. 



