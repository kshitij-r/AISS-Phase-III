
# ---------- Usage ---------------------------------------------------------------------------------
# Running the script in bash terminal:
# $ awk -f <script>.awk <dictionary_file> <manifest_file>
# 
# Parameters:
#   <script>                    This script file
#   <dictionary_file>           Dictionary for string replacement. For example, this could be the 
#                               header file that has macro definitions. 
#   <manifest_file>             Manifest files for the items to be created in the output ipxact file
#                               This needs to be a file with only a cleaned verilog top level file. 
#                               "Cleaned" meaning that it should contain only the module definition
#                               without anything else (i.e. only the boundary signal definitions).
# --------------------------------------------------------------------------------------------------



# FNR equals NR only in the first file. That is, since the number of records 
# read in a file (FNR) is reset to zero when moving into the next file, in the
# second file, the total number of records read (NR) is different than FNR.
FNR==NR {
    # Read key value pairs for constant/macro string replacement

    # Remove comment lines and empty lines
    if ( match( $1, /^\/\// ) ) next
    if ( match( $1, /^$/ ) ) next

    # Add key/value pair to dictionary
    if (NF==2) {
        i_defines[$1] = $2
#        printf( "Added to dictionary: %s : %d\n", $1, $2 )
    }
    else {
        next
    }
}



# Second file is the one used to create the IP-XACT description
FNR!=NR {
#    printf( "----- FNR:%s\n----- NR:%s\n", FNR, NR )

    # Skip comment lines
    if ( match( $1, /^\/\// ) ) next

    # Skip empty lines
    else if ( match( $1, /^$/ ) ) next

    # Skip macro conditional begin
    else if ( match( $1, /ifdef/ ) ) next

    # Skip macro conditional end
    else if ( match( $1, /endif/ ) ) next

    # ----- Match module begin / end -------------------------------------------

    # Match module begin
    else if ( match( $1, /^module/ ) ) {
#        printf( "----- ----- ----- Module begin found: ----- %s\n", $1 )
        next
    }

    # Match module end
    else if ( match( $1, /^\);/ ) ) {
#        printf( "----- ----- ----- Module end found:   ----- %s\n", $1 )
        exit
    }

    # ----- Match port definition ----------------------------------------------

    else if ( $1 ~ /(input|output)/ ) {

        # printf( "\nPort found (NF == %u) : %s\n", NF, $0 )

        i_direction = ""
        i_port_name = ""
        i_array     = ""
        i_left      = ""
        i_right     = ""

        # The first field should be the port direction
        if      ( $1 == "input"         ) i_direction   = "in"
        else if ( $1 == "output"        ) i_direction   = "out"
        else                              i_direction   = "unknown"

        # Second field is either port type, array left hand side or port name
        if      ( $2 == "wire"          ) ;                                     # Do nothing
        else if ( $2 == "reg"           ) ;                                     # Do nothing
        else if ( $2 ~ /^[[:alpha:]]/   ) i_port_name   = $2                    # Port name
        else if ( $2 ~ /^\[.*\]$/       ) i_array       = $2                    # Array dimensions
        else if ( $2 ~ /^\[/            ) i_left        = $2                    # Array LHS
        else                              ;                                     # Do nothing

        # Third filed is either array left hand side, array right hand side, both array dimensions or port name
        if      ( $3 ~ /^[[:alpha:]]/   ) i_port_name   = $3                    # Port name
        else if ( $3 ~ /^\[.*\]$/       ) i_array       = $3                    # Array dimensions
        else if ( $3 ~ /^\[/            ) i_left        = $3                    # Array LHS
        else if ( $3 ~ /\]$/            ) i_right       = $3                    # Array RHS
        else                              ;                                     # Do nothing

        # Fourth filed is either array right hand side or port name
        if      ( $4 ~ /^[[:alpha:]]/   ) i_port_name   = $4                    # Port name
        else if ( $4 ~ /]$/             ) i_right       = $4                    # Array RHS
        else                              ;                                     # Do nothing

        # Fifth field is most likely the port name
        if      ( $5 ~ /^[[:alpha:]]/   ) i_port_name   = $5                    # Port name
        else                              ;                                     # Do nothing

#        printf( "<!-- ----------------------------------------------------------- -->\n" )
#        printf( "<!-- FNR        : %s -->\n", FNR )
#        printf( "<!-- NR         : %s -->\n", NR )
#        printf( "<!-- NF         : %s -->\n", NF )
#        printf( "<!-- ----------------------------------------------------------- -->\n" )
#        printf( "<!-- Zero  >>>>>%s<<<<< -->\n", $0 )
#        printf( "<!-- ----------------------------------------------------------- -->\n" )
#        if ( NF > 0 ) printf( "<!-- First      : %s -->\n", $1 )
#        if ( NF > 1 ) printf( "<!-- Second     : %s -->\n", $2 )
#        if ( NF > 2 ) printf( "<!-- Third      : %s -->\n", $3 )
#        printf( "<!-- ----------------------------------------------------------- -->\n" )
#        printf( "<!-- i_direction: %s -->\n", i_direction      )
#        printf( "<!-- i_port_name: %s -->\n", i_port_name      )
#        printf( "<!-- i_array    : %s -->\n", i_array          )
#        printf( "<!-- i_left     : %s -->\n", i_left           )
#        printf( "<!-- i_right    : %s -->\n", i_right          )
#        printf( "<!-- ----------------------------------------------------------- -->\n" )

        # ----- Clean up variables ---------------------------------------------

        # Remove (trailing) comma from the port name
        gsub( /,/, "", i_port_name      )

        # If i_array variable is set, split array dimensions to LHS and RHS
        if ( i_array != "" ) {
            split( i_array, i_vector, ":" )
            i_left  = i_vector[1]
            i_right = i_vector[2]

#            printf( "<!-- i_array    : %s -->\n", i_array          )
#            printf( "<!-- i_left     : %s -->\n", i_left           )
#            printf( "<!-- i_right    : %s -->\n", i_right          )
#            printf( "<!-- ----------------------------------------------------------- -->\n" )
        }
        # Else, assume array dimensions are already split to i_left and i_right
        else {
        }

        if ( i_array != "" || i_left != "" || i_right != "" ) {
            # Remove brackets and potential backtick and colon from array dimensions
            gsub( /\[|\]/, "", i_left     )
            gsub( /\[|\]/, "", i_right    )
            gsub( /\:/, "", i_left     )
            gsub( /\:/, "", i_right    )
            gsub( /^\W/, "", i_left     )
            gsub( /^\W/, "", i_right    )
    
#            printf( "<!-- i_left     : %s -->\n", i_left           )
#            printf( "<!-- i_right    : %s -->\n", i_right          )
#            printf( "<!-- ----------------------------------------------------------- -->\n" )
    
            # Macro replacement for the array dimensions
            if ( i_left ~ /^[[:alpha:]]/ ) {
    
                # Assume there's a -1 subtraction to the macro
                split( i_left, i_macro, "-" )
    
#                printf( "<!-- i_left     : %s -->\n", i_left           )
#                printf( "<!-- i_right    : %s -->\n", i_right          )
#                printf( "<!-- i_macro[1] : %s -->\n", i_macro[1]       )
#                printf( "<!-- i_macro[2] : %s -->\n", i_macro[2]       )
#                printf( "<!-- ----------------------------------------------------------- -->\n" )
    
                if ( i_macro[1] in i_defines ) {
                    i_left = i_defines[i_macro[1]] - i_macro[2]
    
#                    printf( "<!-- i_macro[1]            : %s -->\n", i_macro[1]                 )
#                    printf( "<!-- i_defines[ i_macro[1] : %s -->\n", i_defines[ i_macro[1] ]    )
#                    printf( "<!-- ----------------------------------------------------------- -->\n" )
                }
                else {
                    i_left = i_macro[1]
                }
            }
            # Else, the array dimensions are already numerical
            else {
            }

        # ----- Print IP-XACT port description -----------------------------

            printf( "<!-- %s [%s : %s] -->\n", i_port_name, i_left, i_right )

            printf("\
            <ipxact:port>\n\
              <ipxact:name>%s</ipxact:name>\n\
              <ipxact:wire>\n\
                <ipxact:direction>%s</ipxact:direction>\n\
                <ipxact:vectors>\n\
                  <ipxact:vector>\n\
                    <ipxact:left>%s</ipxact:left>\n\
                    <ipxact:right>%s</ipxact:right>\n\
                  </ipxact:vector>\n\
                </ipxact:vectors>\n\
              </ipxact:wire>\n\
            </ipxact:port>\n\n"\
            , i_port_name, i_direction, i_left, i_right )
        }

        # Else, assume the port is a single wire
        else {

            printf( "<!-- %s -->\n", i_port_name )

            printf("\
            <ipxact:port>\n\
              <ipxact:name>%s</ipxact:name>\n\
              <ipxact:wire>\n\
                <ipxact:direction>%s</ipxact:direction>\n\
              </ipxact:wire>\n\
            </ipxact:port>\n\n"\
            , i_port_name, i_direction )
        }
    }

    # Else, print everything
    else {
#        printf( "\n>>>>>>>>>> %s <<<<<<<<<<\n\n", $0 )
    }
}



#END {
#    print "------------------------------------------------------------------------"
#    for ( u in i_unknown ) {
#        printf( "%s : %s\n", u, i_unknown[u] )
#    }
#    print "------------------------------------------------------------------------"
#}
