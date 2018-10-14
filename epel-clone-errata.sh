#!/bin/bash
# Processes EPEL Errata and imports it into Spacewalk

# IMPORTANT: read through this script, it's more of a guidance than something fixed in stone
# also: if you're using the commandline options for usernames and passwords, comment out the
# line that says ". ./ya-errata-import.cfg"

# set fixed locale
export LC_ALL=C
export LANG=C

CHANNELS=(centos-7-base
centos-7-extras
centos-7-updates)

# create and/or cleanup the errata dir
ERRATADIR=/tmp/epel-errata
mkdir $ERRATADIR >/dev/null 2>&1
rm -f $ERRATADIR/* >/dev/null 2>&1

(
   cd $ERRATADIR
   # now download the errata, in this example we do it for EPEL-6-x86_64
   # EPEL changed repomd format
   # wget -q --no-cache http://dl.fedoraproject.org/pub/epel/$EPEL_VERSION/x86_64/repodata/updateinfo.xml.gz
   repomd=`wget -q -O - --no-cache http://dl.fedoraproject.org/pub/epel/$EPEL_VERSION/$EPEL_ARCH/repodata/repomd.xml`
   # we use perl minimal matching
   updateinfo_location=`echo $repomd | perl -pe 's/.*href="(.*?updateinfo.xml.bz2).*/$1/;'`
   wget -q --no-cache -O updateinfo.xml.bz2 http://dl.fedoraproject.org/pub/epel/$EPEL_VERSION/$EPEL_ARCH/$updateinfo_location
   bunzip2 updateinfo.xml.bz2
)

# upload the errata to spacewalk, e.g. for a channel used by redhat servers:
/spacewalk-scripts/ya-errata-import.pl --epel_errata $ERRATADIR/updateinfo.xml --server $SPACEWALK --channel rhel-x86_64-server-6-epel --os-version 6 --publish --redhat --startfromprevious twoweeks --quiet
# upload the errata to spacewalk, e.g. for a channel used by centos servers:
/spacewalk-scripts/ya-errata-import.pl --epel_errata $ERRATADIR/updateinfo.xml --server $SPACEWALK --channel centos-x86_64-server-6-epel --os-version 6 --publish --startfromprevious twoweeks --quiet

rm -f $ERRATADIR/*
