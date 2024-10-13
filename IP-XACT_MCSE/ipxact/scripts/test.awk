
# ---------- Usage ---------------------------------------------------------------------------------
# Running the script in bash terminal:
# $ awk -f <script>.awk <incdirs_manifest>
# 
# Parameters:
#   <script>                    This script file
#   <manifest_file>             Manifest files listing the include directories
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

    # Skip macro conditional begin
    else if ( match( $1, /ifdef/ ) ) next

    # Skip macro conditional end
    else if ( match( $1, /endif/ ) ) next

    # Match define
    if ( match( $1, /define/ ) ) {
#        printf( "Define found: %s\n", $0 )
#        print "-----------------------------------------------------------"
#        printf( "FNR        : %s\n", FNR )
#        printf( "NR         : %s\n", NR )
#        printf( "NF         : %s\n", NF )
#        if ( NF > 0 ) printf( "        \$1 : %s\n", $1 )
#        if ( NF > 1 ) printf( "        \$2 : %s\n", $2 )
#        if ( NF > 2 ) printf( "        \$3 : %s\n", $3 )
#        if ( NF > 3 ) printf( "        \$4 : %s\n", $4 )
#        if ( NF > 4 ) printf( "        \$5 : %s\n", $5 )
#        if ( NF > 5 ) printf( "        \$6 : %s\n", $6 )
#        if ( NF > 6 ) printf( "        \$7 : %s\n", $7 )
#        if ( NF > 7 ) printf( "        \$8 : %s\n", $8 )
#        print "-----------------------------------------------------------"
#        print ""

        if ( NF == 3 ) {
            # Assume this format: 1:"`define", 2:name, 3:value

            i_define_name  = $2
            i_define_value = $3

            # Output the define_name define_value
            printf( "%s %s\n", i_define_name, i_define_value )
        }
        else if ( NF > 3 ) {
            # Assume this format: 1:"`define", 2:name, 3:value_word_1, 4:value_word_2, ...

#            printf( "%s\n", $2 )
            i_define_name  = $2
            i_define_value = ""

            # If the value is a string (that may contain spaces)
            if ( $3 ~ /^\"/ ) {

                for ( i = 3; i <= NF; i++ ) {
#                    printf( " |--%s\n", $i )
                    i_define_value = i_define_value " " $i

                    if ( $i ~ /\"$/ ) break;
                }

                for ( i++ ; i <= NF; i++ ) {
#                    printf( " |-- <skip> %s\n", $i )
                }
            }

            # Else (assuming numerical value), only the next field is considered to be the value
            else {
                i_define_value = $3
            }

            # Output the define_name define_value
            if ( i_define_value ~ /^[ ]/ ) i_define_value = substr( i_define_value, 2 )
            printf( "%s %s\n", i_define_name, i_define_value )

#            print "-----------------------------------------------------------"
#            printf( "Define name  : %s\n", i_define_name  )
#            printf( "Define value : %s\n", i_define_value )
#            print "-----------------------------------------------------------"
#            print ""
        }
        else {
            # Skip
#            printf( " <skip> %s\n", $0 )
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
