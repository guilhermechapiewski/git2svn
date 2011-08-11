#!/bin/bash
BASE_DIR=`pwd`
GIT_DIR="/Users/gc/Temp/git_repo"
SVN_DIR="/Users/gc/Temp/svn_repo"

# The SVN_AUTH variable can be used in case you need credentials to commit
#SVN_AUTH="--username guilherme.chapiewski@gmail.com --password XPTO"
SVN_AUTH=""

function svn_checkin {
	echo '... adding files'
	for file in `svn st ${SVN_DIR} | awk -F" " '{print $1 "|" $2}'`; do
		fstatus=`echo $file | cut -d"|" -f1`
		fname=`echo $file | cut -d"|" -f2`

		if [ "$fstatus" == "?" ]; then
			if [[ "$fname" == *@* ]]; then
				svn add $fname@;
			else
				svn add $fname;
			fi
		fi
		if [ "$fstatus" == "!" ]; then
			if [[ "$fname" == *@* ]]; then
				svn rm $fname@;
			else
				svn rm $fname;
			fi
		fi
		if [ "$fstatus" == "~" ]; then
			rm -rf $fname;
			svn up $fname;
		fi
	done
	echo '... finished adding files'
}

function svn_commit {
	echo "... committing -> [$author]: $msg";
	cd $SVN_DIR && svn $SVN_AUTH commit -m "[$author]: $msg" && cd $BASE_DIR;
	echo '... committed!'
}

for commit in `cd $GIT_DIR && git rev-list --all --reverse && cd $BASE_DIR`; do 
	echo "Committing $commit...";
	author=`cd ${GIT_DIR} && git log -n 1 --pretty=format:%an ${commit} && cd ${BASE_DIR}`;
	msg=`cd ${GIT_DIR} && git log -n 1 --pretty=format:%s ${commit} && cd ${BASE_DIR}`;
	
	# Checkout the current commit on git
	echo '... checking out commit on Git'
	cd $GIT_DIR && git checkout $commit && cd $BASE_DIR;
	
	# Delete everything from SVN and copy new files from Git
	echo '... copying files'
	rm -rf $SVN_DIR/*;
	cp -prf $GIT_DIR/* $SVN_DIR/;
	
	# Remove Git specific files from SVN
	for ignorefile in `find ${SVN_DIR} | grep .git | grep .gitignore`;
	do
		rm -rf $ignorefile;
	done
	
	# Add new files to SVN and commit
	svn_checkin && svn_commit;
done

