# Loop through rep_000 to rep_009
for {set i 0} {$i <= 9} {incr i} {
    # Format the folder name
    set rep [format "rep_%03d" $i]
    set dcd_folder "/Users/tana/MAO_A_2025/CHG/2_FEP_GP/$rep"
    set output_file "$dcd_folder/all.dcd"
    set structure "/Users/tana/MAO_A_2025/CHG/2_FEP_GP/chg_gas_start.pdb"

    puts "Processing $rep..."

    # Get sorted list of all fep_*.dcd files
    set dcd_files [lsort [glob -nocomplain -directory $dcd_folder "fep_*.dcd"]]

    if {[llength $dcd_files] == 0} {
        puts "No DCD files found in $dcd_folder. Skipping."
        continue
    }

    # Load topology
    mol new $structure type pdb waitfor all

    # Load all DCD files into the same molecule
    foreach dcd $dcd_files {
        mol addfile $dcd waitfor all
        puts "  Loaded $dcd"
    }

    # Write concatenated DCD into the same replica folder
    animate write dcd $output_file

    puts "✅ Saved $output_file"

    # Delete molecule before next iteration
    mol delete all
}



