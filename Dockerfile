FROM library/postgres:9.4.9

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
MAINTAINER Lorenz Gerber <lorenzottogerber@gmail.com>
RUN apt-get clean -y; \
    apt-get update -y -qq

ENV LANG "C.UTF-8"
ENV LC_ALL "C.UTF-8"

WORKDIR /
RUN mkdir -p /docker-entrypoint-initdb.d
COPY initdb.sh    /docker-entrypoint-initdb.d/000-initdb.sh
COPY load_data.sh /docker-entrypoint-initdb.d/001-load_data.sh

WORKDIR /tmp
COPY elixir_beacon_db_schema.sql /tmp/
COPY elixir_beacon_function_summary_response.sql /tmp/
COPY 1_chrY_subset.samples.csv /tmp/
COPY 1_chr21_subset.samples.csv /tmp/
COPY sg10k_chr1.after_QC.phased.AF_updated.samples.csv /tmp/
COPY 1_chrY_subset.variants.csv /tmp/
COPY 1_chr21_subset.variants.csv /tmp/
COPY sg10k_chr1.after_QC.phased.AF_updated.variants.csv /tmp/
COPY 1_chrY_subset.variants.matching.samples.csv /tmp/
COPY 1_chr21_subset.variants.matching.samples.csv /tmp/
COPY sg10k_chr1.after_QC.phased.AF_updated.variants.matching.samples.csv /tmp/


