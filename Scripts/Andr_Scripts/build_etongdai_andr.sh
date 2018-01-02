#!/usr/bin/env bash
#title: build_etongdai_andr.sh
#author: Liu Shuo <liushuo@glorystone.net>
#date: 23 Nov, 2017

if [ -d "$WORKSPACE" ]; then
    WORK_DIR="$WORKSPACE"
else
    WORK_DIR="$PWD"
fi

#variables set
headVer=${appVersionCode:0:1}
midVer1=${appVersionCode:1:1}
midVer2=${appVersionCode:2:1}
tailVer=${appVersionCode:3:1}
tailVerM=$(( --tailVer ))
version="${headVer}.${midVer1}.${midVer2}.${tailVerM}"

PROJDIR="${WORK_DIR}/android/app"
BUILD_DIR="${PROJDIR}/build/outputs/apk/$(echo $buildType | tr 'A-Z' 'a-z')"
libDir="${PROJDIR}/src/main/jniLibs"
scriptsDir="${WORK_DIR}/Scripts/Andr_Scripts"
jFile="${WORK_DIR}/Scripts/Andr_Scripts/channels.json"
timeStamp=$(date '+%y%m%d-%H-%M')
channelCount=0

[[ ! -d apks ]] && `mkdir -p apks`

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

setversion() {
	INFO "set version"
	sed -i '' "s#appAndroidVersion.*#appAndroidVersion: '$version', //android app#" "$WORK_DIR/app/commons/config.js"
	sed -i '' "s#appVersion.*#appVersion: '$appVersion', //app#" "$WORK_DIR/app/commons/config.js"
}

setconfig() {
	INFO "set environment"
	case "$environment" in
		"stage1" )
                # sed -i '' 's/const mode.*/const mode = "stage1";/' "$WORK_DIR/app/commons/config.js"
                sed -i '' "s/var mode = __DEV__ ? NativeModules.ETDGrowingIO.mode.*/var mode = __DEV__ ? NativeModules.ETDGrowingIO.mode : 'stage1';/" "$WORK_DIR/app/commons/config.js"
            ;;
        "stage2" )
                # sed -i '' 's/const mode.*/const mode = "stage2";/' "$WORK_DIR/app/commons/config.js"
                sed -i '' "s/var mode = __DEV__ ? NativeModules.ETDGrowingIO.mode.*/var mode = __DEV__ ? NativeModules.ETDGrowingIO.mode : 'stage2';/" "$WORK_DIR/app/commons/config.js"
            ;;
         "stage3" )
                # sed -i '' 's/const mode.*/const mode = "stage3";/' "$WORK_DIR/app/commons/config.js"
                sed -i '' "s/var mode = __DEV__ ? NativeModules.ETDGrowingIO.mode.*/var mode = __DEV__ ? NativeModules.ETDGrowingIO.mode : 'stage3';/" "$WORK_DIR/app/commons/config.js"
            ;;    
        "preproduction" )
                # sed -i '' 's/const mode.*/const mode = "preproduction";/' "$WORK_DIR/app/commons/config.js"
                sed -i '' "s/var mode = __DEV__ ? NativeModules.ETDGrowingIO.mode.*/var mode = __DEV__ ? NativeModules.ETDGrowingIO.mode : 'preproduction';/" "$WORK_DIR/app/commons/config.js"
            ;;
        "production" )
                # sed -i '' 's/const mode.*/const mode = "production";/' "$WORK_DIR/app/commons/config.js"
                sed -i '' "s/var mode = __DEV__ ? NativeModules.ETDGrowingIO.mode.*/var mode = __DEV__ ? NativeModules.ETDGrowingIO.mode : 'production';/" "$WORK_DIR/app/commons/config.js"
            ;;	
	esac
	setversion

}

CLEAN() {
	INFO "now is cleaning bundle and res"
	find . -name "$PROJDIR/src/main/asserts/index.android.bundle" -exec rm {} \;
	find . -name "$PROJDIR/src/main/asserts/index.android.bundle.meta" -exec rm {} \;
	find . -name "drawable-*" -type d -maxdepth 1 -exec rm -rf {} \;
	if [[ $? -ne 0 ]]; then
		 ERROR "clean fail"
		 exit 1
	else
		INFO "clean finish"
	fi
}

