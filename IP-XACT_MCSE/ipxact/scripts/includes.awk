
# ---------- Usage ---------------------------------------------------------------------------------
# Running the script in bash terminal:
# $ awk -f <script>.awk <compile_manifest>
# 
# Parameters:
#   <script>                    This script file
#   <compile_manifest>          Source file manifest (one file path/name per line).
#                               The files will be searched to get all `include directives.
# 
# Output:
#                               List of `include directives in the files (duplicates included)
# --------------------------------------------------------------------------------------------------






# --------------------------------------------------------------------------------------------------
BEGIN {
}

# --------------------------------------------------------------------------------------------------
{
    # Skip comment lines
    if ( match( $1, /^\/\// ) ) next

    # Skip empty lines
    else if ( match( $1, /^$/ ) ) next

    # Match include
    else if ( match( $1, /include/ ) ) {
       printf( "Include found: %s\n", $0 )
       print "-----------------------------------------------------------"
       printf( "FNR        : %s\n", FNR )
       printf( "NR         : %s\n", NR )
       printf( "NF         : %s\n", NF )
       if ( NF > 0 ) printf( "         1 : %s\n", $1 )
       if ( NF > 1 ) printf( "         2 : %s\n", $2 )
       if ( NF > 2 ) printf( "         3 : %s\n", $3 )
       if ( NF > 3 ) printf( "         4 : %s\n", $4 )
       if ( NF > 4 ) printf( "         5 : %s\n", $5 )
       if ( NF > 5 ) printf( "         6 : %s\n", $6 )
       if ( NF > 6 ) printf( "         7 : %s\n", $7 )
       if ( NF > 7 ) printf( "         8 : %s\n", $8 )
       print "-----------------------------------------------------------"
       print ""

        if ( NF == 2 ) {
            # Assume this format: 1:"`include", 2:file_name_in_quotes

            # Output the file name without quotes
            split( $3, i_output, "\"" )
            printf( "i_output: %s\n", i_output )
        }
        else {
            # Skip
            printf( " <skip> %s\n", $0 )
        }

    }
    else {
#        print "-----------------------------------------------------------"
#        printf( "Skipping... %s\n", $0 )
#        print "-----------------------------------------------------------"
#        print ""
    }
}


# --------------------------------------------------------------------------------------------------
END {
}
