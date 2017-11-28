#!/usr/bin/env bash
#title: build_etongdai_anrd.sh
#author: Liu Shuo <liushuo@glorystone.net>
#date: 23 Nov, 2017

if [ -d "$WORKSPACE" ]; then
    WORK_DIR="$WORKSPACE"
else
    WORK_DIR="$PWD"
fi

INFO(){ echo -e "\x1B[35m$1\x1B[0m"; }
WARNING(){ echo -e "\x1B[33m$1\x1B[0m"; }
RESET(){
    INFO "reset git repo"
    cd $WORK_DIR
    git reset --hard &> /dev/null
}
ERROR(){
    echo -e "\x1B[31m$1\x1B[0m"
    RESET
}
TIMECONSUMED(){
    timeNow=`date '+%s'`
    echo `expr $timeNow - $timeBegin`
}

# setconfig() {


# }


PROJDIR="${WORK_DIR}/android/app"

BUILD_DIR="${PROJDIR}/build/outputs/apk/$(echo $buildType | tr 'A-Z' 'a-z')"

INFO ">>>>>>$BUILD_DIR"

libDir="${PROJDIR}/src/main/jniLibs"

jFile="./channels.json"

timeStamp=$(date '+%y%m%d-%H-%M')

channelCount=0

[[ ! -d apks ]] && `mkdir -p apks`

INFO ">>>>>>$libDir"