package() {
	# $1-appPkg $2-appName $3-appVersion $4-appVersionCode	$5-channelName $6-channelId	$7-environment	$8-buildType $9-author
	# appPkg=$1 appName=$2 appVersion=$3 appVersionCode=$4 channelName=$5 channelId=$6 environment=$7 buildType=$8 author=$9 isChannels=${10}
	
	#clean proj
	INFO "打包参数列表: appPkg:$appPkg, appName:$appName, appVersion:$appVersion, appVersionCode:$appVersionCode, channelName:$channelName, channelId:$channelId, environment:$environment, buildType:$buildType, author:$author, isChannels:$isChannels"
	gradle clean -b "${WORK_DIR}/android/app/build.gradle"
	productName="eTongDai_${channelName}_${environment}_${buildType}_No.${BUILD_NUMBER}_${timeStamp}"
	if [[ "$isChannels" == "true" ]];then
		INFO "package all channels"
		INFO "count total package time"
		channelCount=`jq '. | length' $jFile`
		packBegin=`date '+%s'`
		for (( i = 0; i < `jq '. | length' $jFile`; i++ )); do
		 	 channelName=`jq -r ".[$i] | .name" $jFile`
		 	 channelId=`jq -r ".[$i] | .value" $jFile`
		 	 productName="eTongDai_${channelName}_${environment}_${buildType}_No.${BUILD_NUMBER}_${timeStamp}"
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
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/${productName}.apk \;
		 	 	else
		 	 		INFO "libac.so is not existed"
		 	 		INFO "cp libac.so"
		 	 		cp -f $scriptsDir/ac/armeabi/libac.so ${libDir}/armeabi
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
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/${productName}.apk \;
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
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/${productName}.apk \;	
    				fi
		 	 	else
		 	 		INFO "libdu.so is not existed"
		 	 		for p in "armeabi" "armeabi-v7a" "x86" ; do
		 	 			INFO ">>>>>>cp $p"
		 	 			cp -rf $scriptsDir/shumeng/${p} ${libDir}
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
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/${productName}.apk \;
		 	 	fi
		 	 fi
		 done
		 packEnd=`date '+%s'`
		 INFO "渠道打包成功！总数量: ${channelCount} 总耗时: `echo $((packEnd - packBegin))`秒"
	elif [[ "$isChannels" == "false" ]]; then
		INFO "isChannels false to this way"
		if [[ "$channelName" == "test" ]]; then
			INFO ">>>>>>$environment"
			[[ "$environment" == "preproduction" ]] && appPkg="com.stateunion.p2p.etongdai.vest"
			INFO ">>>>>>$appPkg"
			INFO "打包开始："	
		 	timeBegin=`date '+%s'`
		 	if [[ $buildType = 'Debug' ]]; then
		 		INFO "now is building Debug package"
		 		react-native bundle --entry-file "index.android.js" --platform "android" --dev "true" --bundle-output "./android/app/src/main/assets/index.android.bundle" --assets-dest "./android/app/src/main/res/"
		 	fi
			gradle -PAPPLICATION_ID="$appPkg" -PAPP_NAME="$appName" -PAPP_VERSION_NAME="$appVersion" -PAPP_VERSION_CODE="$appVersionCode" -PBUILD_SCRIPT="${PROJDIR}/build.gradle" \
			-PUMENG_VALUE="$channelName" -PENVIRONMENT="$environment" -PLABLE="$author" "assemble${buildType}" -b "${PROJDIR}/build.gradle" --stacktrace
			if [ $? -ne 0 ]; then
        		ERROR "编译失败！"
        		exit 1
    		else
        		INFO "编译成功！耗时$(TIMECONSUMED)秒,位于：${BUILD_DIR}"
    		fi
    		INFO "move apk"
			find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/${productName}.apk \;
			
			INFO "apk..."
    		if [ -f "${WORK_DIR}/apks/${productName}.apk" ];then
        		curl -v -u "deployer:iouI&1" --upload-file "${WORK_DIR}/apks/${productName}.apk" "http://10.20.9.108:8081/nexus/repository/etd-apps/Andr/${version}/${BUILD_NUMBER}/"
    		else
        		ERROR "upload apk to nexus fail."
    		fi
    	else
    		channelId=`jq -r --arg channelName "$channelName" '.[] | select( .name | contains($channelName) ) | .value' $jFile`
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
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/${productName}.apk \;
		 	 	else
		 	 		INFO "libac.so is not existed"
		 	 		INFO "cp libac.so"
		 	 		cp -f $scriptsDir/ac/armeabi/libac.so ${libDir}/armeabi
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
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/${productName}.apk \;
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
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/${productName}.apk \;	
    				fi
		 	 	else
		 	 		INFO "libdu.so is not existed"
		 	 		for p in "armeabi" "armeabi-v7a" "x86" ; do
		 	 			INFO ">>>>>>cp $p"
		 	 			cp -rf $scriptsDir/shumeng/${p} ${libDir}
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
					find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/${productName}.apk \;
		 	 	fi
		 	 fi
    		INFO ">>>>>>$appPkg"
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
			find ${BUILD_DIR} -d 1 -name '*.apk' -exec mv {} ./apks/${productName}.apk \;
			
			INFO "apk..."
    		if [ -f "${WORK_DIR}/apks/${productName}.apk" ];then
        		curl -v -u "deployer:iouI&1" --upload-file "${WORK_DIR}/apks/${productName}.apk" "http://10.20.9.108:8081/nexus/repository/etd-apps/Andr/${version}/${BUILD_NUMBER}/"
    		else
        		ERROR "upload apk to nexus fail."
    		fi
		fi
	fi	

}

CLEAN
RESET
setconfig
package
# package "com.stateunion.p2p.etongdai" "易通贷理财" "3.0.5" "3006" "yingxiao1001" "MTA3MTQwMjA=" "production" "Release" "liushuo" "true" | tee andr.log
# package "com.stateunion.p2p.etongdai" "易通贷理财" "3.0.5" "3006" "test" "" "test" "Debug" "liushuo" "false"

