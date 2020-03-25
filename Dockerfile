FROM phusion/baseimage

RUN apt-get -qq update && apt-get install -y \
    alien \
    cmake \
    debhelper \
    libbz2-dev \
    libxml2-dev \
    libxslt1-dev \
    ncurses-dev \
    openjdk-8-jre \
    pkg-config \
    sshpass \
    unzip \
    wget \
    zlib1g-dev

ENV TOOLS=/tools
RUN mkdir ${TOOLS}

# bcl2fastq
WORKDIR ${TOOLS}
RUN wget https://support.illumina.com/content/dam/illumina-support/documents/downloads/software/bcl2fastq/bcl2fastq2-v2-20-0-linux-x86-64.zip \
    && unzip bcl2fastq2-v2-20-0-linux-x86-64.zip
ENV BCL2FASTQ=bcl2fastq2-v2.20.0.422-Linux-x86_64.rpm
RUN alien -i ${BCL2FASTQ} \
    && rm ${BCL2FASTQ}

# bclconvert, the new bcl2fastq
COPY bin/bcl-convert /usr/bin/bcl-convert
COPY bin/concatenate_lanes /usr/bin/concatenate_lanes

# bwa
WORKDIR ${TOOLS}
RUN wget https://github.com/lh3/bwa/releases/download/v0.7.15/bwa-0.7.15.tar.bz2 \
    && tar -jxf bwa-0.7.15.tar.bz2
WORKDIR ${TOOLS}/bwa-0.7.15
RUN make -j4 \
    && chmod +x bwa \
    && ln -s ${TOOLS}/bwa-0.7.15/bwa /usr/bin/bwa

# fastqc
WORKDIR ${TOOLS}
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip \
    && unzip fastqc_v0.11.5.zip \
    && chmod +x ${TOOLS}/FastQC/fastqc \
    && ln -s ${TOOLS}/FastQC/fastqc /usr/bin/fastqc

# freebayes
WORKDIR ${TOOLS}
RUN git clone --recursive --branch v1.3.1 git://github.com/ekg/freebayes.git
WORKDIR ${TOOLS}/freebayes
# Make cannot be parallelized for freebayes
RUN make \
    && make install

# samtools
WORKDIR ${TOOLS}
RUN wget https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2 \
    && tar -xf samtools-1.9.tar.bz2
WORKDIR ${TOOLS}/samtools-1.9
RUN ./configure \
    && make -j4 \
    && make install

# sambamba
WORKDIR ${TOOLS}
RUN wget https://github.com/lomereiter/sambamba/releases/download/v0.6.5/sambamba_v0.6.5_linux.tar.bz2 \
    && tar -jxf sambamba_v0.6.5_linux.tar.bz2 \
    && chmod +x ${TOOLS}/sambamba_v0.6.5 \
    && ln -s ${TOOLS}/sambamba_v0.6.5 /usr/bin/sambamba

# trimmomatic
WORKDIR ${TOOLS}
RUN wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.36.zip \
    && unzip Trimmomatic-0.36.zip
ENV TRIMMOMATIC_JAR="${TOOLS}/Trimmomatic-0.36/trimmomatic-0.36.jar"

# vcftools
WORKDIR ${TOOLS}
RUN wget https://github.com/vcftools/vcftools/releases/download/v0.1.14/vcftools-0.1.14.tar.gz \
    && tar -zxf vcftools-0.1.14.tar.gz
WORKDIR ${TOOLS}/vcftools-0.1.14
RUN ./configure \
    && make -j4 \
    && make install

# sortmerna
WORKDIR ${TOOLS}
RUN wget http://bioinfo.lifl.fr/RNA/sortmerna/code/sortmerna-2.1-linux-64.tar.gz \
    && tar -zxf sortmerna-2.1-linux-64.tar.gz
ENV MERGE_PAIRED_READS="${TOOLS}/sortmerna-2.1-linux-64/scripts/merge-paired-reads.sh"
ENV UNMERGE_RNA_READS="${TOOLS}/sortmerna-2.1-linux-64/scripts/unmerge-paired-reads.sh"
ENV SORTMERNA="${TOOLS}/sortmerna-2.1-linux-64/sortmerna"
ENV SORTMERNA_DIR="${TOOLS}/sortmerna-2.1-linux-64"

