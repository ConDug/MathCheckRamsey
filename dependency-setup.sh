#!/bin/bash

# Function to display help information
function display_help() {
    echo "
    Description:
        This script will install and compile the required dependencies and packages: CaDiCaL, NetworkX, DRAT-trim, march_cu, and AlphaMapleSAT

    Usage:
        ./dependency-setup.sh [-n]
        Use -n to only install CaDiCaL and DRAT-trim, not the tools needed for cube and conquer
    "
    exit
}

# Check if help is requested
[ "$1" = "-h" -o "$1" = "--help" ] && display_help

while getopts "n" opt
do
    case $opt in
        n) n="-n" ;;
    esac
done
shift $((OPTIND-1))

echo "Prerequisite: pip and make installed"

if [ -z $n ]
then
    required_version="2.5"
    installed_version=$(pip3 show networkx | grep Version | awk '{print $2}')

    # Check if networkx needs to be updated
    if [[ "$(printf '%s\n' "$installed_version" "$required_version" | sort -V | head -n1)" != "$required_version" ]]; then
        echo "Need to install networkx version newer than $required_version"
        pip3 install --upgrade networkx
        echo "Networkx has been successfully updated."
    else
        echo "Networkx version $installed_version is already installed and newer than $required_version"
    fi

    #if pip3 list | grep z3-solver
    #then
    #    echo "z3-solver package installed"
    #else
    #    pip3 install z3-solver
    #fi

    # Check if march_cu is present
    if [ -f gen_cubes/march_cu/march_cu ]
    then
        echo "March installed and binary file compiled"
    else
        cd gen_cubes/march_cu
        make
        cd -
    fi
fi

# Check if drat-trim is present
if [ -f drat-trim/drat-trim ]
then
    echo "Drat-trim installed and binary file compiled"
else
    cd drat-trim
    make
    cd -
fi

# Check if cadical-ks is present
if [ -f cadical-ks/build/cadical-ks ]
then
    echo "Cadical-ks installed and binary file compiled"
else
    cd cadical-ks
    ./configure
    make
    cd -
fi

if [ -z $n ]
then
    # Update git submodules
    cd alpha-zero-general
    git submodule init
    git submodule update
    cd ..
fi

echo "All dependencies properly installed"
