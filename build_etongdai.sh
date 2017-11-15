#!/usr/bin/env bash
#author: Liu Shuo <liushuo@glorystone.net>

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

# DEVELOPER_SIGN_NAME_SYSH="iPhone Developer: liu shuo (BEQ9V8Q9B9)"
# DEVELOPER_SIGN_NAME_SYSH="iPhone Developer: liushuo@glorystone.net (P447QKG3KS)"
DEVELOPER_SIGN_NAME_SYSH="iPhone Developer"
DEVELOPMENT_TEAM_NAME_SYSH="Beijing Yitongdai Financial Information Service Co., Ltd."
DEVELOPMENT_TEAM_ID_SYSH="7V42JS9FK2"
# PROVISIONING_PROFILE_SPECIFIER_SYSH_DEV_AUTO="Automatic"
# PROVISIONING_PROFILE_SPECIFIER_SYSH_DEV="4c15ce26-8cf2-4431-8842-50007ee27ca4"


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
    PROJDIR="${PWD}/ios"
    INFO "herehere"
else
    PROJDIR="${PWD}"
fi

INFO ">>>>>PROJDIR is: $PROJDIR"

BUILD_DIR="$WORK_DIR/build"
PKGS_PATH="$WORK_DIR/packages"
mkdir -p "$PKGS_PATH/backup"
find ${PKGS_PATH} -d 1 -name '*.ipa' -exec mv {} ${PKGS_PATH}/backup \;
DSYMS_PATH="$WORK_DIR/dsym"
mkdir -p "$DSYMS_PATH/backup"
mv ${DSYMS_PATH}/*.zip ${DSYMS_PATH}/backup/
timeStamp=$(date '+%Y%m%d-%H-%M')
timeYmd=$(date +%y%m%d)

package(){
    #                      $1               $2         $3        $4         $5             $6       
    # arguments: workspace/projectName schemeName buildConfig signName profileName provisioningStyle
    INFO "=== 开始编译打包$1: scheme $2 config $3 ==="
    RESET
    xcodeproj_dir_path=$(find $PWD -name "$1.xcodeproj" -type d)
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
                    productName="$2_$3_No.${BUILD_NUMBER}_${timeStamp}"
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

    INFO "打包开始：xcodebuild -exportArchive -archivePath $xcarchivePath -exportPath $PKGS_PATH -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates"
    timeBegin=`date '+%s'`
    xcodebuild -exportArchive -archivePath $xcarchivePath -exportPath $PKGS_PATH -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates &>/dev/null
    if [[ 0 -ne $? ]]; then
        ERROR "打包失败！耗时$(TIMECONSUMED)秒"
        [ -d $derivedDataPath ] && { rm -rf "${derivedDataPath}"; }
        exit 1
    else
        INFO "打包成功！耗时$(TIMECONSUMED)秒，位于：${PKGS_PATH}/$productName.ipa"
    fi
    RESET
    INFO "=== $1编译打包完成: scheme $2 config $3 ==="

    #rename ipa
    INFO "重命名ipa..."
    mv "${PKGS_PATH}/${1}.ipa" "${PKGS_PATH}/${productName}.ipa"
    
    #upload ipa to nexus
    if [ -f "${PKGS_PATH}/${productName}" ];then
        curl -v -u "deployer:iouI&1" --upload-file "${PKGS_PATH}/${productName}" http://10.20.9.108:8081/nexus/repository/files/
    else
        ERROR "upload ipa to nexus fail."
    fi

}

case "$build_product" in
    "eTongDai")
            package "eTongDai" "eTongDai" "Debug" "$DEVELOPER_SIGN_NAME_SYSH" "$PROVISIONING_PROFILE_SPECIFIER_SYSH_DEV_AUTO" "Automatic"
            ;;
esac

