#!/usr/bin/env bash
#title: build_etongdai.sh
#author: Liu Shuo <liushuo@glorystone.net>
#date: 21 Nov, 2017

if [[ $JOB_NAME =~ ^iOS ]];then
	platFrom="ios"
else
	platFrom="android"
fi
version=$short_version
bildNo=$BUILD_NUMBER
jobName=$JOB_NAME
url="https://nexus.zgc.etongdai.org/nexus/repository/etd-apps/${short_version}/${BUILD_NUMBER}/index.html"
cat << EOF > download.json
{ "platForm":$platFrom,"version":$version,"bildNo":$BUILD_NUMBER,"jobName":$JOB_NAME,"url":$url}
EOF