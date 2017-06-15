#!/bin/bash 

BASIC=0
WORLD=0
SEQUITUR=1 
STANFORD=0

## Location of this script:-
SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

OSSIAN=$SCRIPTPATH/../


if [ $BASIC == 1 ] ; then


    [ $# -ne 2 ] && echo "Wrong number of arguments supplied" && exit 1 ;

    ## setup script based on http://homepages.inf.ed.ac.uk/owatts/ossian/html/setting_up.html
    HTK_USERNAME=$1
    HTK_PASSWORD=$2

    cd $OSSIAN/tools/
    git clone https://github.com/CSTR-Edinburgh/merlin.git
    cd merlin
    ## reset to this specific version, which I have tested:--
    git reset --hard 8aed278  


    #echo 'stop early'
    #exit 1

    ## Assuming that you want to compile everything cleanly from scratch:
    rm -r $OSSIAN/tools/downloads/*
    rm -r $OSSIAN/tools/bin/*

    ## Make sure these locations exist:
    mkdir -p $OSSIAN/tools/bin
    mkdir -p $OSSIAN/tools/downloads

    cd $OSSIAN/tools/downloads

    ## Download HTK source code:
    wget http://htk.eng.cam.ac.uk/ftp/software/HTK-3.4.1.tar.gz --http-user=$HTK_USERNAME --http-password=$HTK_PASSWORD
    wget http://htk.eng.cam.ac.uk/ftp/software/hdecode/HDecode-3.4.1.tar.gz  --http-user=$HTK_USERNAME --http-password=$HTK_PASSWORD

    ## Download HTS patch:
    wget http://hts.sp.nitech.ac.jp/archives/2.3alpha/HTS-2.3alpha_for_HTK-3.4.1.tar.bz2

    ## Unpack everything:
    tar -zxvf HTK-3.4.1.tar.gz
    tar -zxvf HDecode-3.4.1.tar.gz
    tar -xvf HTS-2.3alpha_for_HTK-3.4.1.tar.bz2

    ## Apply HTS patch:
    cd htk
    patch -p1 -d . < ../HTS-2.3alpha_for_HTK-3.4.1.patch

    ## Apply the Ossian patch:
    patch -p1 -d . < ../../patch/ossian_hts.patch



    ## Finally, configure and compile:
    ./configure --prefix=$OSSIAN/tools/ --without-x --disable-hslab
    make
    make install

    ## Get hts_engine:
    cd $OSSIAN/tools/downloads
    wget http://sourceforge.net/projects/hts-engine/files/hts_engine%20API/hts_engine_API-1.05/hts_engine_API-1.05.tar.gz
    tar xvf hts_engine_API-1.05.tar.gz
    cd hts_engine_API-1.05
    ## Patch engine for use with Ossian (glottHMM compatibility):
    patch -p1 -d . < ../../patch/ossian_engine.patch
    ./configure --prefix=$OSSIAN/tools/
    make
    make install

    ## Get SPTK:
    cd $OSSIAN/tools/downloads
    wget http://downloads.sourceforge.net/sp-tk/SPTK-3.6.tar.gz
    tar xvf SPTK-3.6.tar.gz
    cd SPTK-3.6
    ./configure --prefix=$OSSIAN/tools/

    ## To compile on Mac, modify Makefile for delta tool:
    mv ./bin/delta/Makefile ./bin/delta/Makefile.BAK
    sed 's/CC = gcc/CC = clang/' ./bin/delta/Makefile.BAK > ./bin/delta/Makefile     ## (see http://sourceforge.net/p/sp-tk/bugs/68/)

    make
    make install

    ## Count the binaries in your bin directory:
    ls $OSSIAN/tools/bin/* | wc -l
    ## If all the tools have been compiled OK, you should have 160 or 163 of them.

fi


if [ $WORLD == 1 ] ; then

    cd $OSSIAN/tools/world/World-master
    rm -rf build/*
    make -f makefile clean
    make -f makefile analysis
    make -f makefile synth
    cp build/analysis $OSSIAN/tools/bin/analysis
    cp build/synth $OSSIAN/tools/bin/synth
      
fi


if [ $SEQUITUR == 1 ] ; then

    rm -rf $OSSIAN/tools/g2p/ 

    # Sequitur G2P
    cd $OSSIAN/tools/
    wget https://www-i6.informatik.rwth-aachen.de/web/Software/g2p-r1668-r3.tar.gz
    tar xvf g2p-r1668-r3.tar.gz
    rm -r g2p-r1668-r3.tar.gz
    cd g2p

    ## Couldn't compile with clang on mac -- specify to use g++.
    ## Add this in setup.py under 'import os':

## Don't indent this to avoid screwing up the sed expression:
mv setup.py setup.py.BAK
sed 's/import os/import os\
\
os.environ["CC"] = "g++"\
os.environ["CXX"] = "g++"/' setup.py.BAK > setup.py

    mv UnorderedMap.hh UnorderedMap.hh.BAK
    sed '@#include <tr1/unordered_map>@#include <unordered_map>@' UnorderedMap.hh.BAK > UnorderedMap.hh; 


    ## Compile:
    python setup.py install --prefix  $OSSIAN/tools

fi

# if [ $SEQUITUR == 1 ] ; then

#     rm -rf $OSSIAN/tools/g2p/ $OSSIAN/tools/sequitur-g2p/

#     # Sequitur G2P
#     cd $OSSIAN/tools/
#     git clone https://github.com/sequitur-g2p/sequitur-g2p.git

#     cd sequitur-g2p

#     ## Compile:
#     CFLAGS="-std=c++0x" python setup.py install --prefix  $OSSIAN/tools 
# fi









if [ $STANFORD == 1 ] ; then

    ## clean up:
    rm -rf $OSSIAN/tools/corenlp-python/ $OSSIAN/tools/downloads/*

    # Stanford core NLP with Python bindings

    cd $OSSIAN//tools

    ## Get the Python bindings (we assume git is installed):
    git clone https://bitbucket.org/torotoki/corenlp-python.git

    ## Make a small alteration to the bindings:
    mv ./corenlp-python/corenlp/corenlp.py ./corenlp-python/corenlp/corenlp.py.BAK
    sed 's/?.?.?-models/?.?-models/' ./corenlp-python/corenlp/corenlp.py.BAK | \
    sed 's/?.?.?.jar/?.?.jar/' > ./corenlp-python/corenlp/corenlp.py

    ## Get CoreNLP:
    cd corenlp-python/
    wget http://nlp.stanford.edu/software/stanford-corenlp-full-2014-06-16.zip
    unzip stanford-corenlp-full-2014-06-16.zip
    rm stanford-corenlp-full-2014-06-16.zip

fi


