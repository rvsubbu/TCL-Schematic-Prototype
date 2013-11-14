#!/usr/local/bin/wish

# (c)2013 R.V. Subramanyan All rights reserved.
# Developer: RV (rv@gmail.com)
# netlist functions

namespace eval nl {
	set instId 0
	set insts [dict create]

	set rgnId 0
	set rgns [dict create]

	set netId 0
	set nets [dict create]

	set chipWidth -1
	set chipHeight -1

	proc makeInst {name args} {
		# syntax: nlInst name <-type type> <-numInputs numInputs> <-numOutputs numOutputs> <-parent parentInst> <-x x> <-y y> <-width width> <-height height> <-region region>
		set id $nl::instId
		incr nl::instId
	
		set legalOpts {-type -numInputs -numOutputs -parent -x -y -width -height -region}
	
		set props [dict create id $id type macro numInputs 2 numOutputs 1 parent false x 5 y 5 width 100 height 100 region ""]
	
		set index -1
		foreach {opt val} $args {
			if {-1 == [lsearch $legalOpts $opt]} {
				error "Unknown option $opt"
			}
			if {[incr index 2] > [llength $args]} {
				error "Value for $opt missing"
			}
			set prop [string range $opt 1 end]
			dict set props $prop $val
		}
	
		set pins [dict create]
		set numIns [expr [dict get $props numInputs]]
		set numPins [expr $numIns + [dict get $props numOutputs]]
		for {set i 0} {$i < $numPins} {incr i} {
			dict append pins $i $i
		}
		dbg::msg "[dict values $pins]"
		dict append props ports $pins
		set conns [dict create]
		dict append props connectedInsts $conns
		set nets [dict create]
		dict append props nets $nets
	
		dict append nl::insts $name $props
		dbg::msg "[dict get $nl::insts $name]"
	
		set xMax [expr [dict get $props x] + [dict get $props width] ]
		if {$xMax > $nl::chipWidth} {
			dbg::msg "resetting chip width: old val is $nl::chipWidth, new val is [expr 1.25 * $xMax]"
			set nl::chipWidth [expr 1.25 * $xMax]
		}
		set yMax [expr [dict get $props y] + [dict get $props height] ]
		if {$yMax > $nl::chipHeight} {
			dbg::msg "resetting chip height: old val is $nl::chipHeight, new val is [expr 1.25 * $yMax]"
			set nl::chipHeight [expr 1.25 * $yMax]
		}
		set GUI::status "Created instance $name"
	}
	
	proc makeNet {args} {
		# syntax: nlNet <-name name> -from fromPort -to toPort
		# Todo: multi-fanout nets
		set id $nl::netId
		incr nl::netId
	
		set legalOpts {-name -from -to}
	
		set props [dict create name "" from false to false]
	
		set index -1
		set from false
		set to false
		set name ""
		foreach {opt val} $args {
			if {-1 == [lsearch $legalOpts $opt]} {
				error "Unknown option $opt"
			}
			if {[incr index 2] > [llength $args]} {
				error "Value for $opt missing"
			}
			if {"-from" == $opt} {
				dict set props from $val
				set from $val
			} elseif {"-to" == $opt} {
				dict set props to $val
				set to $val
			} else {
				dict set props name $val
				set name $val
				dbg::msg "name is $val"
			}
		}
		dict append nl::nets $id $props
		dbg::msg "[dict values $nl::nets]"
	
		set fromInstName [string range $from 0 [expr ([string last . $from]) - 1]]
		set toInstName [string range $to 0 [expr ([string last . $to]) - 1]]
		set fromInst [dict get $nl::insts $fromInstName]
		set toInst [dict get $nl::insts $toInstName]
		set fromConns [dict get $fromInst connectedInsts]
		dict set nl::insts $fromInstName nets $id true
		dbg::msg "fromConns is $fromConns"
		if {! [dict exists $fromConns $toInstName] } {
			dbg::msg "adding $toInstName to conns of $fromInstName"
			dict append fromConns $toInstName $toInstName
			dict set nl::insts $fromInstName connectedInsts $fromConns
			dbg::msg "fromInst is [dict get $nl::insts $fromInstName]"
		}
		set toConns [dict get $toInst connectedInsts]
		dict set nl::insts $toInstName nets $id true
		if {! [dict exists $toConns $fromInstName] } {
			dbg::msg "adding $fromInstName to conns of $toInstName"
			dict append toConns $fromInstName $fromInstName
			dict set nl::insts $toInstName connectedInsts $toConns
			dbg::msg "fromInst is [dict get $nl::insts $fromInstName]"
		}
		set GUI::status "Created net $name"
	}
	
	proc makeRgn {name args} {
		# syntax: nlRegion <-x x> <-y y> <-width width> <-height height>
		set id $nl::rgnId
		incr nl::rgnId
	
		set legalOpts {-x -y -width -height}
	
		set props [dict create id $id x 5 y 5 width 100 height 100]
	
		set index -1
		foreach {opt val} $args {
			if {-1 == [lsearch $legalOpts $opt]} {
				error "Unknown option $opt"
			}
			if {[incr index 2] > [llength $args]} {
				error "Value for $opt missing"
			}
			set prop [string range $opt 1 end]
			dict set props $prop $val
		}
		set insts [dict create]
		dict append props insts $insts
		dict append nl::rgns $name $props
		dbg::msg "[dict values $nl::rgns]"
	
		set xMax [expr [dict get $props x] + [dict get $props width] ]
		if {$xMax > $nl::chipWidth} {
			dbg::msg "resetting chip width: old val is $nl::chipWidth, new val is [expr 1.25 * $xMax]"
			set nl::chipWidth [expr 1.25 * $xMax]
		}
		set yMax [expr [dict get $props y] + [dict get $props height] ]
		if {$yMax > $nl::chipHeight} {
			dbg::msg "resetting chip height: old val is $nl::chipHeight, new val is [expr 1.25 * $yMax]"
			set nl::chipHeight [expr 1.25 * $yMax]
		}
		set GUI::status "Created region $name"
	}
	
