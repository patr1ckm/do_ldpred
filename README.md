# do\_ldpred

The primary purpose of do\_ldpred is to provide an ldpred workflow in a cluster environment (e.g. SGE) that enables distributed computation of ldpred weights for sets of phenotypes 
while minimizing memory footprint and recomputation.

Installation: just copy the scripts and use them.
Requires all of the LDPred requirements (e.g. hdf5, plinkio, etc).

Expects a directory structure like the following:

 - ├── 0_ma
 - ├── 1_genetic
 - ├── 2_ssf
 - ├── 3_coord
 - ├── 4_pred
 - ├── 5_scores

Where 0_ma contains the meta-analysis results/summary statistics, 1\_genetic contains plink files (bed/bim/fam) (up to 2 right now). Currently, files in 2 or 3 can be large, 
and are managed by do\_ldpred. do\_ldpred does not recompute files that already exist in these directories.

The work flow steps are as follows:

  1. 2\_clean.R preps MA files 0\_ma/dropntr for ldpred, putting in 2\_ssf. This involves adding C-BP to the RSnumbers based on plink.bim files in 1\_genetic.
     Since the number of snps is different for the two genetic files (imputed, not imputed), we perform ldpred on each separately storing results in folders /g1, /g2
  2. Coordinates 2\_ssf/ files with genetic data in 1\_genetic/. These files are generally quite large even when compressed (e.g. 2-4GB for 1 or 2.5M SNPs)
     so its best to remove them if ldpred worked.
  3. Runs ldpred on 3\_coord/ dropping weights in 4\_pred/. It takes a long time to calculate LD, so the \*.pickled.gz LD file for 1 phenotype is stored in 4\_pred/g1 4\_pred/g2 etc
  4. Computes polygenic scores for the ldpred weights (and original) using plink, assigns to 5\_scores

Of course, use at your own risk, as it stands you will probably need to modify heavily. It is currently under active development.

To do:

 1. Use command arguments
 2. Loop through genetic files
 3. Script the file setup

