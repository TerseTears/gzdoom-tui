#!/usr/bin/env bash

if [[ "$BASH_VERSINFO" -lt 4 ]]; then
    echo "at least bash 4.x is required"
    exit 1
fi

if ! [[ -x "$(command -v gawk)" ]]; then
    echo "gawk (gnu awk) is required."
    exit 1
fi

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

if [[ -n "$XDG_DATA_HOME" ]]; then
    modnames_csv="$XDG_DATA_HOME/gzdoom-tui/modnames.csv"
else
    modnames_csv="$HOME/.local/share/gzdoom-tui/modnames.csv"
fi

# TODO use own program directory
if ! [[ -e "$modnames_csv" ]]; then
    mkdir -p "${modnames_csv%/*}" && touch "$modnames_csv"
fi


modspath=~/.config/gzdoom/Gameplay/
levelspath=~/.config/gzdoom/Levels/

return_indices() {
    local -n return_array="$1"
    local -n selection_array="$2"
    local -n indices="$3"

    return_array=()
    for index in "${indices[@]}"
    do
        return_array+=("${selection_array["$index"]}")
    done
}

setup_list() {
    local -n ret_file_args="$1"
    local -n _files="$2"

    local _file_names=("${_files[@]##*/}")
    local _file_names=("${_file_names[@]%.*}")

    ret_file_args=()
    for index in "${!_files[@]}"
    do
        ret_file_args+=("$index" "${_file_names["$index"]}" "OFF" )
    done
}

folder_checkview() {
    local -n ret_files_selected="$1"
    local files=("$2"*)

    local file_args
    setup_list file_args files

    # separate-output is absolutely essential otherwise whiptail adds quotes
    # around
    local files_selection
    mapfile -t files_selection < \
        <(whiptail --title "${3^}" --checklist --separate-output \
        "Choose $3" 24 48 16 "${file_args[@]}" 3>&1 1>&2 2>&3)

    return_indices ret_files_selected files files_selection
}

folder_radview() {
    local files=("$1"*)
    local file_args
    setup_list file_args files

    local file_selection
    file_selection=$(whiptail --title "${2^}" --radiolist \
        "Choose $2" 24 48 16 "${file_args[@]}" 3>&1 1>&2 2>&3)

    [[ -n "$file_selection" ]] && echo "${files["$file_selection"]}"
}

main_menu() {
    local modcount
    modcount="Number of Loaded Mods: ${#gameplay_mods[@]}"

    local menu
    menu="$(whiptail --title "GZDoom TUI" --backtitle "$modcount"\
        --menu "Choose option" 16 48 8 \
        "gameplay" "Choose gameplay mods" \
        "level" "Choose level mod" \
        "save" "Save current selection"\
        "load" "Load selection"\
        "delete" "Delete mods list name"\
        "exit" "Exit and run" \
        3>&1 1>&2 2>&3)"

    echo "$menu"
}

save_menu() {
    local inputbox
    inputbox=$(echo -e "Gameplay mods:\n\n""${gameplay_mods[*]##*/}\n\n"\
    "Level:" "${level_mod##*/}")

    local savename
    savename=$(whiptail --inputbox "$inputbox" \
        24 40 "" --title "Save mods as name" 3>&1 1>&2 2>&3)

    echo "$savename"
}
save_mods() {
    awk -i inplace -v modname="$1" -v level="${level_mod##*/}" \
        -v mods="${gameplay_mods[*]##*/}" \
        'BEGIN {
            FS=","
            OFS=","
            namepresent=0
            if($1 == modname) namepresent=1
        }

        NR!=1 {allrows[$1] = $2 OFS $3}

        ENDFILE {
            if(!namepresent) {
                allrows[modname] = level OFS mods
            }
            PROCINFO["sorted_in"] = "@ind_str_asc"
            print "modname" OFS "level" OFS "mods"
            for (row in allrows) print row, allrows[row]
            }' "$modnames_csv"
}

setup_csv_list() {
    local -n ret_modsargs=$1

    local modnames
    mapfile -t modnames < <(awk -F, 'NR!=1 {print $1}' "$modnames_csv")
    local levelnames
    mapfile -t levelnames < <(awk -F, 'NR!=1 {print $2}' "$modnames_csv")

    local modlists
    IFS=, read -r -a modlists <<< \
        "$(awk -F, 'BEGIN {ORS=","} NR!=1 {print $3}' "$modnames_csv")"

    ret_modsargs=()
    for index in "${!modnames[@]}"
    do
        local modlist=()
        IFS=" " read -r -a modlist <<< "${modlists["$index"]}"
        local levelname="${levelnames["$index"]}"
        levelname="${levelname%.*}"
        local shortnames=("${levelname:0:8}")
        for mod in "${modlist[@]}"
        do
            mod="${mod%.*}"
            shortnames+=("${mod:0:8}")
        done
        ret_modsargs+=("${modnames["$index"]}" "${shortnames[*]}" OFF)
    done
}

load_menu() {
    local modsargs
    setup_csv_list modsargs

    local toload
    toload="$(whiptail --clear --title "Load modsets" --radiolist \
        "Choose modset" 24 64 16 "${modsargs[@]}" 3>&1 1>&2 2>&3)"

    echo "$toload"
}

load_level() {
    local level_mod
    level_mod="$(awk -F, -v loadname="$1" \
        '$1 == loadname {print $2}' "$modnames_csv")"
    level_mod="${level_mod/#/"$levelspath"}"

    echo "$level_mod"
}

load_mods() {
    local -n ret_gameplay_mods="$1"
    local modlist
    IFS=" " read -r -a modlist <<< "$(awk -F, -v loadname="$2" \
        '$1 == loadname {print $3}' "$modnames_csv")"

    ret_gameplay_mods=()
    for mod in "${modlist[@]}"
    do
        ret_gameplay_mods+=("${mod/#/"$modspath"}")
    done
}

delete_menu() {
    local modsargsout
    setup_csv_list modsargsout

    local todelete
    todelete="$(whiptail --clear --title "Delete modset name" --radiolist \
        "Choose modset" 24 64 16 "${modsargsout[@]}" 3>&1 1>&2 2>&3)"

    echo "$todelete"
}

delete_modname() {
    # inplace library is necessary since piping back to file
    # only manages to add the last printed line
    awk -F, -i inplace -v deletename="$1" \
        '$1 != deletename {print $0}' "$modnames_csv"
}

menu="main"
while [[ -n "$menu" ]]
do
    case "$menu" in
        "main")
            menu=$(main_menu);;
        "gameplay")
            folder_checkview gameplay_mods "$modspath" "gameplay mods"
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
                level_mod=$(load_level "$loadname")
                load_mods gameplay_mods "$loadname"
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