	proc saveDesign {fileName} {
		# Save the design as nlInst, nlNet, nlRegion commands
		set fp [open $fileName w]
		foreach item [dict keys $nl::insts] {
			set val [dict get $nl::insts $item]
			set type [dict get $val type]
			set ins [dict get $val numInputs]
			set outs [dict get $val numOutputs]
			set parent [dict get $val parent]
			set x [dict get $val x]
			set y [dict get $val y]
			set width [dict get $val width]
			set height [dict get $val height]
			set rgn [dict get $val region]
			set str "nlInst $item -type $type -numInputs $ins -numOutputs $outs -parent $parent -x $x -y $y -width $width -height $height"
			if {("" != $rgn)} {
				set str "$str -region $rgn"
			}
			puts $fp $str
		}
		foreach item [dict keys $nl::nets] {
			set val [dict get $nl::nets $item]
			set from [dict get $val from]
			set to [dict get $val to]
			set name [dict get $val name]
			dbg::msg "net name is $name"
			if {("" != $name)} {
				set str "nlNet -name $name -from $from -to $to"
			} else {
				set str "nlNet -from $from -to $to"
			}
			puts $fp $str
		}
		foreach item [dict keys $nl::rgns] {
			set val [dict get $nl::rgns $item]
			set x [dict get $val x]
			set y [dict get $val y]
			set width [dict get $val width]
			set height [dict get $val height]
			set val [dict get $nl::rgns $item]
			set str "nlRegion $item -x $x -y $y -width $width -height $height"
			puts $fp $str
		}
		close $fp
	}
	
	proc loadDesign {fileName} {
		set fp [open $fileName r]
		set design [read $fp]
		set data [split $design "\n"]
		foreach line $data {
			$GUI::slave eval $line
		}
		close $fp
	}
	
	proc clearDesign {} {
		# Delete all insts, nets and rgns
		foreach item [dict keys $nl::insts] {
			dict unset nl::insts $item
		}
		dbg::msg "insts: $nl::insts"
		foreach item [dict keys $nl::nets] {
			dict unset nl::nets $item
		}
		dbg::msg "nets: $nl::nets"
		foreach item [dict keys $nl::rgns] {
			dict unset nl::rgns $item
		}
		dbg::msg "rgns: $nl::rgns"
		set nl::chipWidth -1
		set nl::chipHeight -1
	}

	proc assignInstToRgn {instName rgnName x y {considerGeometry true}} {
		# Move the inst to the location (x,y). (x,y) must be within the rgn
		# if considerGeometry is false, just make the assignment and don't
		#	worry about geometry
		dbg::msg "inst is $instName rgn is $rgnName x is $x y is $y"

		if {! [dict exists $nl::insts $instName] } {
			GUI::error "No such inst as $instName"
			return
		}
		set inst [dict get $nl::insts $instName]

		if {! [dict exists $nl::rgns $rgnName] } {
			GUI::error "No such inst as $rgnName"
			return
		}
		set rgn [dict get $nl::rgns $rgnName]

		set geometryError false
		if { $considerGeometry } {
			# Only simple checks now.
			#	Is (part of the) inst sticking outside the rgn?
			# Todo: More thorough checks 
			#	Is an inst placement overlays with an existing placement?
			set rgnX1 [dict get $rgn x]
			set rgnY1 [dict get $rgn y]
			set rgnWidth [dict get $rgn width]
			set rgnHeight [dict get $rgn height]
			set rgnX2 [expr $rgnX1 + $rgnWidth]
			set rgnY2 [expr $rgnY1 + $rgnHeight]

			set instWidth [dict get $inst width]
			set instHeight [dict get $inst height]
			set x2 [expr $x + $instWidth]
			set y2 [expr $y + $instHeight]

			if { ($x < $rgnX1) || ($x > $rgnX2) } {
				set geometryError true
			} elseif { ($x2 < $rgnX1) || ($x2 > $rgnX2) } {
				set geometryError true
			} elseif { ($y < $rgnY1) || ($y > $rgnY2) } {
				set geometryError true
			} elseif { ($y2 < $rgnY1) || ($y2 > $rgnY2) } {
				set geometryError true
			}
			if { $geometryError } {
				GUI::error "inst $instName is going out of the region $rgnName, cannot make the assignment\nRegion box is $rgnX1 $rgnY1 $rgnX2 $rgnY1\nRequested inst box is $x $y $x2 $y2"
				return
			}
		}
		dict set nl::insts $instName x $x
		dict set nl::insts $instName y $y
		dict set nl::insts $instName region $rgnName
		#dict set [dict get $nl::insts $instName] y $y
		#dict set [dict get $nl::insts $instName] region $rgnName
		#dbg::msg "$instName: [dict get $nl::insts $instName]"
		dict set nl::rgns $rgnName insts $instName true
		#dbg::msg "$rgnName: [dict get $nl::rgns $rgnName]"
	}

	proc setChipWidth {w} {
		set nl::chipWidth $w
	}

	proc setChipHeight {h} {
		set nl::chipHeight $h
	}
}

