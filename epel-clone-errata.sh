#!/bin/bash
# Processes EPEL Errata and imports it into Spacewalk

# IMPORTANT: read through this script, it's more of a guidance than something fixed in stone
# also: if you're using the commandline options for usernames and passwords, comment out the
# line that says ". ./ya-errata-import.cfg"

# set fixed locale
export LC_ALL=C
export LANG=C

CHANNELS=(centos-7-epel)
EPEL_VERSION=7

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

errataImport()
{
  echo "Errata Import In !!!"
  echo "Errata Dir: $ERRATADIR"
	for channel in "${CHANNELS[@]}"
	do
	  /spacewalk-scripts/ya-errata-import.pl --epel_errata $ERRATADIR/updateinfo.xml --server $SPACEWALK --channel $channel --os-version $CENTOS_VERSION --publish --startfromprevious twoweeks --quiet
		# OR do the import and get extra errata info from redhat if possible
		#/spacewalk-scripts/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel $channel --os-version $CENTOS_VERSION --publish --get-from-rhn
	done
}

errataImport

rm -f $ERRATADIR/*
