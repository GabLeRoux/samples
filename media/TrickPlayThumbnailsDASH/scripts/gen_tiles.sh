#!/bin/bash
#
# Copyright (c) 2019-2020 Roku, Inc. All rights reserved.
#
# References:
# https://stackoverflow.com/questions/2853334/glueing-tile-images-together-using-imagemagicks-montage-command-without-resizin
# http://www.imagemagick.org/script/command-line-options.php#append
# https://github.com/image-media-playlist/spec/blob/master/image_media_playlist_v0_4.pdf
# https://www.tecmint.com/install-imagemagick-in-linux/
# https://stackoverflow.com/questions/39504522/create-blank-image-in-imagemagick
# https://stackoverflow.com/questions/5688576/how-to-use-mod-operator-in-bash

if [ $# -lt 6 ]; then
	echo "Usage: $0 <thumbnails-dir> <input-prefix> <output-prefix> <resolution> <cols> <rows>"
	exit 1
fi

INDIR=$1
INPREFIX=$2
OUTPREFIX=$3
RESOLUTION=$4
COLS=$5
ROWS=$6

# All parameters need to be specified
# The $INDIR parameter is a directory containing the thumbnails
# The $INPREFIX parameter is a name without count string, .e.g. in
# The $OUTPREFIX parameter is a name without count string, .e.g. thumb-tile
# The $COLS parameter is tile vertical count, e.g. 5
# The $ROWS parameter is tile horizontal count, e.g. 4
#
# One example of running this command:
# $ ./scripts/gen_tiles.sh /tmp/test-320x180 in 5 4

# The script sorts thumbnails into files and generates the tile using imagemagick montage
# Usually, this script uses input thumbnails generated by gen_thumbs.sh
#

cd $INDIR
let "THUMBCOUNT=`ls -l |wc -l` - 1"
echo "THUMBCOUNT = $THUMBCOUNT"
TILE=1
STARTTILE=1
cd ..

# Special handling for 1x1 tiles, just copy the files to ${OUTPREFIX}-${COLS}x${ROWS}-${TILE}.jpg
if [ ${ROWS} -eq 1 ] && [ ${COLS} -eq 1 ]; then
	while [ $TILE -le $THUMBCOUNT ]
	do
    	mv $INDIR/$INPREFIX-`printf %03d ${TILE}`.jpg ${OUTPREFIX}-${COLS}x${ROWS}-${TILE}.jpg
    	let "TILE= $TILE + 1"
	done
	exit 0
fi

# calculate thumbs need to fill N tiles, result is TILETHUMBS
# and LASTTILE is the tile that may need to be padded
let "TILESIZE=$COLS * $ROWS"
let "TILETHUMBS=$TILESIZE"
let "LASTTILE=1"
while [ $TILETHUMBS -lt $THUMBCOUNT ]
do
	let "TILETHUMBS=$TILETHUMBS + $TILESIZE"
	let "LASTTILE=$LASTTILE + 1"
done

# generation of padding for the last tile, if padding is needed
if [ $TILETHUMBS -gt $THUMBCOUNT ]; then
	let "ALIGNCOUNT=$TILETHUMBS - $THUMBCOUNT"
	echo "ALIGNCOUNT = $ALIGNCOUNT"
	COUNT=1
	mkdir tile${LASTTILE}
	while [ $COUNT -le $ALIGNCOUNT ]
	do
		let "TILENUM=$THUMBCOUNT + $COUNT"
		let "COUNT=$COUNT + 1"
		convert -size ${RESOLUTION} xc:black tile${LASTTILE}/$INPREFIX-${TILENUM}.jpg
	done

	# finally, reset THUMBCOUNT to include padded tiles
	#let "THUMBCOUNT=$THUMBCOUNT + $ALIGNCOUNT"
	#echo "THUMBCOUNT = $THUMBCOUNT"
fi

# normal handling of tile generation
while [ $STARTTILE -lt $THUMBCOUNT ]
do
	let "ENDTILE= $STARTTILE + $TILESIZE - 1"
	if [ $ENDTILE -gt $THUMBCOUNT ] ; then
		ENDTILE=$THUMBCOUNT
	fi
	echo "create dir tile${TILE}"
	if [ ! -d tile${TILE} ]; then
		mkdir tile${TILE}
	fi

	echo "move $INPREFIX-${STARTTILE}.jpg to $INPREFIX-${ENDTILE}.jpg"
	for ((i=$STARTTILE; i<=$ENDTILE; i++))
	do
		cp $INDIR/$INPREFIX-`printf %03d ${i}`.jpg tile${TILE}
	done

	echo "montage -mode concatenate -tile ${COLS}x${ROWS} tile${TILE}/${INPREFIX}-*.jpg ${OUTPREFIX}_${TILE}.jpg"
	montage -mode concatenate -tile ${COLS}x${ROWS} tile${TILE}/${INPREFIX}-*.jpg ${OUTPREFIX}_${TILE}.jpg

	let "STARTTILE= $TILE * $TILESIZE + 1"
	let "TILE= $TILE + 1"
done