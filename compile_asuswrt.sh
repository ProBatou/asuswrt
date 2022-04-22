#!/bin/bash

version=$(curl --silent https://www.asuswrt-merlin.net/ | perl -ln0e '/<table.*?table>/s;print $&' | grep -A 3 -B 1 RT-AX56U | html2text | sed '2!d')
BOTNAME=Build-Notify
AVATAR_URL="https://a.fsdn.com/allura/p/asuswrt-merlin/icon?1561187555?&w=90"
getCurrentTimestamp() { date -u --iso-8601=seconds; }
path=$PWD

if [ whoami == "root" ]; then
    echo "You can't compile the firmware as root user"
    exit
fi

if [ ! -w /var/www/html/ ]; then
    echo "You don't have permission to write to /var/www/html/"
    exit
fi

if [ ! -w $path ]; then
    echo "You don't have permission to write to this folder"
    exit
fi

if [ -f "$path/WEBHOOK.txt" ]; then
    WEBHOOK=$(cat $path/WEBHOOK.txt)
    echo "Webhook url define"
else
    touch $path/WEBHOOK.txt
    read -p "what is the url of the webhook"$'\n'
    echo $REPLY >>WEBHOOK.txt
fi

if [ -f "$path/version.txt" ]; then
    latestVersion=$(cat $path/version.txt)
    echo "file exist"
else
    touch $path/version.txt
    echo "000" >version.txt
    latestVersion=$(cat $path/version.txt)
    echo "file created"
fi

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

    pv $version | tar -xzf - --strip 1 -C $path/amng-build
    rm $path/$version
    echo "Archive extracted"

    start=$(date +%s)
    find $path/amng-build/ -type f | xargs grep -l -s "X-Frame-Options" | xargs sed -i '/X-Frame-Options/d'
    echo "X-Frame-Options removed"
    find $path/amng-build/ -type f | xargs grep -l -s "x-frame-options" | xargs sed -i '/x-frame-options/d'
    echo "x-frame-options removed"
    find $path/amng-build/ -type f | xargs grep -l -s "x-xss-protection" | xargs sed -i '/x-xss-protection/d'
    echo "x-xss-protection removed"
    find $path/amng-build/ -type f | xargs grep -l -s "top.location" | xargs sed -i 's/top.location/location/g'
    echo "top.location replaced"
    find $path/amng-build/ -type f | xargs grep -l -s "parent.location" | xargs sed -i 's/parent.location/location/g'
    echo "parent.location replaced"
    find $path/amng-build/ -type f | xargs grep -l -s " window.top" | xargs sed -i 's/ window.top/ window/g'
    echo "window.top replaced"
    find $path/amng-build/ -type f | xargs grep -l -s "top.document" | xargs sed -i 's/top.document/document/g'
    echo "top.document replaced"
    find $path/amng-build/ -type f | xargs grep -l -s "top.isIE8" | xargs sed -i 's/top.isIE8/isIE8/g'
    echo "top.isIE8 replaced"
    find $path/amng-build/ -type f | xargs grep -l -s "\!parent\." | xargs sed -i 's/!parent./!/g'
    echo "!parent. replaced"

    sed -i 's/$(MAKE)/$(MAKE) -j 24 -s --no-print-directory/g' amng-build/release/src-rt/Makefile
    echo "make - replaced"
    sed -i 's/make -j 9/make -j 24 -/g' amng-build/release/src-rt/Makefile
    echo "make - replaced"
    sed -i 's/make -j3/make -j 24 -/g' amng-build/release/src-rt/Makefile
    echo "make - replaced"
    sed -i 's/make -/make -s --no-print-directory -/g' amng-build/release/src-rt/Makefile
    echo "make - replaced"

    end=$(date +%s)
    runtimeSed=$((end - start))
    echo "All replacements done in $runtimeSed seconds"

    start=$(date +%s)
    make -j 24 -C $path/amng-build/release/src-rt-5.02axhnd.675x/ -s --no-print-directory rt-ax56u
    error=$?
    end=$(date +%s)
    runtime=$((end - start))

    if (($runtime > 3600)); then
        let "hours=runtime/3600"
        let "minutes=(runtime%3600)/60"
        let "seconds=(runtime%3600)%60"
        runtime="in $hours hour(s), $minutes minute(s) and $seconds second(s)"
    elif (($runtime > 60)); then
        let "minutes=(runtime%3600)/60"
        let "seconds=(runtime%3600)%60"
        runtime="in $minutes minute(s) and $seconds second(s)"
    else
        runtime="in $runtime seconds"
    fi

    if (($runtimeSed > 3600)); then
        let "hours=runtimeSed/3600"
        let "minutes=(runtimeSed%3600)/60"
        let "seconds=(runtimeSed%3600)%60"
        runtimeSed="in $hours hour(s), $minutes minute(s) and $seconds second(s)"
    elif (($runtimeSed > 60)); then
        let "minutes=(runtimeSed%3600)/60"
        let "seconds=(runtimeSed%3600)%60"
        runtimeSed="in $minutes minute(s) and $seconds second(s)"
    else
        runtimeSed="in $runtime seconds"
    fi

    echo "Build finished"

    if [ $error = 0 ]; then

        echo "Build success"

        if [ -d "/var/www/html/asuswrt" ]; then
            rm -rf /var/www/html/asuswrt/*
            echo "Folder exist remove file in it"
        else
            mkdir /var/www/html/asuswrt
            echo "Folder created"
        fi

        changelog=$(sed -e "s/\r//g" $path/amng-build/Changelog-NG.txt | sed -n "/$version/,/^$/{/./p}" | sed -e "s/$/\\\\n /g" | tr '\n' ' ')

        cp $(find $path/amng-build/release/src-rt-5.02axhnd.675x/ -name *_cferom_pureubi.w) /var/www/html/asuswrt/
        cp $(find $path/amng-build/release/src-rt-5.02axhnd.675x/ -name *_cferom_pureubi.w) $path/

        rm -rf $path/amng-build/
        sed -i "s/$latestVersion/$version/g" $path/version.txt

        curl -i --silent \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST \
            --data '{
            "username": "'"$BOTNAME"'",
            "avatar_url": "'"$AVATAR_URL"'",
            "embeds": [{
                "color": 3329330,
                "title": "Build sucsessfully '"$runtime"' and apply patch '"$runtimeSed"'",
                "author": { "name": "'"$BOTNAME"'", "icon_url": "'"$AVATAR_URL"'" },
                "footer": { "icon_url": "'"$AVATAR_URL"'", "text": "'"$BOTNAME"'" },
                "description": "New update for router RT-AX56U\n\n**Patch Note: ** '"$changelog"'\n",
                "timestamp": "'$(getCurrentTimestamp)'"
            }]
        }' $WEBHOOK >/dev/null

        echo "Build notification sent"

    else
        echo "Build failed"

        curl -i --silent \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST \
            --data '{
            "username": "'"$BOTNAME"'",
            "avatar_url": "'"$AVATAR_URL"'",
            "embeds": [{
                "color": 12976176,
                "title": "Build failed '"$runtime"'",
                "author": { "name": "'"$BOTNAME"'", "icon_url": "'"$AVATAR_URL"'" },
                "footer": { "icon_url": "'"$AVATAR_URL"'", "text": "'"$BOTNAME"'" },
                "description": "Build fail \n",
                "timestamp": "'$(getCurrentTimestamp)'"
            }]
        }' $WEBHOOK >/dev/null

        echo "Build notification sent"

    fi
fi
