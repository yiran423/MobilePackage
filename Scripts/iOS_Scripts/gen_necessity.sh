#!/usr/bin/env bash
#title: gen_necessity.sh
#author: Liu Shuo <liushuo@glorystone.net>
#date: 21 Nov, 2017

INFO(){ echo -e "\x1B[35m$1\x1B[0m"; }
ERROR(){ echo -e "\x1B[31m$1\x1B[0m"; }

[ -d necessity ] || mkdir -p necessity
plistpath="necessity/manifest.plist"
htmlpath="necessity/index.html"
imgpath="$iOS_Scripts/AppIcon60x60@3x.png"

#gen plist
cat << EOF > $plistpath
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>items</key>
	<array>
		<dict>
			<key>assets</key>
			<array>
				<dict>
					<key>kind</key>
					<string>software-package</string>
					<key>url</key>
					<string>https://nexus.zgc.etongdai.org/nexus/repository/etd-apps/${short_version}/${BUILD_NUMBER}/${productName}.ipa</string>
				</dict>
			</array>
			<key>metadata</key>
			<dict>
				<key>bundle-identifier</key>
				<string>com.stateunion.p2p.etongdai</string>
				<key>bundle-version</key>
				<string>${short_version}</string>
				<key>kind</key>
				<string>software</string>
				<key>title</key>
				<string>易通贷理财</string>
			</dict>
		</dict>
	</array>
</dict>
</plist>
EOF

#gen html
cat << EOF > $htmlpath
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=320, user-scalable=no" />
    <meta content="telephone=no" name="format-detection" />
    <link rel="stylesheet" href="/public/stylesheets/style.css">
    <style>
    #header {
        /*background-color:Aquamarine;*/
        color: DodgerBlue;
        text-align:center;
        height:60px;
        width:294px;
        padding:5px;
    }

    .btn {
        display: inline-block;
        padding: 15px 25px;
        font-size: 20px;
        cursor: pointer;
        text-align: center;
        text-decoration: none;
        outline: none;
        color: white;
        background-color: DodgerBlue;
        border: none;
        border-radius: 15px;
        box-shadow: 0 9px #999;
    }
    #img {
        text-align:center;
        height:100%;
        width:90%;
        padding:15px;
    }
    </style>
    <title>易通贷iOS版下载页</title>
</head>
<body bgcolor="LightGray">
    <div align="center" id="header"><h2>易通贷iOS</h2></div>
    <div align="center" id="img"><img src="AppIcon60x60@3x.png" class="icon"/></div>
    <div align="center" id="header"><h4>请点击下方按钮进行安装</h4></div>
    <div align="center">
        <form>
            <input type="button" class="btn" value="点击安装" onclick="window.location.href='itms-services://?action=download-manifest&url=https://nexus.zgc.etongdai.org/nexus/repository/etd-apps/iOS/${short_version}/${BUILD_NUMBER}/manifest.plist'" />
        </form>
    </div>
</body>
</html>
EOF

INFO "upload plist and html to nexus"
if [ -f "${plistpath}" ];then
    curl -v -u "deployer:iouI&1" --upload-file "${plistpath}" "http://10.20.9.108:8081/nexus/repository/etd-apps/iOS/${short_version}/${BUILD_NUMBER}/"
else
    ERROR "upload plist to nexus fail."
fi

if [ -f "${htmlpath}" ];then
    curl -v -u "deployer:iouI&1" --upload-file "${htmlpath}" "http://10.20.9.108:8081/nexus/repository/etd-apps/iOS/${short_version}/${BUILD_NUMBER}/"
else
    ERROR "upload html to nexus fail."
fi

INFO "upload plist and img to nexus"
if [ -f "${htmlpath}" ];then
    curl -v -u "deployer:iouI&1" --upload-file "${imgpath}" "http://10.20.9.108:8081/nexus/repository/etd-apps/iOS/${short_version}/${BUILD_NUMBER}/"
else
    ERROR "upload img to nexus fail."
fi





