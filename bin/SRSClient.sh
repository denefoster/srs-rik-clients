#!/bin/sh

DIR=`dirname $0`
PERL=`sh $DIR/perl_cmd $DIR`;

eval "$PERL $DIR/SRSClient $*";
