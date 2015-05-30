#!/bin/bash
# This shell script uses pandoc, with a custom writer and a custom template,
# followed by a regular expression replace with sed, and a bit of XSLT, to 
# produce TEI from markdown. Never have so many technologies been used to 
# accomplish a task so seemingly simple.

pandoc -S -s -t ./tei.lua --template=./tei-lite.template "$1" | sed 's:<l><p>:<l>:g' | sed 's:</p></l>:</l>:g' | xsltproc postprocess.xsl - 
