#!/bin/bash
# Processes CentOS Errata and imports it into Spacewalk
# Modified from https://github.com/liedekef/spacewalk_scripts for use with spacewalk in k8s

# set fixed locale
export LC_ALL=C
export LANG=C

CHANNELS=(centos-7-base
centos-7-extras
centos-7-updates)

if [[ $NBR_DIGESTS -lt 1 ]]; then
   NBR_DIGESTS=1;
fi
if [[ $NBR_DIGESTS -gt 28 ]]; then
   NBR_DIGESTS=28;
fi

# create and/or cleanup the errata dir
ERRATADIR=/tmp/centos-errata
[[ -d $ERRATADIR ]] && rm -f $ERRATADIR/* || mkdir $ERRATADIR
(
   cd $ERRATADIR
   eval $(exec /bin/date -u +'yearmon=%Y-%B day=%d')
   # for the first day of the month: also consider last month
   # this only applies if the script is ran EVERY DAY
   if [ $day -lt $NBR_DIGESTS ]; then
      yearmon=$(date -u -d "$NBR_DIGESTS days ago" +%Y-%B)\ $yearmon
   fi
   # Use wget to fetch the errata data from centos.org
   listurl=https://lists.centos.org/pipermail/centos
   { for d in $yearmon; do
	  wget --no-cache -q -O- $listurl/$d/date.html \
		| sed -n 's|.*"\([^"]*\)".*CentOS-announce Digest.*|'"$d/\\1|p"
     done
   } |	tail -n $NBR_DIGESTS | xargs -n1 -I{} wget -q $listurl/{}
)

errataImport()
{
  echo "Errata Import In !!!"
  echo "Errata Dir: $ERRATADIR"
	for channel in "${CHANNELS[@]}"
	do
	  /spacewalk-scripts/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel $channel --os-version $CENTOS_VERSION --publish
		# OR do the import and get extra errata info from redhat if possible
		#/spacewalk-scripts/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel $channel --os-version $CENTOS_VERSION --publish --get-from-rhn
	done
}

errataImport
