package require PWI_Glyph

pw::Application reset
pw::Application clearModified
set scriptDir [file dirname [info script]]


# -------------------------------------
# User Defined Parameters
# -------------------------------------
# Files to load
set projectFile "grid.pw"; # Project file
pw::Application load [file join $scriptDir $projectFile]
pw::Display update

# Entities
set domList [list "dom-1"]; # Domain to optimize

# Solver settings
set boundaryControl "HilgenstockWhite"; # "StegerSorenson" "HilgenstockWhite" "None"
set interiorControl "ThomasMiddlecoff"; # "ThomasMiddlecoff" "Laplace" "Fixed"
set iterationList   [list 10 50 100 500 1000]



# Get max included angle for a domain
proc GetMaxAngle {dom} {

    set examine [pw::Examine create DomainMaximumAngle]

        $examine addEntity $dom
        $examine examine 

    return [$examine getMaximum] 

}



# Run elliptic solver
proc RunSolver {dom iter} {

    set solverMode [pw::Application begin EllipticSolver $dom]

        $solverMode run $iter

    $solverMode end

    return $dom

}



# Set solver attributes and run elliptic solver
proc FuncEval {dom params {reInit 1}} {

    set iter [lindex $params 0]

    if {[llength $params]>1} {

        set bnd  [lindex $params 1]
        set int  [lindex $params 2] 

        $dom setEllipticSolverAttribute EdgeControl $bnd
        $dom setEllipticSolverAttribute InteriorControl $int
    
    }

    set maxAngle [GetMaxAngle [RunSolver $dom $iter]]

    if {$reInit} {
        $dom initialize
    }
    
    return $maxAngle

}



# Main
set domNum 0
foreach ent $domList {

	set tBegin [pwu::Time now]
	
    set dom [pw::Entity getByName $ent]

	set origF [GetMaxAngle $dom]

    puts ""
	puts "----------------------------------------------"
	puts "Results for Domain [$dom getName]"
	puts "----------------------------------------------"
    puts ""
    puts "Boundary control:      $boundaryControl"
    puts "Interior control:      $interiorControl"
    puts "Iterations to run:     $iterationList"
    puts ""
	puts "----------------------------------------------"

    foreach iteration $iterationList {

	    set newF [FuncEval $dom [list $iteration $boundaryControl $interiorControl]]

	    puts "Solver iterations:     $iteration"
	    puts ""
	    puts [format "Original max included angle:  %.2f deg" $origF]
	    puts [format "New max included angle:       %.2f deg" $newF]
	    puts [format "Max angle improvement:        %.2f%%" [expr {abs($newF-$origF)/$origF*100.0}]]
	    puts ""
	    puts [format "Total run time: %.2f sec" [pwu::Time elapsed $tBegin]] 
	    puts ""
	    puts "----------------------------------------------"

    }

incr domNum

}

# End
