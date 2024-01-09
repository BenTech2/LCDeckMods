#!/bin/bash

R2REPO="ebkr/r2modmanPlus"; 
R2FILENAME=$(curl -s https://api.github.com/repos/${R2REPO}/releases/latest | grep "browser_download_url.*AppImage" | head -1 | cut -d : -f 2,3 | tr -d \" | xargs basename )

#close steam
killall steam || pkill steam

downloadR2 () {
    mkdir -p $HOME/Desktop/Mods/R2ModManager
    cd $HOME/Desktop/Mods/R2ModManager
    curl -s https://api.github.com/repos/${R2REPO}/releases/latest | grep "browser_download_url.*AppImage" | head -1 | cut -d : -f 2,3 | tr -d \" | wget --show-progress -qi - || echo "-> Could not download the latest version of '${REPO}' for your architecture." # if you're polite
    chmod +x $R2FILENAME
    cd ..
}

downloadSteamTinker () {
    git clone https://github.com/sonic2kk/steamtinkerlaunch.git steamtinkerlaunch
    cd steamtinkerlaunch
    ./steamtinkerlaunch addnonsteamgame -an="R2ModManager" -ep="$HOME/Desktop/Mods/R2ModManager/${R2FILENAME}" -sd="$HOME/Desktop/Mods/R2ModManager/" -ip="/path/to/game/icon" -lo="--no-sandbox" -t="Tag1,Tag2"
}

addlaunchoptions () {
    STEAM_USER_ID=$(ls $HOME/.local/share/Steam/userdata/)
    #echo $STEAM_USER_ID
    # Path to Steam userdata
    STEAM_USERDATA="$HOME/.local/share/Steam/userdata/$STEAM_USER_ID"
    #echo $STEAM_USERDATA
    # Check if userdata directory exists
    if [ ! -d "$STEAM_USERDATA" ]; then
        echo "Steam userdata directory not found."
        exit 1
    fi
    FILE_PATH="$STEAM_USERDATA/config/localconfig.vdf"
    SECTION="\"1966720\"" #steam game id for Lethal Company
    NEW_ENTRY="\t\t\t\t\t\t\"LaunchOptions\"\t\t\"-screen-width 1280 -screen-height 800 +r_forceaspectratio 1.485\""
    # awk -v section="$SECTION" -v new_entry="$NEW_ENTRY" '
    #     $0 ~ section {print; getline; print; flag=1; next}
    #     flag && /}/ {print new_entry; flag=0}
    #     {print}
    # ' "$FILE_PATH" > tmpfile && mv tmpfile "$FILE_PATH"
    awk -v section="$SECTION" -v new_entry="$NEW_ENTRY" '
    $0 ~ section {print; in_section=1; next}
    in_section && /"LaunchOptions"/ {print new_entry; skip=1; next}
    in_section && /}/ {if (!skip) print new_entry; skip=0; in_section=0}
    in_section {print; next}
    {print}
' "$FILE_PATH" > tmpfile && mv tmpfile "$FILE_PATH"
}

downloadR2
downloadSteamTinker
addlaunchoptions
qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout