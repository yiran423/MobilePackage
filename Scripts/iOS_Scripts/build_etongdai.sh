#!/usr/bin/env bash
#title: build_etongdai.sh
#author: Liu Shuo <liushuo@glorystone.net>
#date: 13 Nov, 2017

if [ -d "$WORKSPACE" ]; then
    WORK_DIR="$WORKSPACE"
    iOS_Scripts="$WORKSPACE/Scripts/iOS_Scripts"
else
    iOS_Scripts="$PWD"
    WORK_DIR=${iOS_Scripts%/*}
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

for i in $@; do
    eval $i
    if [ $? -ne 0 ]; then
        echo "参数错误:$i"
        exit 1
    fi
done

if [ -z "$build_product" ]; then
   ERROR "用法：$(basename $0) build_product=eTongDai"
   exit 1
fi

if [[ $build_product == "eTongDai" ]]; then
    PROJDIR="${WORK_DIR}/ios"
    INFO "herehere"
else
    PROJDIR="${WORK_DIR}/ios"
fi

INFO ">>>>>PROJDIR is: $PROJDIR"

BUILD_DIR="$WORK_DIR/build"
PKGS_PATH="$WORK_DIR/packages"
SIM_PATH="$WORK_DIR/simOutput"
mkdir -p "$PKGS_PATH/backup"
find ${PKGS_PATH} -d 1 -name '*.ipa' -exec mv {} ${PKGS_PATH}/backup \;
# DSYMS_PATH="$WORK_DIR/dsym"
# mkdir -p "$DSYMS_PATH/backup"
# mv ${DSYMS_PATH}/*.zip ${DSYMS_PATH}/backup/
timeStamp=$(date '+%y%m%d-%H-%M')
timeYmd=$(date +%y%m%d)

setversion() {
    INFO "set version"
    info_plist=$(find $PROJDIR/$build_product -d 1 -name "Info.plist" -type f)
    INFO "info_plist is: $info_plist"
    short_ver=$(/usr/libexec/PlistBuddy "$info_plist" -c "Print CFBundleShortVersionString")
    headVer=`echo $short_ver | awk -F "." '{print $1}'`
    midVer=`echo $short_ver | awk -F "." '{print $2}'`
    tailVer=`echo $short_ver | awk -F "." '{print $3}'`
    # tailVerM=$(( ++tailVer ))
    tailVerM=$(( tailVer ))
    versionM="${headVer}.0.${midVer}.${tailVerM}"
    INFO "short_ver is: $short_ver"
    INFO "versionM is: $versionM"
    sed -i '' "s#appVersion.*#appVersion: '$short_ver', //app#" "$WORK_DIR/app/commons/config.js"
    sed -i '' "s#appAndroidVersion.*#appAndroidVersion: '$versionM', //android app#" "$WORK_DIR/app/commons/config.js"
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

# DEVELOPER_SIGN_NAME_SYSH="iPhone Developer: liu shuo (BEQ9V8Q9B9)"
# DEVELOPER_SIGN_NAME_SYSH="iPhone Developer: liushuo@glorystone.net (P447QKG3KS)"
DEVELOPER_SIGN_NAME_SYSH="iPhone Developer"
DEVELOPMENT_TEAM_NAME_SYSH="Beijing Yitongdai Financial Information Service Co., Ltd."
DEVELOPMENT_TEAM_ID_SYSH="7V42JS9FK2"
PROVISIONING_PROFILE_SPECIFIER_SYSH_DEV_AUTO="Automatic"
# PROVISIONING_PROFILE_SPECIFIER_SYSH_DEV="4c15ce26-8cf2-4431-8842-50007ee27ca4"

package(){
    #                      $1               $2         $3        $4         $5             $6       
    # arguments: workspace/projectName schemeName buildConfig signName profileName provisioningStyle
    INFO "=== 开始编译打包$1: scheme $2 config $3 ==="
    # RESET
    xcodeproj_dir_path=$(find $WORK_DIR -name "$1.xcodeproj" -type d)
    INFO "设置sign name，profile和dSYM配置"
    ruby -e "require 'xcodeproj'
        xcproj = Xcodeproj::Project.open('$xcodeproj_dir_path')
        target_id = xcproj.targets.select {|target| target.name == '$2' }.first.uuid
        puts target_id
        attributes = xcproj.root_object.attributes['TargetAttributes']
        target_attributes = attributes[target_id]
        target_attributes['ProvisioningStyle'] = '$6'
        xcproj.targets.each do |target|
            if target.display_name == '$2'
                target.build_configurations.each do |config|
                  if config.name == '$3'
                    #config.build_settings['CODE_SIGN_IDENTITY'] = '$4'
                    config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = '$4'
                    # config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'testtesttest111'
                    #config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = '$5'
                    config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
                  end
                end
            end
        end
        xcproj.save"

    if [ $? -ne 0 ]; then
        ERROR "设置sign name，profile或dSYM失败！"
        exit 1
    fi

    info_plist_path=$(find $PROJDIR/$1 -d 1 -name "Info.plist" -type f)
    INFO "info_plist_path is: $info_plist_path"
    short_version=$(/usr/libexec/PlistBuddy "$info_plist_path" -c "Print CFBundleShortVersionString")
    INFO "short_version is: $short_version"
    version="$short_version.${timeYmd}${BUILD_NUMBER}"
    INFO "修改长版本号为${version}"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $version" ${info_plist_path}

    case "$1" in
        eTongDai)
                case $5 in
                    "$PROVISIONING_PROFILE_SPECIFIER_SYSH_DEV_AUTO")
                        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.stateunion.p2p.etongdai"  ${info_plist_path}
                        ruby -e "require 'xcodeproj'
                            xcproj = Xcodeproj::Project.open('$xcodeproj_dir_path')
                            xcproj.targets.each do |target|
                                if target.display_name == '$2'
                                    target.build_configurations.each do |config|
                                      if config.name == '$3'
                                          config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.stateunion.p2p.etongdai'
                                      end
                                    end
                                end
                            end
                            xcproj.save"
                    productName="$2_$3_${environment}_${short_version}_No.${BUILD_NUMBER}_${timeStamp}"
                    ;;
                    *)
                        INFO "需要新增PROVISIONING_PROFILE_SPECIFIER"
                        ;;
                esac
            ;;
        *)
            INFO "需要新增projectName"
            ;;
    esac

    if [[ "$pushServices" == "true" ]]; then
        INFO "go pushServices way"
        ruby -e "require 'xcodeproj'
        xcproj = Xcodeproj::Project.open('$xcodeproj_dir_path')
        xcproj.targets.each do |target|
            if target.display_name == '$2'
                target.build_configurations.each do |config|
                    puts 'go in this way $2'
                    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.etongdai.product'
                end
            elsif target.display_name == '${2}NotifyService'
                target.build_configurations.each do |config|
                    puts 'go in this way ${2}NotifyService'
                    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.etongdai.product.notifyservice'
                end
            end
        end
        xcproj.save"
        appKey="9e2cf131bcaa181162a717a3"
        info_notify_path=$(find $PROJDIR/${1}NotifyService -d 1 -name "Info.plist" -type f)
        sed -i '' 's/\(^.*JPUSHService setupWithOption:launchOptions appKey:@\).*$/\1'\"$appKey\"'/' "$PROJDIR/$1/Main/AppDelegate.m"
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.etongdai.product"  ${info_plist_path}
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.etongdai.product.notifyservice"  ${info_notify_path}
    fi

    derivedDataPath="$BUILD_DIR"
    xcarchivePath="${derivedDataPath}/$2.xcarchive"

    if [ $? -eq 0 ]; then
        INFO "编译开始：$xcodebuild clean archive -project ${PROJDIR}/${1}.xcodeproj -scheme $2 -sdk iphoneos -configuration $3 -derivedDataPath ${derivedDataPath} -archivePath ${xcarchivePath}"
        timeBegin=`date '+%s'`
        xcodebuild clean archive -project "$PROJDIR/${1}.xcodeproj" -scheme "$2" -sdk iphoneos -configuration "$3" -derivedDataPath "${derivedDataPath}" -archivePath "${xcarchivePath}"
    else
        INFO "编译环境异常!退出脚本..."
        exit 1
    fi

    if [ $? -ne 0 ]; then
        ERROR "编译失败！"
        exit 1
    else
        INFO "编译成功！耗时$(TIMECONSUMED)秒"
    fi

    appPath="$(find ${xcarchivePath} -name "*.app" | head -n1)"

    INFO ">>>>>appPath is: $appPath"

    INFO "打包开始：xcodebuild -exportArchive -archivePath $xcarchivePath -exportPath $PKGS_PATH -exportOptionsPlist $iOS_Scripts/ExportOptions.plist -allowProvisioningUpdates"
    timeBegin=`date '+%s'`
    xcodebuild -exportArchive -archivePath $xcarchivePath -exportPath $PKGS_PATH -exportOptionsPlist $iOS_Scripts/ExportOptions.plist -allowProvisioningUpdates &>/dev/null
    if [[ 0 -ne $? ]]; then
        ERROR "打包失败！耗时$(TIMECONSUMED)秒"
        [ -d $derivedDataPath ] && { rm -rf "${derivedDataPath}"; }
        exit 1
    else
        INFO "打包成功！耗时$(TIMECONSUMED)秒，位于：${PKGS_PATH}/$productName.ipa"
    fi
    # RESET
    INFO "=== $1编译打包完成: scheme $2 config $3 ==="

    #rename ipa
    INFO "重命名ipa..."
    mv "${PKGS_PATH}/${1}.ipa" "${PKGS_PATH}/${productName}.ipa"
    
    #upload ipa to nexus
    INFO "上传ipa..."
    if [ -f "${PKGS_PATH}/${productName}.ipa" ];then
        curl -v -u "deployer:iouI&1" --upload-file "${PKGS_PATH}/${productName}.ipa" "http://10.20.9.108:8081/nexus/repository/etd-apps/iOS/${short_version}/${BUILD_NUMBER}/"
    else
        ERROR "upload ipa to nexus fail."
    fi

}

case "$build_product" in
    "eTongDai")
        if [[ "$simulator" == "false" ]]; then
            RESET
            setconfig
            package "eTongDai" "eTongDai" "$buildType" "$DEVELOPER_SIGN_NAME_SYSH" "$PROVISIONING_PROFILE_SPECIFIER_SYSH_DEV_AUTO" "Automatic"
            RESET
        else
            RESET
            setconfig
            xcodebuild clean build -project "${PROJDIR}/eTongDai.xcodeproj" -scheme "eTongDai" -configuration "$buildType" -sdk "iphonesimulator" -derivedDataPath "$SIM_PATH"
            RESET
            simApp="eTongDai_${buildType}_${appVersion}_No.${BUILD_NUMBER}_${timeStamp}"
            INFO "重命名app..."
            mv "${SIM_PATH}/Build/Products/Debug-iphonesimulator/eTongDai.app" "${SIM_PATH}/Build/Products/Debug-iphonesimulator/${simApp}.app"
            INFO "上传app..."
            if [ -d "${SIM_PATH}/Build/Products/Debug-iphonesimulator/${simApp}.app" ];then
                cd "${SIM_PATH}/Build/Products/Debug-iphonesimulator"
                zip -qr "${simApp}.zip" "${simApp}.app"
                curl -v -u "deployer:iouI&1" --upload-file "${SIM_PATH}/Build/Products/Debug-iphonesimulator/${simApp}.zip" "http://10.20.9.108:8081/nexus/repository/etd-apps/iOS/simulator/${appVersion}/${BUILD_NUMBER}/"
                INFO "http://10.20.9.108:8081/nexus/repository/etd-apps/iOS/simulator/${appVersion}/${BUILD_NUMBER}/"
            else
                ERROR "upload app to nexus fail."
            fi
        fi
            ;;  
esac

