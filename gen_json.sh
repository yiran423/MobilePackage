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
	"platform":"$platFrom",
	"version":"$version",
	"buildNum":"$BUILD_NUMBER",
	"jobName":"$JOB_NAME",
	"indexUrl"="https://nexus.zgc.etongdai.org/nexus/repository/etd-apps/iOS/${short_version}/${BUILD_NUMBER}/index.html",
	"resources": [ "${productName1}", "${productName2}", "${productName3}" ]
}
EOF