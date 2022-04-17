#!/bin/sh

version=$(curl --silent https://www.asuswrt-merlin.net/  | perl -ln0e '/<table.*?table>/s;print $&' | grep -A 3 -B 1 RT-AX56U | html2text | sed '2!d')
path="/root/asuswrt"

BOTNAME=Build-Notify
AVATAR_URL="https://a.fsdn.com/allura/p/asuswrt-merlin/icon?1561187555?&w=90"
WEBHOOK="https://discord.com/api/webhooks/964958022826868766/IblcZagFYogtPJjfsK-rLqtkwOaaIzu3BimhUEIlKOty7p1SpGe_1jlEvKVW4zi7tq7z"
DATE=$(date +"%d/%m/%Y")
HEURE=$(date +"%H:%M:%S")
getCurrentTimestamp() { date -u --iso-8601=seconds; };

latestVersion=$(cat $path/version.txt)

if [ "$latestVersion" = "$version" ]; then
    echo "Version is equal"
else

wget -nv https://codeload.github.com/RMerl/asuswrt-merlin.ng/tar.gz/refs/tags/$version

mkdir $path/asuswrt-merlin.ng

tar -xf $version --strip 1 -C $path/asuswrt-merlin.ng && rm $version

sed -i '/X-Frame-Options/d' $path/asuswrt-merlin.ng/release/src/router/curl/tests/data/test1270
sed -i '/X-Frame-Options/d' $path/asuswrt-merlin.ng/release/src/router/lighttpd-1.4.39/src/response.c
sed -i '/X-Frame-Options/d' $path/asuswrt-merlin.ng/release/src/router/samba-3.6.x/source/source3/web/swat.c
sed -i '/X-Frame-Options/d' $path/asuswrt-merlin.ng/release/src/router/samba-3.0.33/source/web/swat.c
sed -i '/X-Frame-Options/d' $path/asuswrt-merlin.ng/release/src/router/httpd/httpd.c
sed -i '/X-Frame-Options/d' $path/asuswrt-merlin.ng/release/src/router/vsftpd-3.x/postlogin.c


#make asus



error=$?

if [ $error = 0 ]; then

sed -i "s/$latestVersion/$version/g" $path/version.txt

changelog=$(sed -e "s/\r//g" $path/Changelog-NG.txt | sed -n "/$version/,/^$/{/./p}" | sed -e "s/$/\\\\n /g" a | tr '\n' ' ')

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

fi
fi