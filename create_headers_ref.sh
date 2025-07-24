#!/usr/bin/env bash
for datafile in $(grep 'csvFile =' covid_dashboard.html | grep -v let| cut -d= -f2| xargs | sed 's/;//g'); do
    echo "# $datafile sample"
    head -n1 ${datafile} ; 
    echo
done | tee data_samples_headers.ref
