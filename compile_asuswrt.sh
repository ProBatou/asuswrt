#!/bin/bash

BOTNAME=Build-Notify
AVATAR_URL="https://a.fsdn.com/allura/p/asuswrt-merlin/icon?1561187555?&w=90"
path=$PWD

if [ -f "$path/WEBHOOK.txt" ]; then
    WEBHOOK=$(cat $path/WEBHOOK.txt)
    echo "Webhook url define"
else
    touch $path/WEBHOOK.txt
    read -p "what is the url of the webhook"$'\n'
    echo $REPLY >> WEBHOOK.txt
fi

DATE=$(date +"%d/%m/%Y")
HEURE=$(date +"%H:%M:%S")
getCurrentTimestamp() { date -u --iso-8601=seconds; };

if [ -d "$path/version.txt" ]; then
    latestVersion=$(cat $path/version.txt)
    echo "file exist"
else
  touch $path/version.txt
  echo "file created"
fi

version=$(curl --silent https://www.asuswrt-merlin.net/  | perl -ln0e '/<table.*?table>/s;print $&' | grep -A 3 -B 1 RT-AX56U | html2text | sed '2!d')

if [ "$latestVersion" = "$version" ]; then
    echo "Version is equal"
else

    echo "New version available"

wget -q --show-progress https://codeload.github.com/RMerl/asuswrt-merlin.ng/tar.gz/refs/tags/$version

echo "Downlad finished"

if [ -d "$path/amng-build/" ]; then
  echo "Folder exist"
else
  mkdir $path/amng-build
  echo "Folder created"
fi

pv -p $version | tar -xf $version --strip 1 -C $path/amng-build && rm $path/$version

echo "Tar extracted"

sed -i '/X-Frame-Options/d' $path/amng-build/release/src/router/curl/tests/data/test1270
sed -i '/X-Frame-Options/d' $path/amng-build/release/src/router/lighttpd-1.4.39/src/response.c
sed -i '/X-Frame-Options/d' $path/amng-build/release/src/router/samba-3.6.x/source/source3/web/swat.c
sed -i '/X-Frame-Options/d' $path/amng-build/release/src/router/samba-3.0.33/source/web/swat.c
sed -i '/x-frame-options/d' $path/amng-build/release/src/router/httpd/httpd.c
sed -i '/X-Frame-Options/d' $path/amng-build/release/src/router/vsftpd-3.x/postlogin.c
sed -i '/x-xss-protection/d' $path/amng-build/release/src/router/httpd/httpd.c

find $path/amng-build/release/src/router/www/ -type f | xargs grep -l "top.location.href" | xargs sed -i 's/top.location.href/location.href/g'

echo "Frame removed"

cd $path/amng-build/release/src-rt-5.02axhnd.675x/ && /usr/bin/make -s --no-print-directory rt-ax56u

error=$?

if [ -d "/var/www/html/asuswrt" ]; then
    sudo rm -rf /var/www/html/asuswrt/*
    echo "Folder exist remove file in it"
else
    sudo mkdir /var/www/html/asuswrt
    echo "Folder created"
fi

sudo cp $(find $path/amng-build/release/src-rt-5.02axhnd.675x/ -name *_cferom_pureubi.w) /var/www/html/asuswrt/

changelog=$(sed -e "s/\r//g" $path/amng-build/Changelog-NG.txt | sed -n "/$version/,/^$/{/./p}" | sed -e "s/$/\\\\n /g" | tr '\n' ' ')

echo "Build finished"

if [ $error = 0 ]; then

sudo rm -rf $path/amng-build/

sed -i "s/$latestVersion/$version/g" $path/version.txt

    curl -i --silent \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST \
        --data  '{
            "username": "'"$BOTNAME"'",
            "avatar_url": "'"$AVATAR_URL"'",
            "embeds": [{
                "color": 3329330,
                "title": "Build sucsessfully",
                "author": { "name": "'"$BOTNAME"'", "icon_url": "'"$AVATAR_URL"'" },
                "footer": { "icon_url": "'"$AVATAR_URL"'", "text": "'"$BOTNAME"'" },
                "description": "Nouvelle mise a jour pour le routeur asus RT-AX56U\n\n**Patch Note: ** '"$changelog"'\n",
                "timestamp": "'$(getCurrentTimestamp)'"
            }]
        }' $WEBHOOK > /dev/null

        echo "Build notification sent"

else

    curl -i --silent \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST \
        --data  '{
            "username": "'"$BOTNAME"'",
            "avatar_url": "'"$AVATAR_URL"'",
            "embeds": [{
                "color": 12976176,
                "title": "Build failed",
                "author": { "name": "'"$BOTNAME"'", "icon_url": "'"$AVATAR_URL"'" },
                "footer": { "icon_url": "'"$AVATAR_URL"'", "text": "'"$BOTNAME"'" },
                "description": "Build fail \n",
                "timestamp": "'$(getCurrentTimestamp)'"
            }]
        }' $WEBHOOK > /dev/null

        echo "Build notification sent"

fi
fi
