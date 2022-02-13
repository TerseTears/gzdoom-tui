#!/usr/bin/env bash

export NEWT_COLORS='
border=yellow,red
button=green,blue
entry=white,blue
checkbox=white,blue
actcheckbox=brightred,green
compactbutton=lightgray,blue
listbox=white,blue
actlistbox=lightgray,brightgreen
actsellistbox=white,brightgreen
root=,gray
roottext=brightcyan,green
sellistbox=green,brightgreen
textbox=lightgray,brightblue
title=white,gray
window=,blue
'

! [[ -e "modnames.csv" ]] && touch "modnames.csv"

modspath=~/.config/gzdoom/Gameplay/
levelspath=~/.config/gzdoom/Levels/

return_indices() {
    local -n selection_array="$1"
    local -n indices="$2"
    local return_array=()
    for index in "${indices[@]}"
    do
        return_array+=("${selection_array["$index"]}")
    done
    echo "${return_array[@]}"
}

setup_list() {
    local -n _files="$1"
    local _file_names=("${_files[@]##*/}")
    local _file_names=("${_file_names[@]%.*}")

    local _file_args=()
    for index in "${!_files[@]}"
    do
        _file_args+=("$index" "${_file_names["$index"]}" OFF)
    done
    echo "${_file_args[@]}"
}

folder_checkview() {
    local files=("$1"*)
    local file_args=($(setup_list files))

    # separate-output is absolutely essential otherwise whiptail adds quotes around
    local files_selection=($(whiptail --title "${2^}" --checklist \
        --separate-output \
        "Choose $2" 24 48 16 \
        "${file_args[@]}" 3>&1 1>&2 2>&3))

    local files_selected=($(return_indices files files_selection))
    echo "${files_selected[@]}"
    }

folder_radview() {
    local files=("$1"*)
    local file_args=($(setup_list files))

    local file_selection=($(whiptail --title "${2^}" --radiolist \
        "Choose $2" 24 48 16 \
        "${file_args[@]}" 3>&1 1>&2 2>&3))

    ! [[ -z "$file_selection" ]] && echo "${files["$file_selection"]}"
    }

main_menu() {
    local modcount=$(echo "Number of Loaded Mods:" "${#gameplay_mods[@]}")
    echo $(whiptail --title "GZDoom TUI" --backtitle "$modcount"\
    --menu "Choose option" 16 48 8 \
        "gameplay" "Choose gameplay mods" \
        "level" "Choose level mod" \
        "save" "Save current selection"\
        "load" "Load selection"\
        "delete" "Delete mods list name"\
        "exit" "Exit and run" \
         3>&1 1>&2 2>&3)
}

save_menu() {
    local inputbox=$(echo -e "Gameplay mods:\n\n""${gameplay_mods[@]##*/}\n\n"\
    "Level:" "${level_mod##*/}")
    echo $(whiptail --inputbox "$inputbox" \
        28 39 "" --title "Save mods as name" 3>&1 1>&2 2>&3)
}
save_mods() {
    # inplace library is necessary since piping back to file
    # only manages to add the last printed line
    ./save_mods.awk -i inplace modnames.csv "$1" \
        "${level_mod##*/}" "${gameplay_mods[*]##*/}"
}

setup_csv_list() {
    local modnames=($(awk -F, 'NR!=1 {print $1}' modnames.csv))
    local levelnames=($(awk -F, 'NR!=1 {print $2}' modnames.csv))

    local modlists

    IFS=, read -a modlists <<< \
        $(awk -F, 'BEGIN {ORS=","} NR!=1 {print $3}' modnames.csv)

    local -n modsargs=$1
    modsargs=()
    for index in "${!modnames[@]}"
    do
        local modlist=()
        IFS=" " read -a modlist <<< "${modlists["$index"]}"
        local levelname="${levelnames["$index"]}"
        levelname="${levelname%.*}"
        local shortnames=("${levelname:0:8}")
        for mod in "${modlist[@]}"
        do
            mod="${mod%.*}"
            shortnames+=("${mod:0:8}")
        done
        modsargs+=("${modnames["$index"]}" "${shortnames[*]}" OFF)
    done
}

load_menu() {
    local modsargsout
    setup_csv_list modsargsout
    local toload=($(whiptail --clear --title \
        "Modsets" --radiolist \
        "Choose modset" 24 64 16 \
        "${modsargsout[@]}" \
        3>&1 1>&2 2>&3))

    echo "$toload"
}

load_level() {
    local level_mod=$(awk -F, -v loadname="$1" \
        '$1 == loadname {print $2}' modnames.csv)

    local level_mod="${level_mod/#/"$levelspath"}"
    echo "$level_mod"
}

load_mods() {
    local modlist=($(awk -F, -v loadname="$1" \
        '$1 == loadname {print $3}' modnames.csv))

    local gameplay_mods=()
    for mod in "${modlist[@]}"
    do
        gameplay_mods+=("${mod/#/"$modspath"}")
    done

    echo "${gameplay_mods[@]}"
}

delete_menu() {
    local modsargsout
    setup_csv_list modsargsout
    local todelete=($(whiptail --clear --title \
        "Modsets" --radiolist \
        "Choose modset" 24 64 16 \
        "${modsargsout[@]}" \
        3>&1 1>&2 2>&3))

    echo "$todelete"
}

delete_modname() {
    awk -F, -i inplace -v deletename="$1" \
        '$1 != deletename {print $0}' modnames.csv
}

menu="main"
while [[ -n "$menu" ]]
do
    case "$menu" in
        "main")
            menu=$(main_menu);;
        "gameplay")
            gameplay_mods=($(folder_checkview "$modspath" "gameplay mods"))
            menu="main";;
        "level")
            level_mod=$(folder_radview "$levelspath" "level mod")
            menu="main";;
        "save")
            savename=$(save_menu)
            if [[ -n "$savename" ]]; then
                save_mods "$savename"
            fi
            menu="main";;
        "load")
            loadname=$(load_menu)
            if [[ -n "$loadname" ]]; then
                level_name=$(load_level "$loadname")
                gameplay_mods=($(load_mods "$loadname"))
            fi
            menu="main";;
        "delete")
            deletename=$(delete_menu)
            if [[ -n "$deletename" ]]; then
                delete_modname "$deletename"
            fi
            menu="main";;
        "exit")
            menu=""
            gzdoom -file "$level_mod" "${gameplay_mods[@]}"
            ;;

    esac
done

# gameplay_mods=($(folder_checkview ~/.config/gzdoom/Gameplay/))
# 
# level_mod=($(folder_radview ~/.config/gzdoom/Levels/))
# 
# gzdoom -file "${gameplay_mods[@]}" "$level_mod"
