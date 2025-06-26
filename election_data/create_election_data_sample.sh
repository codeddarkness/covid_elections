#!/usr/bin/env bash

sample_limit=${1:-25}
report=sample_election_data.csv.ref

for x in *.csv ; do
    echo "## SAMPLE DATA from $x (${sample_limit} random lines sorted) ##";
    head -n1 "$x" ;
    grep -v 'year\|state\|state_po\|county_name\|county_fips\|office,candidate\|party\|candidatevotes\|totalvotes\|version\|mode' ${x} | shuf -n${sample_limit}| sort; 
    echo -e "## RECORDS IN FILE [ 'wc -l $x' ]: $(wc -l "$x")"
    echo -e "## END ${x}\n"
done | tee ${report}

echo "## osprey(dev) folder structure $(realpath .)" | tee -a ${report}
ls -laht ./ | tee -a ${report}

echo -e "\n## bataleon(web server) folder structure $(ssh bataleon "realpath /var/www/html/covid_elections/")" | tee -a ${report}
ssh bataleon "ls -laht /var/www/html/covid_elections/" | tee -a ${report}