package() {
	# $1-appPkg $2-appName $3-appVersion $4-appVersionCode	$5-channelName $6-channelId	$7-environment	$8-buildType $9-author
	appPkg=$1
	appName=$2
	appVersion=$3
	appVersionCode=$4
	channelName=$5
	channelId=$6
	environment=$7
	buildType=$8
	author=$9
	isChannels=${10}
	#clean proj

	INFO "打包参数列表: appPkg:$appPkg, appName:$appName, appVersion:$appVersion, appVersionCode:$appVersionCode, channelName:$channelName, channelId:$channelId, environment:$environment, buildType:$buildType, author:$author, isChannels:$isChannels"
	gradle clean -b "${WORK_DIR}/android/app/build.gradle"

	if [[ "$isChannels" == "true" ]];then
		INFO "package all channels"
		INFO "count total package time"
		channelCount=`jq '. | length' $jFile`
		packBegin=`date '+%s'`
		for (( i = 0; i < `jq '. | length' $jFile`; i++ )); do
		 	 channelName=`jq -r ".[$i] | .name" $jFile`
		 	 channelId=`jq -r ".[$i] | .value" $jFile`
		 	 INFO ">>>>>>$current channel is: $channelName"
		 	 INFO ">>>>>>$current channel is: $channelId"
		 	 if [[ "$channelName" == "乐视" ]] || [[ "$channelName" == "应用宝应用市场" ]]; then
		 	 	INFO "replace leshi or yyb lib"
		 	 	INFO "remove useless dir and libdu.so"
		 	 	[[ -f ${libDir}/armeabi/libdu.so ]] && `rm -f "${libDir}/armeabi/libdu.so"`
		 	 	[[ -d ${libDir}/armeabi-v7a ]] && `rm -rf ${libDir}/armeabi-v7a`
		 	 	[[ -d ${libDir}/x86 ]] && `rm -rf ${libDir}/x86`
		 	 	if [[ -f ${libDir}/armeabi/libac.so ]]; then
		 	 		INFO "libac.so already existed"
		 	 		[[ -f ${libDir}/armeabi/libac.so ]] && `chmod 776 ${libDir}/armeabi/libac.so`
		 	 		if [[ $? -ne 0 ]]; then
		 	 			ERROR "chmod file fail"
		 	 			exit 1
		 	 		else
		 	 			INFO "打包开始："	
		 	 			timeBegin=`date '+%s'`
		 	 			gradle -PAPPLICATION_ID="$appPkg" -PAPP_NAME="$appName" -PAPP_VERSION_NAME="$appVersion" -PAPP_VERSION_CODE="$appVersionCode" -PBUILD_SCRIPT="${PROJDIR}/build.gradle" \
						-PUMENG_VALUE="$channelName" -PFRINED_ID="$channelId" -PENVIRONMENT="$environment" -PLABLE="$author" "assemble${buildType}" -b "${PROJDIR}/build.gradle" --stacktrace
						if [ $? -ne 0 ]; then
        					ERROR "编译失败！"
        					exit 1
    					else
        					INFO "编译成功！耗时$(TIMECONSUMED)秒,位于：${BUILD_DIR}"
    					fi
    				fi
    				INFO "move apk"
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/eTongDai_${channelName}_${environment}_${buildType}_${timeStamp}.apk \;
		 	 	else
		 	 		INFO "libac.so is not existed"
		 	 		INFO "cp libac.so"
		 	 		cp -f ac/armeabi/libac.so ${libDir}/armeabi
		 	 		[[ -f ${libDir}/armeabi/libac.so ]] && `chmod 776 ${libDir}/armeabi/libac.so`
		 	 		if [[ $? -ne 0 ]]; then
		 	 			ERROR "chmod file fail"
		 	 			exit 1
		 	 		else	
		 	 			INFO "打包开始："	
		 	 			timeBegin=`date '+%s'`
						gradle -PAPPLICATION_ID="$appPkg" -PAPP_NAME="$appName" -PAPP_VERSION_NAME="$appVersion" -PAPP_VERSION_CODE="$appVersionCode" -PBUILD_SCRIPT="${PROJDIR}/build.gradle" \
						-PUMENG_VALUE="$channelName" -PFRINED_ID="$channelId" -PENVIRONMENT="$environment" -PLABLE="$author" "assemble${buildType}" -b "${PROJDIR}/build.gradle" --stacktrace
						if [ $? -ne 0 ]; then
        					ERROR "编译失败！"
        					exit 1
    					else
        					INFO "编译成功！耗时$(TIMECONSUMED)秒,位于：${BUILD_DIR}"
    					fi
    				fi
					INFO "move apk"
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/eTongDai_${channelName}_${environment}_${buildType}_${timeStamp}.apk \;
		 	 	fi
		 		
		 	 else 
		 	 	INFO "replace other channel lib"
		 	 	INFO "remove libac.so"
		 	 	[[ -f ${libDir}/armeabi/libac.so ]] && `rm -f "${libDir}/armeabi/libac.so"`
		 	 	if [[ -f ${libDir}/armeabi/libdu.so ]]; then
		 	 		INFO "libdu.so already existed"
		 	 		for p in "armeabi" "armeabi-v7a" "x86" ; do
		 	 			chmod 776 ${libDir}/${p}/libdu.so
		 	 		done
		 	 		if [[ $? -ne 0 ]]; then
		 	 			ERROR "chmod file fail"
		 	 			exit 1
		 	 		else
		 	 			INFO "打包开始："	
		 	 			timeBegin=`date '+%s'`
						gradle -PAPPLICATION_ID="$appPkg" -PAPP_NAME="$appName" -PAPP_VERSION_NAME="$appVersion" -PAPP_VERSION_CODE="$appVersionCode" -PBUILD_SCRIPT="${PROJDIR}/build.gradle" \
						-PUMENG_VALUE="$channelName" -PFRINED_ID="$channelId" -PENVIRONMENT="$environment" -PLABLE="$author" "assemble${buildType}" -b "${PROJDIR}/build.gradle" --stacktrace
						if [ $? -ne 0 ]; then
        					ERROR "编译失败！"
        					exit 1
    					else
        					INFO "编译成功！耗时$(TIMECONSUMED)秒,位于：${BUILD_DIR}"
    					fi
    				INFO "move apk"
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/eTongDai_${channelName}_${environment}_${buildType}_${timeStamp}.apk \;	
    				fi
		 	 	else
		 	 		INFO "libdu.so is not existed"
		 	 		for p in "armeabi" "armeabi-v7a" "x86" ; do
		 	 			INFO ">>>>>>cp $p"
		 	 			cp -rf shumeng/${p} ${libDir}
		 	 			[[ -f ${libDir}/${p}/libdu.so ]] && `chmod 776 ${libDir}/${p}/libdu.so`
		 	 		done
		 	 		if [[ $? -ne 0 ]]; then
		 	 			ERROR "chmod file fail"
		 	 			exit 1
		 	 		else
		 	 			INFO "打包开始："	
		 	 			timeBegin=`date '+%s'`
						gradle -PAPPLICATION_ID="$appPkg" -PAPP_NAME="$appName" -PAPP_VERSION_NAME="$appVersion" -PAPP_VERSION_CODE="$appVersionCode" -PBUILD_SCRIPT="${PROJDIR}/build.gradle" \
						-PUMENG_VALUE="$channelName" -PFRINED_ID="$channelId" -PENVIRONMENT="$environment" -PLABLE="$author" "assemble${buildType}" -b "${PROJDIR}/build.gradle" --stacktrace
						if [ $? -ne 0 ]; then
        					ERROR "编译失败！"
        					exit 1
    					else
        					INFO "编译成功！耗时$(TIMECONSUMED)秒,位于：${BUILD_DIR}"
    					fi
		 	 		fi
		 	 		INFO "move apk"
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/eTongDai_${channelName}_${environment}_${buildType}_${timeStamp}.apk \;
		 	 	fi
		 	 fi
		 done
		 packEnd=`date '+%s'`
		 INFO "渠道打包成功！总数量: ${channelCount} 总耗时: `echo $((packEnd - packBegin))`秒"
	elif [[ "$isChannels" == "false" ]]; then
		INFO "isChannels false to this way"
		if [[ "$channelName" == "test" ]]; then
			INFO ">>>>>>$environment"
			[[ "$environment" == "develop" ]] && appPkg="com.stateunion.p2p.etongdai.vest"
			INFO ">>>>>>$appPkg"
			INFO "打包开始："	
		 	timeBegin=`date '+%s'`
			gradle -PAPPLICATION_ID="$appPkg" -PAPP_NAME="$appName" -PAPP_VERSION_NAME="$appVersion" -PAPP_VERSION_CODE="$appVersionCode" -PBUILD_SCRIPT="${PROJDIR}/build.gradle" \
			-PUMENG_VALUE="$channelName" -PENVIRONMENT="$environment" -PLABLE="$author" "assemble${buildType}" -b "${PROJDIR}/build.gradle" --stacktrace
			if [ $? -ne 0 ]; then
        		ERROR "编译失败！"
        		exit 1
    		else
        		INFO "编译成功！耗时$(TIMECONSUMED)秒,位于：${BUILD_DIR}"
    		fi
    		INFO "move apk"
			find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/eTongDai_${channelName}_${environment}_${buildType}_${timeStamp}.apk \;
    	else
    		INFO ">>>>>>$appPkg"
			INFO "打包开始："	
		 	timeBegin=`date '+%s'`
			gradle -PAPPLICATION_ID="$appPkg" -PAPP_NAME="$appName" -PAPP_VERSION_NAME="$appVersion" -PAPP_VERSION_CODE="$appVersionCode" -PBUILD_SCRIPT="${PROJDIR}/build.gradle" \
			-PUMENG_VALUE="$channelName" -PENVIRONMENT="$environment" -PLABLE="$author" "assemble${buildType}" -b "${PROJDIR}/build.gradle" --stacktrace
			if [ $? -ne 0 ]; then
        		ERROR "编译失败！"
        		exit 1
    		else
        		INFO "编译成功！耗时$(TIMECONSUMED)秒,位于：${BUILD_DIR}"
    		fi
    		INFO "move apk"
			find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/eTongDai_${channelName}_${environment}_${buildType}_${timeStamp}.apk \;

		fi

	fi	

	# gradle -PAPPLICATION_ID="$appPkg" -PAPP_NAME="$appName" -PAPP_VERSION_NAME="$appVersion" -PAPP_VERSION_CODE="$appVersionCode" \
	# -PUMENG_VALUE="$channelName" -PFRINED_ID="$channelId" -PENVIRONMENT="$environment" -PLABLE="$author" clean "assemble${buildType}" -b "${WORK_DIR}/android/app/build.gradle" --stacktrace

}


package
# package "com.stateunion.p2p.etongdai" "易通贷理财" "3.0.5" "3006" "yingxiao1001" "MTA3MTQwMjA=" "production" "Release" "liushuo" "true" | tee anrd.log
# package "com.stateunion.p2p.etongdai" "易通贷理财" "3.0.5" "3006" "test" "" "test" "Debug" "liushuo" "false"
