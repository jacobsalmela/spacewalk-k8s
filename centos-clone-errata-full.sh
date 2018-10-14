#!/bin/bash
# Processes CentOS Errata and imports it into Spacewalk
# Modified from https://github.com/liedekef/spacewalk_scripts for use with spacewalk in k8s

# set fixed locale
export LC_ALL=C
export LANG=C

CHANNELS=(centos-7-base
centos-7-extras
centos-7-updates)

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

fullChargeErrata()
{
  # Retrieve all years from emails sent to list, since 2004. This function will sign all erratas from digest
  # available in the mail list.
  yearmon=$(curl https://lists.centos.org/pipermail/centos/index.html|grep date.html|cut -d"\"" -f2|cut -d"/" -f1)

  # create and/or cleanup the errata dir
  ERRATADIR=/tmp/centos-errata
  [[ -d $ERRATADIR ]] && rm -f $ERRATADIR/* || mkdir $ERRATADIR
  (
    cd $ERRATADIR
    # Use wget to fetch the errata data from centos.org
    listurl=https://lists.centos.org/pipermail/centos
    { for d in $yearmon; do
		echo "Getting full listing of centos erratta digests..."
	  wget --no-cache -q -O- $listurl/$d/date.html \
		| sed -n 's|.*"\([^"]*\)".*CentOS-announce Digest.*|'"$d/\\1|p"
      done
    } |	xargs -n1 -I{} wget -q $listurl/{}
  )
  errataImport
}

fullChargeErrata
