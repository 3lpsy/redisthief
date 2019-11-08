# RedisThief

## Purpose

This is a simple script for watching redis services and downloading data.

## About

The code is **extremely** simple. It just continuously checks redis services for keys and downloads the associated values.

```
usage: redisthief.sh [arguments]

required arguments:
    -t     the redis target(s) in host:port:password format. port and password are optional. can be in csv format but cannot have any spaces

optional arguments:
    -r     the name of the redis client executable (default: redis-cli)
    -o     the path to the output directory (default: current directory)
    -d     the delay length in seconds between each attempt to grab keys (default: 10)

optional flags:
    -s     output all the key/value data to stdout also
    -S     output all the key/value data to stdout only
    -N     disables double downloading of a key's value. It set, data will be saved under DATA_DIR/KEY_NAME/value.txt instead of DATA_DIR/KEY_NAME/YYYY-MM-DD_hh-mm-ss.value.txt
    -D     enable debug messsages
    -q     enable quiet mode
    -h     show this message

examples:
    $ redisthief.sh -r 10.0.0.1:6379 -o /path/to/datadirectory
    $ redisthief.sh -r 10.0.0.1:6379,somerediserver.dev,192.168.1.1:6666:SomePass -D

```
