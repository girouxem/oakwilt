

if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("dada2", version = "3.10")


library("dada2")

# Unzipped fastq files
path <- '/media/2TB_NVMe/pirl_2020-01-15_ITS1F/tmp'

fnFs <- sort(list.files(path, pattern="_R1_001.fastq", full.names = TRUE))
sample.names <- sapply(strsplit(basename(fnFs), "_"), `[`, 1)
             

# Filter and trim
filtFs <- file.path(path, "filtered", paste0(sample.names, "_F_filt.fastq.gz"))
names(filtFs) <- sample.names
out <- filterAndTrim(fnFs, filtFs, maxN=0, maxEE=2, truncQ=2, minLen=50, 
                     compress=TRUE, multithread=TRUE)

# Learn the Error Rates
errF <- learnErrors(filtFs, multithread=TRUE)

# Sample Inference
dadaFs <- dada(filtFs, err=errF, multithread=TRUE,
               HOMOPOLYMER_GAP_PENALTY=-1, BAND_SIZE=32)

# Construct an amplicon sequence variant table (ASV) table
seqtab <- makeSequenceTable(dadaFs)

# Track reads through the pipeline
getN <- function(x) sum(getUniques(x))
track <- cbind(out, sapply(dadaFs, getN))
colnames(track) <- c("input", "filtered", "denoisedF")
rownames(track) <- sample.names
track

# Assign taxonomy
taxa <- assignTaxonomy(seqtab, "/media/30tb_raid10/db/UNITE/fasta/UNITE_82.fasta", multithread=TRUE)


# Phyloseq





