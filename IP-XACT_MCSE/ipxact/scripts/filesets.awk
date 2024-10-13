
# ---------- Usage ---------------------------------------------------------------------------------
# Running the script in bash terminal:
# $ awk -f <script>.awk <manifest_file>
#
# Tested with GNU Awk 4.0.2
# 
# Parameters:
#   <script>                    This script file
#   <manifest_file>             Manifest files for the items to be created in the output ipxact file
#                               This needs to be a file with only the file names with path.
# Note:
#   Remember to remove any testbench files from the compile manifest, if generating release files 
#
# --------------------------------------------------------------------------------------------------



BEGIN {
    printf( "\
  <ipxact:fileSets>\n\
    <ipxact:fileSet>\n\
      <ipxact:name>Hdl</ipxact:name>\n" )
}

{
    # Remove comment lines and empty lines
    if ( match( $1, /^\/\// ) ) next
    if ( match( $1, /^$/ ) ) next

# print "------------------------------------------------------------------------"
# printf( "FNR        : %s\n", FNR )
# printf( "NR         : %s\n", NR )
# printf( "NF         : %s\n", NF )
# printf( "Eka        : %s\n", $1 )
# printf( "Toka       : %s\n", $2 )
# print "------------------------------------------------------------------------"

    printf( "\
        <ipxact:file>\n\
          <ipxact:name>%s</ipxact:name>\n\
          <ipxact:fileType>verilogSource</ipxact:fileType>\n\
        </ipxact:file>\n"\
        , $1 )
}

END {
    printf( "\
    </ipxact:fileSet>\n\
  </ipxact:fileSets>\n" )
}