# index the databases for SortMeRNA
WORKDIR ${TOOLS}
RUN ${TOOLS}/sortmerna-2.1-linux-64/indexdb_rna --ref ${TOOLS}/sortmerna-2.1-linux-64/rRNA_databases/silva-bac-16s-id90.fasta,${TOOLS}/sortmerna-2.1-linux-64/index/silva-bac-16s-db:\
${TOOLS}/sortmerna-2.1-linux-64/rRNA_databases/silva-bac-23s-id98.fasta,${TOOLS}/sortmerna-2.1-linux-64/index/silva-bac-23s-db:\
${TOOLS}/sortmerna-2.1-linux-64/rRNA_databases/silva-arc-16s-id95.fasta,${TOOLS}/sortmerna-2.1-linux-64/index/silva-arc-16s-db:\
${TOOLS}/sortmerna-2.1-linux-64/rRNA_databases/silva-arc-23s-id98.fasta,${TOOLS}/sortmerna-2.1-linux-64/index/silva-arc-23s-db:\
${TOOLS}/sortmerna-2.1-linux-64/rRNA_databases/silva-euk-18s-id95.fasta,${TOOLS}/sortmerna-2.1-linux-64/index/silva-euk-18s-db:\
${TOOLS}/sortmerna-2.1-linux-64/rRNA_databases/silva-euk-28s-id98.fasta,${TOOLS}/sortmerna-2.1-linux-64/index/silva-euk-28s:\
${TOOLS}/sortmerna-2.1-linux-64/rRNA_databases/rfam-5s-database-id98.fasta,${TOOLS}/sortmerna-2.1-linux-64/index/rfam-5s-db:\
${TOOLS}/sortmerna-2.1-linux-64/rRNA_databases/rfam-5.8s-database-id98.fasta,${TOOLS}/sortmerna-2.1-linux-64/index/rfam-5.8s-db

# SPAdes
WORKDIR ${TOOLS}
RUN wget http://cab.spbu.ru/files/release3.10.1/SPAdes-3.10.1-Linux.tar.gz \
    && tar -zxf SPAdes-3.10.1-Linux.tar.gz \
    && ln -s ${TOOLS}/SPAdes-3.10.1-Linux/bin/spades.py /usr/bin/spades.py

# vcflib for additional VCF utilities
WORKDIR ${TOOLS}
RUN git clone --recursive https://github.com/vcflib/vcflib.git
WORKDIR ${TOOLS}/vcflib
RUN make -j4 \
    && cp bin/* /usr/bin

# bbtools -- includes bbmap as an alternative aligner for large deletions and bbnorm for kmer normalization
WORKDIR ${TOOLS}
RUN wget https://downloads.sourceforge.net/project/bbmap/BBMap_37.33.tar.gz \
    && tar -zxf BBMap_37.33.tar.gz
ENV BBMAP="${TOOLS}/bbmap/bbmap.sh"
ENV BBNORM="${TOOLS}/bbmap/bbnorm.sh"

# MindTheGap -- for large indel detection
# This is just a dumb incrementer to force MTG to update sometimes
ARG MTG_UPDATE="May 26 2019"
WORKDIR ${TOOLS}
RUN git clone --recursive https://github.com/GATB/MindTheGap.git \
    && cd MindTheGap && bash ./INSTALL \
    && ln -s ./build/bin/MindTheGap /usr/bin/MindTheGap && cd ..
ENV MINDTHEGAP="${TOOLS}/MindTheGap/build/bin/MindTheGap"

# Picard tools
WORKDIR ${TOOLS}/picardtools
RUN wget https://github.com/broadinstitute/picard/releases/download/2.17.10/picard.jar
ENV PICARD_JAR="${TOOLS}/picardtools/picard.jar"

# BedTools -- general genomic arithmatic
WORKDIR ${TOOLS}
RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.25.0/bedtools-2.25.0.tar.gz \
    && tar -zxvf bedtools-2.25.0.tar.gz
RUN cd bedtools2 && make && make install

# bedGraphToBigWig -- part of kenttools. the big* stuff is free of the reagents of UCSC licenses
RUN wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig \
    && chmod +x bedGraphToBigWig \
    && mv bedGraphToBigWig /usr/bin/

# centrifuge -- taxonomy report for detecting contamination
WORKDIR ${TOOLS}
RUN wget https://github.com/infphilo/centrifuge/archive/v1.0.4-beta.tar.gz -O centrifuge-1.0.4-beta.tar.gz \
    && tar -zxvf centrifuge-1.0.4-beta.tar.gz \
    && cd centrifuge-1.0.4-beta \
    && make -j4 \
    && make install

# dustmasker -- masks low-complexity regions (used for building centrifuge index)
WORKDIR ${TOOLS}
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.9.0/ncbi-blast-2.9.0+-x64-linux.tar.gz \
    && tar -zxvf ncbi-blast-2.9.0+-x64-linux.tar.gz \
    && ln -s ${TOOLS}/ncbi-blast-2.9.0+/bin/dustmasker /usr/bin/dustmasker
