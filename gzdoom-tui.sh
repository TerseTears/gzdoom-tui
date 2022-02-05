#!/usr/bin/env bash

return_indices() {
    local -n selection_array="$1"
    local -n indices="$2"
    local return_array=()
    for index in "${indices[@]}"
    do
        return_array+=("${selection_array["$ind"]}")
    done
    echo "${return_array[@]}"
}

setup_list() {
    local -n _files="$1"
    local _file_names=("${_files[@]##*/}")
    local _file_names=("${_file_names[@]%.*}")

    local _file_args=()
    for ind in "${!_files[@]}"
    do
        _file_args+=("$ind" "${_file_names["$ind"]}" OFF)
    done
    echo "${_file_args[@]}"
}

folder_checkview() {
    local files=("$1"*)
    local file_args=($(setup_list files))

    # separate-output is absolutely essential otherwise whiptail adds quotes around
    local files_selection=($(whiptail --title "Check list example" --checklist \
        --separate-output \
        "Choose user's permissions" 20 78 20 \
        "${file_args[@]}" 3>&1 1>&2 2>&3))

    local files_selected=($(return_indices files files_selection))
    echo "${files_selected[@]}"
    }

folder_radview() {
    local files=("$1"*)
    local file_args=($(setup_list files))

    local file_selection=($(whiptail --title "Check list example" --radiolist \
        "Choose user's permissions" 20 78 20 \
        "${file_args[@]}" 3>&1 1>&2 2>&3))

    echo "${files["$file_selection"]}"
    }

#folder_checkview ~/.config/gzdoom/Gameplay/

folder_radview ~/.config/gzdoom/Levels/

#gameplay_mods_selected=($(folder_view ~/.config/gzdoom/Gameplay/))


#gzdoom -file "${gameplay_mods_selected[@]}"
