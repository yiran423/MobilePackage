#!/usr/bin/env bash
#title: genjson.sh
#author: Liu Shuo <liushuo@glorystone.net>
#date: 21 Nov, 2017

if [[ $JOB_NAME =~ ^iOS ]];then
	platform="iOS"
else
	platform="android"
fi
version=$short_version
buildNum=$BUILD_NUMBER
jobName=$JOB_NAME
productName=${productName}
cat << EOF > ${WORK_DIR}/download.json
{
	"platform":"$platform",
	"version":"$version",
	"buildNum":"$BUILD_NUMBER",
	"jobName":"$JOB_NAME",
	"buildUrl":"${BUILD_URL}",
	"indexUrl":"https://nexus.zgc.etongdai.org/nexus/repository/etd-apps/iOS/${short_version}/${BUILD_NUMBER}/index.html",
	"resources": [ "${productName}.ipa" ]
}
EOF