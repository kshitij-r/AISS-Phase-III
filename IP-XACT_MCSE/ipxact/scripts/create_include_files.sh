#!/bin/bash



# --------------------------------------------------------------------------------------------------
# Function: Print usage
# --------------------------------------------------------------------------------------------------
function print_usage {

    echo ""
    echo "Automated Integration of Secure Silicon (AISS) Security Engine"
    echo "---------------------------------------------------------------------------------------------"
    echo "Create a list of include file names by scraping the from the source file \`include directives."
    echo ""
    echo ""
    echo "Assumptions:"
    echo "  + Design name is set in a config file"
    echo "    ./config/design_name"
    echo ""
    echo "Command line arguments:"
    echo ""
    echo "  1: [compile_manifest]           - Design compile manifest."
    echo "                                    If none given, the default will be used."
    echo "                                    Default: ../compile_manifest"
    echo ""
    echo "Usage: $0 [compile_manifest]"
    echo ""
    echo "Example:"
    echo "    $ ./scripts/$0 ../compile_manifest"
    echo ""
    echo "Output:"
    echo "  + tmp_include_files             - List of file names (one per line) that appear in the"
    echo "                                    \`include directives in the source files listed in the"
    echo "                                    compile manifest."
    echo ""
    echo ""
}



# --------------------------------------------------------------------------------------------------
# Function: Print usage
# --------------------------------------------------------------------------------------------------
function print_usage {
    echo ""
    echo "Usage: $0"
    echo ""
    echo ""
}



# --------------------------------------------------------------------------------------------------
# Check command line arguments
# --------------------------------------------------------------------------------------------------
# Check if command line argument is missing
# if [ -z $1 ]; then
#     print_usage
#     exit
# fi

# Check that first command line argument is a file name (with path)
# if [[ ! -f $1 ]]; then
#     print_usage
#     exit
# fi



# --------------------------------------------------------------------------------------------------
# System variables
# --------------------------------------------------------------------------------------------------
COLOR_BLACK='\033[0;30m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_WHITE='\033[0;37m'
COLOR_RESET='\033[0m'



# --------------------------------------------------------------------------------------------------
# Setup variables
# --------------------------------------------------------------------------------------------------
DIR_ROOT=..
DIR_CURRENT=`pwd`
TIMESTAMP=`date +"%F_%H%M%S"`

DIR_ARTIFACTS=artifacts
DIR_SCRIPTS=scripts
DIR_CONFIG=config

mapfile -n 1 -t DESIGN_NAME < $DIR_ROOT/$DIR_CONFIG/design_name

FILE_INCDIRS=$DIR_ROOT/$DIR_CONFIG/incdirs
FILE_COMPILE_MANIFEST=$DIR_ROOT/compile_manifest
FILE_DEFINES_DICTIONARY=tmp_defines_dictionary
FILE_INCLUDE_DIRECTIVES=tmp_include_directives
FILE_INCLUDE_MANIFEST=${DIR_ARTIFACTS}/${DESIGN_NAME}_include_manifest
FILE_DEFINES_AWK=$DIR_SCRIPTS/defines.awk






# ----- Functions ----------------------------------------------------------------------------------






# Truncate the output file
> $FILE_INCLUDE_DIRECTIVES

# Map the compile manifest entries (lines) into an array MAPFILE
mapfile -t < $FILE_COMPILE_MANIFEST

# Go through all files listed in the compile manifest
for I in ${MAPFILE[@]}; do
#    echo "----- $I"
    grep -rsh -e '^`include' $DIR_ROOT/$I | awk '!a[$0]++ { gsub(/\"/, ""); print $2 }' >> $FILE_INCLUDE_DIRECTIVES

done

# Remove duplicate entries
awk '!a[$0]++' $FILE_INCLUDE_DIRECTIVES
