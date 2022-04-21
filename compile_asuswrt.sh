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

pv -p $version | tar -xzf $version --strip 1 -C $path/amng-build && rm $path/$version

echo "Archive extracted"

find $path/amng-build/ -type f | xargs grep -l -s "X-Frame-Options" | xargs sed -i '/X-Frame-Options/d'
find $path/amng-build/ -type f | xargs grep -l -s "x-frame-options" | xargs sed -i '/x-frame-options/d'
find $path/amng-build/ -type f | xargs grep -l -s "x-xss-protection" | xargs sed -i '/x-xss-protection/d'
find $path/amng-build/ -type f | xargs grep -l -s "top.location.href" | xargs sed -i 's/top.location.href/window.location.href/g'
find $path/amng-build/ -type f | xargs grep -l -s " window.top" | xargs sed -i 's/ window.top/ window/g'


echo "Patch applied"

start=`date +%M:%S`
cd $path/amng-build/release/src-rt-5.02axhnd.675x/ && /usr/bin/make -s --no-print-directory rt-ax56u
error=$?
end=`date +%M:%S`

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

#sudo rm -rf $path/amng-build/

sed -i "s/$latestVersion/$version/g" $path/version.txt

runtime=$((end-start))

    curl -i --silent \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST \
        --data  '{
            "username": "'"$BOTNAME"'",
            "avatar_url": "'"$AVATAR_URL"'",
            "embeds": [{
                "color": 3329330,
                "title": "Build sucsessfully in '"$runtime"'s",
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
