#!/bin/bash
repo_ids=(epel base extras updates)

REPO_DIRECTORY=/var/www/html/repo/

reposync_a_repo(){
	if [[ "$repo" == "extras" ]] || [[ "$repo" == "updates" ]]; then
		rsync -azHP --exclude='drpms/' --ignore-existing "$mirror" $REPO_DIRECTORY/"$repo"
	elif [[ "$repo" == "base" ]]; then
		rsync -azHP --ignore-existing\
			--exclude='CentOS_BuildTag' \
			--exclude='drpms/' \
			--exclude='EFI*' \
			--exclude='EULA' \
			--exclude='LiveOS/' \
			--exclude='images/' \
			--exclude='isolinux/' \
			--exclude='GPL' \
			--exclude='EFI*' \
			"$mirror" $REPO_DIRECTORY/"$repo"
	elif [[ "$repo" == "epel" ]]; then
			reposync -n --gpgcheck -l --repoid=$repo --download_path=$REPO_DIRECTORY --downloadcomps --download-metadata
	fi
}

createrepo_a_repo(){
	if [[ "$repo" == "epel" ]]; then
		:
	elif [[ "$repo" == "base" ]] || [[ "$repo" == "extras" ]] || [[ "$repo" == "updates" ]]; then
		createrepo --workers 4 -v $REPO_DIRECTORY/$repo
	fi
}

spacewalk_sync_a_repo(){
	if [[ "$repo" == "base" ]] || [[ "$repo" == "extras" ]] || [[ "$repo" == "updates" ]]; then
		spacewalk-repo-sync --latest --channel=$channel --type yum --url=http://localhost/repo/$repo/
	else
		:
	fi
}

clone_epel_errata(){
	# Assuming https://github.com/liedekef/spacewalk_scripts
  chmod 755 /spacewalk-scripts/epel-clone-errata.sh
  /spacewalk-scripts/epel-clone-errata.sh
}

clone_centos_errata(){
	# Assuming https://github.com/liedekef/spacewalk_scripts
  chmod 755 /spacewalk-scripts/centos-clone-errata-full.sh
  /spacewalk-scripts/centos-clone-errata-full.sh
}

for repo in "${repo_ids[@]}"
do
	case "$repo" in
		epel) channel="centos-7-epel";;
		base) channel="centos-7-base";mirror="rsync://mirrors.usinternet.com/centos/7/os/x86_64/";;
		extras) channel="centos-7-extras";mirror="rsync://mirrors.usinternet.com/centos/7/extras/x86_64/";;
		updates) channel="centos-7-updates";mirror="rsync://mirrors.usinternet.com/centos/7/updates/x86_64/";;
	esac
	reposync_a_repo $repo
	createrepo_a_repo $repo
	spacewalk_sync_a_repo $repo
done

# clone_epel_errata
# clone_centos_errata
