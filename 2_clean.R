## Patrick Miller
## RRV: 2015-11-24
## Purpose: use R to clean, prep meta-analysis files for ldpred
##  1. Add chromosome and base pair position from plink bim
##  2. Reorder columns for "STANDARD" format
##  3. change column names
##  4. Write to ssf 

## Notes:
##  1. SNPs without information in the plink.bim files are removed. There is code here to do and NCBI lookup.. but it takes forever


#library(rsnps) # for chromosome and pase pair position

## args received from do_ldpred
args <- commandArgs(trailingOnly = TRUE)
fn <- args[1]
gname <- args[2]
outname <- args[3]
print(paste0("In 2_clean.R with fn=",fn,"  gname=",gname, "  out=",outname))

#data.dir <- "../3_subsets/0_ma/dropntr/"
#all.fn <- list.files(data.dir)
#fn <- grep(mname,all.fn,value=TRUE,perl=TRUE) # matches the dot (\.tbl) not followed by another dot
#print(getwd())
#print(list.files(data.dir))

#ssf.names <- gsub("MetaAnalysis_","ldpred_ssf_",fn)

## 0. loads a table of meta analysis summary statistics called d 
print(paste0("loading ma file ", fn))
d <- read.delim(fn)
print(paste0("file ",fn," loaded"))

## 1. Add chromosome identification and base pair position

## nmarkers <- length(d$MarkerName)
## chunk.size <- 100
## j <- 1
## snp.info <- data.frame()
## while(j < nmarkers){
##     jx <- j:(min(nmarkers,(j+chunk.size-1)))
##     inf <- try(NCBI_snp_query(as.character(d$MarkerName[jx]))) # likely takes a lot of time
##     tries <- 0
##     while (inherits(inf, "try-error") & tries < 10) {
##         print(paste0("retry #",tries))
##         inf <- try(NCBI_snp_query(as.character(d$MarkerName[jx]))) # likely takes a lot of time
##     	tries <- tries + 1
##     }    
##     if(!inherits(inf, "try-error")){
##         print("snp.info made with no errors")
##         print(paste0("obtained snp info for indices ",jx[1],"-",tail(jx,1)))
##         snp.info <- rbind(snp.info,inf)
##     } else {
##         print("snp.info could not be made without errors")
##     }
##     j <- max(jx)+1
## }

## merge on most recent snp id. Unmatched names will have NA chromosome and bp positions
## snpinf.short <- snp.info[,c(3,2,10)]
## colnames(snpinf.short)[1] <- "MarkerName"

## Load conversion file
##conv <- read.table("../3_subsets/raw/Conversion_Files/1000G_RStoCBP_b37_All.txt",header=FALSE,as.is=TRUE,sep="\t")


#snps.rs <- read.table("../3_subsets/raw/MRG7_2MZ_CIQC_RS_PM.bim")
print("reading genetic data")
snps.rs <- read.table(paste0(gname,".bim"))
colnames(snps.rs) <- c("chr","MarkerName","dist","bp","Allele1","Allele2")
print("merging genetic data with ma results")
dm <- merge(d,snps.rs,by="MarkerName",all.x=TRUE) #
dm$chr <- paste0("chr",dm$chr)
dm$info <- 1
print("cleaning file")
## [1] "MarkerName" "Allele1.x"  "Allele2.x"  "Freq1"      "FreqSE"    
## [6] "MinFreq"    "MaxFreq"    "Effect"     "StdErr"     "P.value"   
## [11] "Direction"  "HetISq"     "HetChiSq"   "HetDf"      "HetPVal"   
## [16] "NTot"       "chr"        "dist"       "bp"         "Allele1.y" 
## [21] "Allele2.y"  "info"   
## Allele1 is major (reference) allele
## Freq1 is frequency of the major (reference) allele

## The LDpred "STANDARD" format is as follows:
##    chr     pos     ref     alt     reffrq  info    rs           pval    effalt
##    chr1    1020428 C       T       0.85083 0.98732 rs6687776    0.0587  -0.0100048507289348
##    chr1    1020496 G       A       0.85073 0.98751 rs6678318    0.1287  -0.00826075392985992
## reffrq = frequency of reference allele
## info = imputation quality
## effalt = effect of the alternative allele (the beta)

## 2. reorder columns to obtain clean version
                                        #ss.clean <- d[,c(17,18,2:4,19,1,10,8)]
ss.clean <- dm[,c("chr","bp","Allele1.y","Allele2.y","Freq1","info","MarkerName","P.value","Effect")]

## 3. Change names
colnames(ss.clean) <- c("chr","pos","ref","alt","reffrq","info","rs","pval","effalt")
print("file cleaned. Head:")

##  ss.clean now looks like:
#    chr       pos ref alt reffrq info         rs    pval  effalt
#1  chr9 124003326   C   A 0.5149    1 rs10760160 0.67990 -0.0036
#2 chr11 100009976   G   A 0.8665    1 rs12364336 0.36290 -0.0118
#3  chr1 166367755   G   A 0.7619    1 rs12562373 0.05846 -0.0200
#4 chr14  25713464   G   T 0.7534    1 rs17278013 0.49580 -0.0070
#5 chr13 113272878   A   G 0.0570    1  rs7323548 0.37280 -0.0182
#6  chr7  34448765   G   A 0.9364    1   rs977590 0.27440 -0.0258
## Not sure if this is necessary
snps.rm <- sum(!complete.cases(ss.clean))
ss.clean <- ss.clean[complete.cases(ss.clean),]
print(head(ss.clean,3))
print(paste0("M = ", nrow(ss.clean), " snps obtained"))
print(paste0("M =  ",snps.rm," snps with missing information"))

print(paste0("writing file ",outname)) 
write.table(ss.clean,file=outname,row.names=FALSE,quote=FALSE)



