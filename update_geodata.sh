#!/bin/sh

GEOIP_DAT_URL='https://raw.githubusercontent.com/Loyalsoldier/geoip/release/geoip.dat'
GEOSITE_DAT_URL='https://raw.githubusercontent.com/Loyalsoldier/domain-list-custom/release/geosite.dat'

GEODATA_PATH='/usr/local/share/geodat'

GEOIP_TXT_BASE='https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text'
GEOSITE_TXT_BASE='https://raw.githubusercontent.com/Loyalsoldier/domain-list-custom/release'


TEMPDIR=$(mktemp -d)
TEMPDAT_DIR=$TEMPDIR/tmpdata

mkdir -p $TEMPDAT_DIR

echo "Updating geoip.dat"
curl --limit-rate 10000k --progress-bar --create-dirs -O --output-dir $TEMPDAT_DIR -L $GEOIP_DAT_URL
echo "Updating geosite.dat"
curl --limit-rate 10000k --progress-bar --create-dirs -O --output-dir $TEMPDAT_DIR -L $GEOSITE_DAT_URL

echo "Updating uncompressed geoip"

git -C $TEMPDIR clone -b release https://github.com/Loyalsoldier/geoip.git

mkdir -p $TEMPDAT_DIR/geoip/
mkdir -p $TEMPDAT_DIR/geosite/

for file in $(ls $TEMPDIR/geoip/text)
do
    cat $TEMPDIR/geoip/text/$file >> $TEMPDAT_DIR/geoip/$(echo $file | awk -F. '{print $1}')
done

echo "Updating uncompressed geosite"

git -C $TEMPDIR clone https://github.com/v2fly/domain-list-community.git

cp $TEMPDIR/domain-list-community/data/* $TEMPDAT_DIR/geosite/

for file in $(ls $TEMPDAT_DIR/geosite)
do
    sed -i -c -e '/^#/d;s/ @.*//g;s/ #.*//;s/\r$//' $TEMPDAT_DIR/geosite/$file
done

for file in $(ls $TEMPDAT_DIR/geosite/)
do
    echo "Processing geosite/$file"
    while [ $(cat $TEMPDAT_DIR/geosite/$file | grep include | awk -F ':' '{{print $2}}' | wc -l) -gt 0 ]
    do
        LIST=$(cat $TEMPDAT_DIR/geosite/$file | grep include | awk -F ':' '{{print $2}}')
        sed -i -c -e '/^include/d' $TEMPDAT_DIR/geosite/$file
        for next in $LIST
        do
            echo "" >> $TEMPDAT_DIR/geosite/$file
            cat $TEMPDAT_DIR/geosite/$next >> $TEMPDAT_DIR/geosite/$file
            echo "" >> $TEMPDAT_DIR/geosite/$file
        done
    done 
done

for file in $(ls $TEMPDAT_DIR/geosite)
do
    sed -i -c -e '/^$/d' $TEMPDAT_DIR/geosite/$file
done

rm -rf $GEODATA_PATH/*.dat
rm -rf $GEODATA_PATH/geoip/*
rm -rf $GEODATA_PATH/geosite/*

cp -r $TEMPDAT_DIR/* $GEODATA_PATH

rm -rf $TEMPDIR