#!/bin/bash



# --------------------------------------------------------------------------------------------------
# Function: Print usage
# --------------------------------------------------------------------------------------------------
function print_usage {

    echo ""
    echo "Automated Integration of Secure Silicon (AISS) Security Engine"
    echo "---------------------------------------------------------------------------------------------"
    echo "Create a dictionary of compiler pre-processor \`define directives."
    echo ""
    echo ""
    echo "Assumptions:"
    echo "  + Design name is set in a config file"
    echo "    ./config/design_name"
    echo ""
    echo "Command line arguments:"
    echo ""
#    echo "  1: [compile_manifest]           - Design compile manifest."
#    echo "                                    If none given, the default will be used."
#    echo "                                    Default: ../compile_manifest"
    echo "  1: [include_manifest]           - Design include files manifest."
    echo "                                    The files that have the \`define directievs."
    echo "                                    Default: artifacts/<design_name>_include_manifest"
    echo ""
    echo "Usage: $0 [include_manifest]"
    echo ""
    echo "Example:"
    echo "    $ ./scripts/$0 ../include_manifest"
    echo ""
    echo "Output:"
    echo "  + tmp_defines_dictionary        - Dictionaly file containing name value pairs"
    echo "                                    generated from \`define directives in source files"
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











# Find all `include directives in source files listed in compile manifest
#while IFS= read -r MANIFEST_ENTRY; do
#
#    grep -e 'include' $DIR_ROOT/$MANIFEST_ENTRY
#
#    
#
#done < $FILE_COMPILE_MANIFEST






# Add all defines from files listed in include file manifest to the dictionary
mapfile < $FILE_INCLUDE_MANIFEST

for F in ${MAPFILE[@]}; do
#    echo $F
    awk -f $FILE_DEFINES_AWK $F >> $FILE_DEFINES_DICTIONARY
done
