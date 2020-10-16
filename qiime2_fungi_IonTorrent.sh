# Qiime2

# Input folder
export fastq=/media/30tb_raid10/data/PIRL/2020-01-15_OAK_ITSF_30

# Output folder
export baseDir=/media/2TB_NVMe/pirl_2020-01-15_ITS1F


#############################

#folders
export qiime2=""${baseDir}"/qiime2"
export trimmed=""${baseDir}"/trimmed"
export logs=""${baseDir}"/logs"


#if forlder does not exists, create it
# -p -> create parent directories if they don't exist
# "||" if test is false
# "&&" if test is true
[ -d "$baseDir" ] || mkdir -p "$baseDir"
[ -d "$qiime2" ] || mkdir -p "$qiime2"
[ -d "$trimmed" ] || mkdir -p "$trimmed"
[ -d "$logs" ] || mkdir -p "$logs"


################################


# Activate environment
source activate qiime2-2019.10


#################
#               #
#   ITSxpress   #
#               #
#################


# Rename files for QIIME2
# L2S357_15_L001_R1_001.fastq.gz. The underscore-separated fields in this file name are:
#     1. the sample identifier,
#     2. the barcode sequence or a barcode identifier,
#     3. the lane number,
#     4. the direction of the read (i.e. only R1, because these are single-end reads), and
#     5. the set number.

function find_ITS()
{
# Retrive ITS1 part of the amplicons
# https://github.com/USDA-ARS-GBRU/q2_itsxpress
    filename=$(basename "$1" '.fastq.gz')
    barcode=$(echo "$filename" | cut -d "_" -f 1)
    # samplename=$(echo "$filename" | cut -d "_" -f 2)
    # newname="${samplename}"_"${barcode}"_L001_R1_001.fastq.gz
    newname="${barcode}"_"${barcode}"-ITS1F_L001_R1_001.fastq.gz

    # ln -s "$i" "${baseDir}"/fastq/"$newname"
    itsxpress \
        --fastq "$1" \
        --single_end \
        --outfile "${trimmed}"/"$newname" \
        --region ITS1 \
        --taxa Fungi \
        --cluster_id 0.995 \
        --log "${baseDir}"/logs/itsxpress/"${barcode}".log \
        --threads 48
}

export -f find_ITS

[ -d "${logs}"/itsxpress ] || mkdir -p "${logs}"/itsxpress

find "${fastq}" -type f -name "*.fastq.gz" \
| parallel  --bar \
            --env find_ITS1 \
            --env baseDir \
            --jobs 4 \
            'find_ITS {}'


#############
#           #
#   DADA2   #
#           #
#############


# Unzip files for dada2
mkdir -p "${baseDir}"/tmp

function uncompress()
{
    outname=$(basename "$1" '.gz')
    pigz -dkc -p 3 "$1" > "${baseDir}"/tmp/"$outname"
}


export -f uncompress

find "$trimmed" -name "*.fastq.gz" \
| parallel --bar --env baseDir 'uncompress {}'


# Dada2
Rscipt --vanilla "${script}"/dada2_IonTorrent.R "${baseDir}"/tmp


##############
#            #
#   QIIME2   #
#            #
##############


# import fastq files
qiime tools import \
    --type 'SampleData[SequencesWithQuality]' \
    --input-path "${baseDir}"/fastq \
    --output-path "${baseDir}"/qiime2/demux-single-end.qza \
    --input-format CasavaOneEightSingleLanePerSampleDirFmt

# Make summary of samples
# Subsample 10,000 reads by default
qiime demux summarize \
    --i-data "${baseDir}"/qiime2/demux-single-end.qza \
    --p-n 1000 \
    --o-visualization "${baseDir}"/qiime2/demux-single-end.qzv \
    --verbose

# View the summary
qiime tools view \
    "${baseDir}"/qiime2/demux-single-end.qzv

# qiime itsxpress trim-single \
#     --i-per-sample-sequences "${baseDir}"/qiime2/demux-single-end.qza \
#     --p-region ITS1 \
#     --p-taxa F \
#     --p-threads $(nproc) \
#     --o-trimmed "${baseDir}"/qiime2/demux-single-end-trimmed.qza \
#     --verbose

# qiime demux summarize \
#     --i-data "${baseDir}"/qiime2/demux-single-end-trimmed.qza \
#     --p-n 1000 \
#     --o-visualization "${baseDir}"/qiime2/demux-single-end-trimmed.qzv \
#     --verbose

# # View the summary
# qiime tools view \
#     "${baseDir}"/qiime2/demux-single-end-trimmed.qzv

# Dada2
# https://benjjneb.github.io/dada2/faq.html#can-i-use-dada2-with-my-454-or-ion-torrent-data
# dada(..., HOMOPOLYMER_GAP_PENALTY=-1, BAND_SIZE=32)
# filterAndTrim(..., maxLen=XXX) # XXX depends on the chemistry
# filterAndTrim(..., trimLeft=15)
qiime dada2 denoise-single \
    --i-demultiplexed-seqs "${baseDir}"/qiime2/demux-single-end.qza \
    --p-trim-left 0 \
    --p-trunc-len 0 \
    --o-representative-sequences "${baseDir}"/qiime2/rep-seqs-dada2.qza \
    --o-table "${baseDir}"/qiime2/table-dada2.qza \
    --o-denoising-stats "${baseDir}"/qiime2/stats-dada2.qza \
    --p-n-threads $(nproc) \
    --verbose












