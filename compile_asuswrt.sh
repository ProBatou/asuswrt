#!/bin/bash

BOTNAME=Build-Notify
AVATAR_URL="https://a.fsdn.com/allura/p/asuswrt-merlin/icon?1561187555?&w=90"
WEBHOOK="https://discord.com/api/webhooks/964958022826868766/IblcZagFYogtPJjfsK-rLqtkwOaaIzu3BimhUEIlKOty7p1SpGe_1jlEvKVW4zi7tq7z"
DATE=$(date +"%d/%m/%Y")
HEURE=$(date +"%H:%M:%S")
getCurrentTimestamp() { date -u --iso-8601=seconds; };

path=$PWD
latestVersion=$(cat $path/version.txt)
version=$(curl --silent https://www.asuswrt-merlin.net/  | perl -ln0e '/<table.*?table>/s;print $&' | grep -A 3 -B 1 RT-AX56U | html2text | sed '2!d')

if [ "$latestVersion" = "$version" ]; then
    echo "Version is equal"
else

    echo "New version available"

wget -q https://codeload.github.com/RMerl/asuswrt-merlin.ng/tar.gz/refs/tags/$version

echo "Downlad finished"

if [ -d "$path/amng-build/" ]; then
  echo "Folder exist"
else
  mkdir $path/amng-build
  echo "Folder created"
fi

tar -xf $version --strip 1 -C $path/amng-build && rm $path/$version

echo "Tar extracted"

sed -i '/X-Frame-Options/d' $path/amng-build/release/src/router/curl/tests/data/test1270
sed -i '/X-Frame-Options/d' $path/amng-build/release/src/router/lighttpd-1.4.39/src/response.c
sed -i '/X-Frame-Options/d' $path/amng-build/release/src/router/samba-3.6.x/source/source3/web/swat.c
sed -i '/X-Frame-Options/d' $path/amng-build/release/src/router/samba-3.0.33/source/web/swat.c
sed -i '/x-frame-options/d' $path/amng-build/release/src/router/httpd/httpd.c
sed -i '/X-Frame-Options/d' $path/amng-build/release/src/router/vsftpd-3.x/postlogin.c
sed -i '/x-xss-protection/d' $path/amng-build/release/src/router/httpd/httpd.c

echo "Frame removed"

cd $path/amng-build/release/src-rt-5.02axhnd.675x/ && /usr/bin/make -s --no-print-directory rt-ax56u

error=$?

sudo rm /var/www/html/asuswrt/*

sudo cp $(find $path/amng-build/release/src-rt-5.02axhnd.675x/ -name *_cferom_pureubi.w) /var/www/html/asuswrt/

changelog=$(sed -e "s/\r//g" $path/amng-build/Changelog-NG.txt | sed -n "/$version/,/^$/{/./p}" | sed -e "s/$/\\\\n /g" | tr '\n' ' ')

rm -r $path/amng-build/

echo "Build finished"

if [ $error = 0 ]; then

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
