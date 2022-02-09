#!/usr/bin/awk -f 

BEGIN {
    modname = ARGV[2]
    level = ARGV[3]
    mods = ARGV[4]
    ARGV[2] = NULL
    ARGV[3] = NULL
    ARGV[4] = NULL

    FS=","
    OFS=","

    namepresent=0
    if($1 == modname) namepresent=1
}

{allrows[$1] = $2 OFS $3}

END {
    if(!namepresent) {
        allrows[modname] = level OFS mods
    }
    PROCINFO["sorted_in"] = "@ind_str_asc"
    print "modname" OFS "level" OFS "mods"
    for (row in allrows) print row, allrows[row]
}
