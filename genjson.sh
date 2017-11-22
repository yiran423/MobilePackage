#!/usr/bin/env bash
#title: genjson.sh
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
# url="https://nexus.zgc.etongdai.org/nexus/repository/etd-apps/${short_version}/${BUILD_NUMBER}/index.html"
url="https://nexus.zgc.etongdai.org/nexus/repository/etd-apps"
cat << EOF > download.json
{
	"platForm":"$platFrom",
	"version":"$version",
	"buildNo":"$BUILD_NUMBER",
	"jobName":"$JOB_NAME",
	"url":"$url",
	"resourse": [
			{ "ipa":"$productName", "html":"index.html", "plist":"manifest.plist" } 
	]
}
EOF