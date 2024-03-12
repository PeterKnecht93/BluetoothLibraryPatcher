#!/usr/bin/env bash
#
# Copyright (C) 2024 PeterKnecht93
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# [
hex=(
    # default
    [134]=6804003528008052                 [1134]=2b00001428008052
    [133]=6804003528008052                 [1133]=2a00001428008052
    [132]=........f9031f2af3031f2a41       [1132]=1f2003d5f9031f2af3031f2a48
    [131]=........f9031f2af3031f2a41       [1131]=1f2003d5f9031f2af3031f2a48
    [130]=........f3031f2af4031f2a3e       [1130]=1f2003d5f3031f2af4031f2a3e
    [129]=........f4031f2af3031f2ae8030032 [1129]=1f2003d5f4031f2af3031f2ae8031f2a
    [128]=88000034e8030032                 [1128]=1f2003d5e8031f2a
    [127]=88000034e8030032                 [1127]=1f2003d5e8031f2a
    [126]=88000034e8030032                 [1126]=1f2003d5e8031f2a
    # arm
    [234]=4e7e4448bb                       [1234]=4e7e4437e0
    [233]=4e7e4440bb                       [1233]=4e7e4432e0
    [231]=20b14ff000084ff000095ae0         [1231]=00bf4ff000084ff0000964e0
    [230]=18b14ff0000b00254a               [1230]=00204ff0000b002554
    [229]=..b100250120                     [1229]=00bf00250020
    [228]=..b101200028                     [1228]=00bf00200028
    [227]=09b1012032e0                     [1227]=00bf002032e0
    [226]=08b1012031e0                     [1226]=00bf002031e0
    [225]=087850bbb548                     [1225]=08785ae1b548
    [224]=007840bb6a48                     [1224]=0078c4e06a48
    # qcom
    [330]=88000054691180522925c81a69000037 [1330]=1f2003d5691180522925c81a1f2003d5
    [329]=88000054691180522925c81a69000037 [1329]=1f2003d5691180522925c81a1f2003d5
    [328]=7f1d0071e91700f9e83c0054         [1328]=7f1d0071e91700f9e7010014
    # Q specific
    [429]=....0034f3031f2af4031f2a....0014 [1429]=1f2003d5f3031f2af4031f2a47000014
    # A137 S specific
    [531]=10b1002500244ce0                 [1531]=00bf0025002456e0
    # T510 R and Q specific
    [530]=18b100244ff0000b4d               [1530]=002000244ff0000b57
    [529]=44387810b1002400254a             [1529]=44387800200024002556
    # T595 Q specific
    [629]=90387810b1002400254a             [1629]=90387800200024002558
)
# ]

if [[ $# -lt 2 ]]; then
    echo -e "Usage: $0 <lib/apex> <api> [arm/qcom] \n"
    exit 1
else
    FILE="$1"
    API="$2"
    var=$(if [[ $3 == arm ]] || [[ $API -le 25 ]]; then echo 2; elif [[ $3 == qcom ]] && [[ $API -ge 28 ]] && [[ $API -le 30 ]]; then echo 3; else echo 1; fi)

    if [[ ! -f $FILE ]]; then
        echo -e "File not found: \"$FILE\" \n"
        exit 1
    else
        [ -d "tmp" ] && rm -rf "tmp"
        [ -d "out" ] && rm -rf "out"
        mkdir -p "out"

        if [[ $FILE == *.apex ]]; then
            mkdir -p "tmp/mnt" "out/stock"
            
            echo "- Extracting APEX..."
            unzip -qj "$FILE" "apex_payload.img" -d "tmp"

            sudo mount -o ro "tmp/apex_payload.img" "tmp/mnt"
            sudo cat "tmp/mnt/lib64/libbluetooth_jni.so" > "out/stock/libbluetooth_jni.so"

            sudo umount "tmp/mnt"
            rm -rf "tmp"

            FILE="out/stock/libbluetooth_jni.so"
            echo ""
        fi

        echo "- Patching Library..."
        if [[ $3 == qcom ]] && ! xxd -p "$FILE" | tr -d \\n | tr -d " " | grep -q "${hex[$var$API]}"; then
            if xxd -p "$FILE" | tr -d \\n | tr -d " " | grep -q "${hex[1$var$API]}"; then
                echo -e " Hex patch already applied! \n"
                exit 0
            else
                var=1
            fi
        fi

        if ! xxd -p "$FILE" | tr -d \\n | tr -d " " | grep -q "${hex[$var$API]}"; then
            if xxd -p "$FILE" | tr -d \\n | tr -d " " | grep -q "${hex[1$var$API]}"; then
                echo -e " Hex patch already applied! \n"
                exit 0
            elif [[ $var == 1 ]] && [[ $API == 29 ]] && xxd -p "$FILE" | tr -d \\n | tr -d " " | grep -q "${hex[4$API]}"; then
                var=4
            elif [[ $var == 2 ]]; then
                if [[ $API -ge 29 ]] && [[ $API -le 31 ]]; then
                    if xxd -p "$FILE" | tr -d \\n | tr -d " " | grep -q "${hex[5$API]}"; then
                        var=5
                    elif xxd -p "$FILE" | tr -d \\n | tr -d " " | grep -q "${hex[6$API]}"; then
                        var=6
                    fi
                elif [[ $API == 27 ]] && xxd -p "$FILE" | tr -d \\n | tr -d " " | grep -q "${hex[$var26]}"; then
                    API=26
                fi
            else
                echo -e " No ${hex[$var$API]} match in library! \n"
                exit 1
            fi
        fi

        xxd -p "$FILE" | tr -d \\n | tr -d " " | sed "s/${hex[$var$API]}/${hex[1$var$API]}/" | xxd -r -p > "out/$(basename "$FILE")"
    fi
fi

echo ""