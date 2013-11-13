#!/usr/local/bin/wish

# All code (c)2013 R.V. Subramanyan All rights reserved.
# Developer: RV (rv@gmail.com)
# GUI functions

#define normal 0 - normal drawing mode
#define selected 1 - some inst(s) selected
#define filterConns 2 - show the selected insts and their connected insts only


namespace eval GUI {

	# Widgets
	set cnvs false; # Canvas Widget where the schematic is drawn
	set hsb false; # Horizontal Scrollbar
	set vsb false; # Vertical Scrollbar
	set cmdWdgt false; # Entry Widget to type commands
	set cmd "Command Window"; # Command to be executed - from cmdWdgt
	set statusWdgt false;
	set status "Status Window"; # Status msg to be displayed

	# Geometry
	set cnvsWidth -1; # width of canvas Widget
	set cnvsHeight -1; # height of canvas widget
	set vpX 0; # Viewport (i.e. area of design on display) lower left corner
	set vpY 0; # Viewport lower left corner
	set vpWidth -1; # viewport width
	set vpHeight -1; # viewport height
	set vpMinWidth -1; # Viewport width not to shrink below chipWidth/16
	set vpMinHeight -1; # Viewport height not to shrink below chipHeight/16

	# Selections
	set selectedInst "" 
	set selectedRgn ""
	set selectedNet ""

	# Parameters for drawing
	# To draw pins etc. Does not depend on chip dimensions.
	set pinOffset 4;
	font create tinyFont -family Arial -size 10; # for port names
	set pinDisplay true
	
	#  To find inst/rgn from a click, store rects on canvas for them
	set instRects [dict create];
	set rgnRects [dict create];

	# Drag and Drop setup
	set dndStartX -1
	set dndStartY -1
	set dndOldX -1
	set dndOldY -1
	set dndInstName ""

	# For initial splash screen
	set splashOver false; # is splash done?
	font create splashTitleFont -family Helvetica -size 20 -weight bold
	font create splashSubtitleFont -family Arial -size 15
	set logo [image create photo -file data/synopsys.gif]
	set RV [image create photo -file data/rv.gif]

	# If mode is 0: draw everything
	#	mode is 1: show conns of the selected inst only
	#	mode is 2: show conns of the selected rgn only
	#	mode is 3: show conns of the selected net only
	set mode 0

	set slave [interp create slave]
	# Slave interpreter aliases. These aliases are executed from cmdWdgt
	#	and loadDesign.
	interp alias slave setPinDisplay {} GUI::setPinDisplay
	interp alias slave goIntoRegion {} GUI::goIntoRgn
	interp alias slave nlSetChipWidth {} nl::setChipWidth
	interp alias slave nlSetChipHeight {} nl::setChipHeight
	interp alias slave nlInst {} nl::makeInst
	interp alias slave nlNet {} nl::makeNet
	interp alias slave nlRegion {} nl::makeRgn
	interp alias slave loadDesign {} GUI::loadDesign
	interp alias slave saveDesign {} nl::saveDesign
	interp alias slave clearDesign {} GUI::clearDesign
	interp alias slave designInfo {} GUI::designInfo
	interp alias slave selectInst {} GUI::setSelectInst
	interp alias slave unselectInst {} GUI::unselectInst
	interp alias slave instInfo {} GUI::instInfo
	interp alias slave showInstConnections {} GUI::showInstConns
	interp alias slave selectRegion {} GUI::setSelectRgn
	interp alias slave unselectRegion {} GUI::unselectRgn
	interp alias slave regionInfo {} GUI::rgnInfo
	interp alias slave regionFlylines {} GUI::rgnFlylines
	interp alias slave assignInstToRegion {} GUI::assignInstToRgn
	interp alias slave showRegionConnections {} GUI::showRgnConns
	interp alias slave selectNet {} GUI::setSelectNet
	interp alias slave unselectNet {} GUI::unselectNet
	interp alias slave netInfo {} GUI::netInfo
	interp alias slave showNetConnections {} GUI::showNetConns

	proc calcCnvsDims {w} {
		set prevFn [dbg::enterFn calcCnvsDims]
		set GUI::cnvsWidth [winfo width $w]
		set GUI::cnvsHeight [winfo height $w]
		dbg::msg "$w $GUI::cnvsWidth, $GUI::cnvsHeight"
		if {$GUI::splashOver} {
			dbg::msg "Splash over vpWidth is $GUI::vpWidth nlWidth is $nl::chipWidth"
			if {-1 == $GUI::vpWidth} {
				if {-1 != $nl::chipWidth} {
					GUI::setDefaultViewport
				}
				dbg::msg "$GUI::cnvsWidth, $GUI::cnvsHeight"
			}
			GUI::drawSchematic
			#dbg::msg "ff is $GUI::ff"
			#if { $GUI::ff } {
				#dbg::msg "drawing ff $GUI::ff"
				#GUI::drawFF 500 250
			#}
		} else {
			GUI::splashScreen
		}
		dbg::exitFn $prevFn
	}

	proc splashScreen {} {
		set prevFn [dbg::enterFn splashScreen]
		$GUI::cnvs delete all
		set xcen [expr $GUI::cnvsWidth / 2]
		dbg::msg "wid is $GUI::cnvsWidth xcen is $xcen"
		set title "TCL/TK Prototype for Vineet Rashingkar"
		$GUI::cnvs create text $xcen 100 -text $title -font splashTitleFont -fill darkblue -tag foo
		$GUI::cnvs create text $xcen 125 -text "by RV" -font splashSubtitleFont -fill darkgreen -tag foo
		$GUI::cnvs create image [expr $xcen - 125] 250 -image $GUI::logo -tag foo
		$GUI::cnvs create image [expr $xcen + 125] 250 -image $GUI::RV -tag foo
		$GUI::cnvs create text $xcen 400 -text "Click to continue" -tag foo
		set GUI::status "Click to continue"
		dbg::exitFn $prevFn
	}

	proc setDefaultViewport {} {
		set prevFn [dbg::enterFn setDefaultViewport]
		set GUI::vpX 0
		set GUI::vpY 0
		set GUI::vpWidth $nl::chipWidth
		set GUI::vpHeight $nl::chipHeight
		set GUI::vpMinWidth [expr $GUI::vpWidth / 16 ]
		set GUI::vpMinHeight [expr $GUI::vpHeight / 16 ]
		dbg::exitFn $prevFn
	}

	proc zoomOut {w} {
		# zoomOut doubles the Viewport in both x & y directions
		# Currently we cannot zoom out beyond the size of the chip
		set prevFn [dbg::enterFn zoomOut]
		dbg::msg "$w x,y,wid,hei $GUI::vpX $GUI::vpY $GUI::vpWidth $GUI::vpHeight"
		if {-1 == $GUI::vpWidth} {
			GUI::setDefaultViewport
		}
		if {$GUI::vpWidth < $nl::chipWidth} {
			set tmp [expr 2 * $GUI::vpWidth]
			if {$tmp > $nl::chipWidth} {
				GUI::setDefaultViewport
			} else {
				set GUI::vpX [expr $GUI::vpX - ($GUI::vpWidth/2)]
				if {0 > $GUI::vpX} {
					set GUI::vpX 0
				}
				set GUI::vpY [expr $GUI::vpY - ($GUI::vpHeight/2)]
				if {0 > $GUI::vpY} {
					set GUI::vpY 0
					set GUI::status "Cannot zoom out any more"
				}
				set GUI::vpWidth $tmp
				set GUI::vpHeight [expr 2 * $GUI::vpHeight]
			}
		}
		GUI::drawSchematic
		dbg::msg "x,y,wid,hei $GUI::vpX $GUI::vpY $GUI::vpWidth $GUI::vpHeight"
		dbg::exitFn $prevFn
	}

	proc zoomIn {w} {
		# zoomIn halves the Viewport in both x & y directions
		# Currently we cannot zoom in beyond 1/16th of the chip
		# Todo: Make this 1/16th a configurable parameter
		set prevFn [dbg::enterFn zoomIn]
		dbg::msg "$w x,y,wid,hei $GUI::vpX $GUI::vpY $GUI::vpWidth $GUI::vpHeight"
		if {-1 == $GUI::vpWidth} {
			GUI::setDefaultViewport
		}
		set tmp [expr $GUI::vpWidth / 2]
		if {$tmp > $GUI::vpMinWidth} {
			set GUI::vpWidth $tmp
			set GUI::vpHeight [expr $GUI::vpHeight / 2]
			set GUI::vpX [expr $GUI::vpX + ($GUI::vpWidth/2)]
			set GUI::vpY [expr $GUI::vpY + ($GUI::vpHeight/2)]
			GUI::drawSchematic
		} else {
			set GUI::status "Cannot zoom in any more"
		dbg::msg "x,y,wid,hei $GUI::vpX $GUI::vpY $GUI::vpWidth $GUI::vpHeight"
		}
		dbg::exitFn $prevFn
	}

	proc showInfo {} {
		set prevFn [dbg::enterFn showInfo]
		if { "" != $GUI::selectedInst } {
			instInfo $GUI::selectedInst
		}
		if { "" != $GUI::selectedRgn } {
			rgnInfo $GUI::selectedRgn
		}
		if { "" != $GUI::selectedNet } {
			netInfo $GUI::selectedNet
		}
		designInfo
		dbg::exitFn $prevFn
	}

	proc drawSchematic {} {
		# Draw the schematic
		# Set the scroll parameters
		set prevFn [dbg::enterFn drawSchematic]
		if {! $GUI::splashOver} {
			return
		}
		$GUI::cnvs delete all
		if {(0 >= $nl::chipWidth)} {
			#Design has been cleared
		} else {
			GUI::drawChip
			dbg::msg "drew chip"
			GUI::drawRgns
			dbg::msg "drew rgns"
			GUI::drawInsts
			dbg::msg "drew insts"
			GUI::drawNets
			dbg::msg "drew nets"
			set first [expr (1.0*$GUI::vpX)/$nl::chipWidth]
			set last [expr (1.0*($GUI::vpX+$GUI::vpWidth))/$nl::chipWidth]
			dbg::msg "vpX vpWidth chipWidth first last $GUI::vpX $GUI::vpWidth $nl::chipWidth $first $last"
			$GUI::hsb set $first $last
			$GUI::cnvs xview moveto $first
			set first [expr 1.0 - (1.0*$GUI::vpY)/$nl::chipHeight]
			set last [expr 1.0 - (1.0*($GUI::vpY+$GUI::vpHeight))/$nl::chipHeight]
			dbg::msg "vpY vpHeight chipHeight first last $GUI::vpY $GUI::vpHeight $nl::chipHeight $first $last"
			$GUI::vsb set $last $first
			$GUI::cnvs yview moveto $first
			dbg::msg "h nowat [$GUI::cnvs xview] v nowat [$GUI::cnvs yview]"
			#$GUI::cnvs raise text
		}
		update idletasks
		dbg::exitFn $prevFn
	}

	proc getX {x} {
		# X Transformation - we use 80% horizontal area for drawing
		set prevFn [dbg::enterFn getX]
		dbg::msg "$x $GUI::cnvsWidth $GUI::vpWidth $GUI::vpX $nl::chipWidth"
		set x1 [expr (round ((0.1*$GUI::cnvsWidth) + [expr (0.8*($x-$GUI::vpX)*$GUI::cnvsWidth/$GUI::vpWidth)]))]
		dbg::msg "in, out: $x $x1"
		dbg::exitFn $prevFn
		return $x1
	}

	proc getY {y} {
		# Y Transformation - We use 80% vertical area for drawing.
		set prevFn [dbg::enterFn getY]
		# UI y starts at top, chip y starts at bottom.
		dbg::msg "$y $GUI::cnvsHeight $nl::chipHeight"
		set y1 [expr (round ((0.9*$GUI::cnvsHeight) - [expr (0.8*($y-$GUI::vpY)*$GUI::cnvsHeight/$GUI::vpHeight)]))]
		dbg::msg "in, out: $y $y1"
		dbg::exitFn $prevFn
		return $y1
	}

	proc getChipX {x} {
		# Reverse of getX
		set prevFn [dbg::enterFn getChipX]
		dbg::msg "$x $GUI::cnvsWidth $GUI::vpWidth $GUI::vpX $nl::chipWidth"
		set x1 [expr $GUI::vpX + (1.25* $GUI::vpWidth * ($x- (0.1*$GUI::cnvsWidth)) / $GUI::cnvsWidth)]
		dbg::msg "in, out: $x $x1"
		dbg::exitFn $prevFn
		return $x1
	}

	proc getChipY {y} {
		# Reverse of getY
		set prevFn [dbg::enterFn getChipY]
		# UI y starts at top, chip y starts at bottom.
		dbg::msg "$y $GUI::cnvsHeight $nl::chipHeight"
		set y1 [expr $GUI::vpY + (1.25 * $GUI::vpHeight * ((0.9 * $GUI::cnvsHeight) - $y) / $GUI::cnvsHeight)]
		dbg::msg "in, out: $y $y1"
		dbg::exitFn $prevFn
		return $y1
	}

	proc drawChip {} {
		# Draw the chip outline
		# Todo: Not sure whether we should do this
		set prevFn [dbg::enterFn drawChip]
		set w [GUI::getX $nl::chipWidth]
		set h [GUI::getY $nl::chipHeight]
		set x0 [GUI::getX 0]
		set y0 [GUI::getY 0]
		dbg::msg "$x0 $y0 $w $h"
		set item [$GUI::cnvs create rectangle $x0 $y0 $w $h -outline red -width 3]
		set tooltipText "Design Info\n# of Insts: $nl::instId\n# of Regions: $nl::rgnId\n# of Nets: $nl::netId"
		update idletasks
		tooltip::tooltip $GUI::cnvs -item $item $tooltipText
		dbg::exitFn $prevFn
	}

	proc drawRgns {} {
		# Draw all regions
		set prevFn [dbg::enterFn drawRgns]
		dbg::msg "winWid,Hei are $GUI::cnvsWidth, $GUI::cnvsHeight"
		foreach rgn [dict keys $nl::rgns] {
			set val [dict get $nl::rgns $rgn]
			dbg::msg "$rgn is $val"
			set x [dict get $val x]
			set y [dict get $val y]
			set w [dict get $val width]
			set h [dict get $val height]
			dbg::msg "x y wid hei are $x $y $w $h"
			set x1 [GUI::getX $x]
			set y1 [GUI::getY $y]
			set w1 [GUI::getX [expr $w + $x]]
			set h1 [GUI::getY [expr $h + $y]]
			dbg::msg "x1 y1 x2 y2 are $x1 $y1 $w1 $h1"
			set color blue
			set lw 3
			if {$rgn == $GUI::selectedRgn} {
				dbg::msg "$rgn is selected"
				set lw 5
				set color red
			} else {
				dbg::msg "$rgn is not selected"
			}
			set item [$GUI::cnvs create rectangle $x1 $y1 $w1 $h1 -width $lw -dash {2 4} -outline $color -tag rgn -tag $rgn]
			dict set GUI::rgnRects $rgn x1 $x1
			dict set GUI::rgnRects $rgn y1 $y1
			dict set GUI::rgnRects $rgn x2 $w1
			dict set GUI::rgnRects $rgn y2 $h1
			set tooltipText "Region: $rgn"
			set insts [dict get $val insts]
			if { 0 < [dict size $insts] } {
				set tooltipText "$tooltipText: [dict size $insts] assignments - "
				foreach inst [dict keys $insts] {
					set tooltipText "$tooltipText $inst"
				}
			}
			tooltip::tooltip $GUI::cnvs -item $item $tooltipText
			dbg::msg "rgnRects are $GUI::rgnRects"
			set xstr [expr ($x1 + $w1)/2]
			set ystr [expr ($y1 + $h1) /2]
			dbg::msg "$xstr $ystr box is $x1 $y1 $w1 $h1 txt is $rgn"
			$GUI::cnvs create text $xstr $ystr -text $rgn -fill blue -tag rgn -tag $rgn -tag text
		}
		dbg::exitFn $prevFn
	}

	proc drawOneInst {inst {highlight false} } {
		# Draw the given inst as a rect.
		# If highlight is true (selected inst), draw it in red
		# Store the rect for easy calculation of click to inst
		set prevFn [dbg::enterFn drawOneInst]
		set val [dict get $nl::insts $inst]
		#dbg::msg "$inst is $val"
		dbg::msg "inst is $inst"
		set x [dict get $val x]
		set y [dict get $val y]
		set w [dict get $val width]
		set h [dict get $val height]
		dbg::msg "$x $y $w $h"
		set x1 [GUI::getX $x]
		set y1 [GUI::getY $y]
		set w1 [GUI::getX [expr $w + $x]]
		set h1 [GUI::getY [expr $h + $y]]
		dbg::msg "$x1 $y1 $w1 $h1"
		set lw 1
		set color darkgreen
		if {$highlight} {
			set lw 3
			set color red
		}
		set item [$GUI::cnvs create rectangle $x1 $y1 $w1 $h1 -width $lw -outline $color -tag inst -tag $inst]
		dict set GUI::instRects $inst x1 $x1
		dict set GUI::instRects $inst y1 $y1
		dict set GUI::instRects $inst x2 $w1
		dict set GUI::instRects $inst y2 $h1
		dbg::msg "instRects are $GUI::instRects"

		set xstr [expr ($x1 + $w1)/2]
		set ystr [expr ($y1 + $h1) /2]
		dbg::msg "$xstr $ystr box is $x1 $y1 $w1 $h1 txt is $inst"
		$GUI::cnvs create text $xstr $ystr -text $inst -fill darkgreen -tag inst -tag text -tag $inst 

#Draw Pins
		set ins [dict get $val numInputs]
		set outs [dict get $val numOutputs]
		set numPorts [expr $ins + $outs]
		set ih [expr ($h1-$y1) / [expr $ins+1]]
		set oh [expr ($h1-$y1) / [expr $outs+1]]
		set mid [expr (($y1 + $h1)/2)]
		if { (1.0 > $ih) } {
# No space to draw all pins
			set x2 [expr $x1-(4*$GUI::pinOffset)]
			$GUI::cnvs create line $x1 $mid $x2 $mid -width 2 -fill gray -tag inst -tag $inst
			set xx1 [expr $x2 + $GUI::pinOffset]
			set xy1 [expr $mid - (2*$GUI::pinOffset)]
			set xx2 [expr $x2 + (2*$GUI::pinOffset)]
			set xy2 [expr $mid + (2*$GUI::pinOffset)]
			$GUI::cnvs create line $xx1 $xy1 $xx2 $xy2 -fill gray -tag inst -tag $inst
			dbg::msg "pindisplay is $GUI::pinDisplay"
			if { $GUI::pinDisplay } {
				$GUI::cnvs create text $xx2 $xy1 -text $ins -font tinyFont -fill gray -tag inst -tag text -tag $inst
			}
		} else {
			set ypos [expr $y1 + $ih]
			set x2 [expr $x1-$GUI::pinOffset]
			for {set i 0} {$i < $numIns} {incr i} {
				dbg::msg "pin# $i"
				dbg::msg "x1 is $x1, ypos is $ypos, x2 is $x2"
				$GUI::cnvs create line $x1 $ypos $x2 $ypos -width 2 -fill gray -tag inst -tag $inst
				set ypos [expr $ypos + $ih]
			}
		}
		if { (1.0 > $oh) } {
# No space to draw all pins
			set x2 [expr $w1+(4*$GUI::pinOffset)]
			$GUI::cnvs create line $w1 $mid $x2 $mid -width 2 -fill gray -tag inst -tag $inst
			set xx1 [expr $x2 - [expr 3 * $GUI::pinOffset]]
			set xy1 [expr $mid - (2*$GUI::pinOffset)]
			set xx2 [expr $x2 - $GUI::pinOffset]
			set xy2 [expr $mid + (2*$GUI::pinOffset)]
			$GUI::cnvs create line $xx1 $xy1 $xx2 $xy2 -fill gray -tag inst -tag $inst
			dbg::msg "pindisplay is $GUI::pinDisplay"
			if { $GUI::pinDisplay } {
				$GUI::cnvs create text $xx2 $xy1 -text $outs -font tinyFont -fill gray -tag inst -tag text -tag $inst
			}
		} else {
			set x2 [expr $w1+$GUI::pinOffset]
			set ypos [expr $y1 + $oh]
			for {set i $numIns} {$i < $numPorts} {incr i} {
				$GUI::cnvs create line $x1 $ypos $x2 $ypos -fill darkgreen -tag inst -tag $inst
				set ypos [expr $ypos + $oh]
			}
		}
#tooltip
		#set tooltipText "$inst\nInputs:$ins\nOutputs:$outs"
		#set rgn [dict get $val region]
		#if { "" != $rgn } {
		#	set tooltipText "$tooltipText\nAssigned to: $rgn"
		#}
		#tooltip::tooltip $GUI::cnvs -item $item $tooltipText
		dbg::exitFn $prevFn
	}

	proc drawOnlyInstsOfSelectedNet {} {
		set prevFn [dbg::enterFn drawOnlyInstsOfSelectedNet]
		# Draw only the selected net and its conn insts.
		dbg::msg "Drawing insts of $GUI::selectedNet only"
		set net [dict get $nl::nets $GUI::selectedNet]
		set from [dict get $net from]
		set to [dict get $net to]
		set fromInstName [string range $from 0 [expr ([string last . $from]) - 1]]
		GUI::drawOneInst $fromInstName
		set toInstName [string range $to 0 [expr ([string last . $to]) - 1]]
		GUI::drawOneInst $toInstName
		dbg::exitFn $prevFn
	}

	proc drawOnlyInstsOfSelectedRgn {} {
		set prevFn [dbg::enterFn drawOnlyInstsOfSelectedRgn]
		# Draw only insts (and their connInsts) assigned to the rgn.
		# connInsts may be outside the rgn
		dbg::msg "Drawing insts of $GUI::selectedRgn only"
		set rgn [dict get $nl::rgns $GUI::selectedRgn]
		set insts [dict get $rgn insts]
		foreach inst [dict keys $insts] {
			dbg::msg "inst is $inst"
			GUI::drawOneInst $inst
			set conns [dict get $nl::insts $inst connectedInsts]
			foreach connInst [dict keys $conns] {
				dbg::msg "connInst is $connInst"
				GUI::drawOneInst $connInst
			}
		}
		dbg::exitFn $prevFn
	}

	proc drawOnlySelectedInst {} {
		set prevFn [dbg::enterFn drawOnlySelectedInst]
		# Draw only the selected inst and its conn insts.
		dbg::msg "drawing $GUI::selectedInst only"
		GUI::drawOneInst $GUI::selectedInst true
		set inst [dict get $nl::insts $GUI::selectedInst]
		set conns [dict get $inst connectedInsts]
		foreach connInst [dict keys $conns] {
			dbg::msg "connInst is $connInst"
			GUI::drawOneInst $connInst
		}
		dbg::exitFn $prevFn
	}

	proc drawInsts {} {
		set prevFn [dbg::enterFn drawInsts]
		dbg::msg "mode is $GUI::mode"
		if { 3 == $GUI::mode } {
			drawOnlyInstsOfSelectedNet
		} elseif { 2 == $GUI::mode } {
			drawOnlyInstsOfSelectedRgn
		} elseif { 1 == $GUI::mode } {
			drawOnlySelectedInst
		} else {
			foreach inst [dict keys $nl::insts] {
				if { $inst == $GUI::selectedInst } {
					GUI::drawOneInst $inst true
				} else {
					GUI::drawOneInst $inst
				}
			}
		}
		dbg::exitFn $prevFn
	}

	proc drawNet {netName {highlight false} } {
		set prevFn [dbg::enterFn drawNet]
		set val [dict get $nl::nets $netName]
		dbg::msg "net is $val"
		set from [dict get $val from]
		set to [dict get $val to]
		dbg::msg "from is $from to is $to"
		set fromInstName [string range $from 0 [expr ([string last . $from]) - 1]]
		set toInstName [string range $to 0 [expr ([string last . $to]) - 1]]
		set fromPin [string range $from [expr ([string last . $from]) + 1] [string length $from]]
		set toPin [string range $to [expr ([string last . $to]) + 1] [string length $to]]
		dbg::msg "fromInst is $fromInstName fromPin is $fromPin toInst is $toInstName toPin is $toPin"
		set fromInst [dict get $nl::insts $fromInstName]
		set toInst [dict get $nl::insts $toInstName]
		dbg::msg "fromInst is $fromInst toInst is $toInst"

		set fromX [expr [dict get $fromInst x] + [dict get $fromInst width]]
		set fromYBase [dict get $fromInst y]
		set numIns [dict get $fromInst numInputs]
		set numOuts [dict get $fromInst numOutputs]
		set fromYOff [expr ([expr $fromPin - $numIns] * [dict get $fromInst height]) / [expr $numOuts+1]]
		set fromY [expr $fromYBase + $fromYOff]
		dbg::msg "fromX is $fromX fromYbase is $fromYBase fromYOff is $fromYOff fromY is $fromY"

		set toX [dict get $toInst x]
		set toYBase [dict get $toInst y]
		set numIns [dict get $toInst numInputs]
		set toYOff [expr ($toPin * [dict get $toInst height]) / [expr $numIns+1]]
		set toY [expr $toYBase + $toYOff]
		dbg::msg "toX is $toX toYbase is $toYBase toYOff is $toYOff toY is $toY"

		set fx [expr [GUI::getX $fromX] + $GUI::pinOffset]
		set fy [GUI::getY $fromY]
		set tx [expr [GUI::getX $toX] - $GUI::pinOffset]
		set ty [GUI::getY $toY]
		#set mx [expr ($fx+$tx)/2]
		set netCoords [list]
		lappend netCoords $fx $fy
		# Todo: should be a visually pleasing route 
		#lappend netCoords $mx $fy
		#lappend netCoords $mx $ty
		lappend netCoords $tx $ty
		set lw 1
		set color gray
		if {$highlight} {
			set lw 3
			set color red
		}
		set item [$GUI::cnvs create line $netCoords -fill $color -width $lw -tag net -tag net$netName]
#tooltip
		#set tooltipText "net $netName\nfrom: $fromInstName.$fromPin\nto: $toInstName.$toPin"
		#tooltip::tooltip $GUI::cnvs -item $item $tooltipText
		dbg::exitFn $prevFn
	}

	proc drawNetsOfInst {instName} {
		set prevFn [dbg::enterFn drawNetsOfInst]
		set inst [dict get $nl::insts $instName]
		set nets [dict get $inst nets]
		foreach net [dict keys $nets] {
			drawNet $net
		}
		dbg::exitFn $prevFn
	}

	proc drawOnlyNetsOfSelectedRgn {} {
		set prevFn [dbg::enterFn drawOnlyNetsOfSelectedRgn]
		# Draw only the nets of insts in rgn
		dbg::msg "drawing nets of insts in rgn $GUI::selectedRgn only"
		set rgn [dict get $nl::rgns $GUI::selectedRgn]
		set insts [dict get $rgn insts]
		foreach inst [dict keys $insts] {
			drawNetsOfInst $inst
		}
		dbg::exitFn $prevFn
	}

	proc drawNets {} {
		set prevFn [dbg::enterFn drawNets]
		if { 3 == $GUI::mode } {
			drawNet $GUI::selectedNet true
		} elseif { 2 == $GUI::mode } {
			drawOnlyNetsOfSelectedRgn
		} elseif { 1 == $GUI::mode } {
			drawNetsOfInst $GUI::selectedInst
		} else {
			foreach net [dict keys $nl::nets] {
				if { $net == $GUI::selectedNet } {
					drawNet $net true
				} else {
					drawNet $net
				}
			}
		}
		dbg::exitFn $prevFn
	}

	proc vertScroll {args} {
		set prevFn [dbg::enterFn vertScroll]
		set nowat [$GUI::cnvs yview]
		set scrollPos [$GUI::vsb get]
		set start [lindex $scrollPos 0]
		dbg::msg "args is $args nowat $nowat scrollPos is $scrollPos start is $start"
		set cmdList [split $args]
		dbg::msg "cmdList is $cmdList"
		switch [lindex $cmdList 0] {
			"scroll" {
				set foo [lindex $cmdList 2]
				set count [lindex $cmdList 1]
				if {[string first units $foo] >= 0} {
					set incr [expr 1 * $count]
				} else {
					set incr [expr $GUI::vpHeight * $count]
				}
				dbg::msg "incr is $incr"
				set GUI::vpY [expr $GUI::vpY - $incr]
				dbg::msg "vpY is $GUI::vpY"
				if {0 > $GUI::vpY} {
					set GUI::vpY 0
				}
				dbg::msg "vpY is $GUI::vpY"
			}
			"moveto" {
				dbg::msg "moveto"
				set top [lindex $cmdList 1]
				if {0.0 > $top} {
					set top 0.0
				}
				dbg::msg "moveto top is $top"
				set GUI::vpY [expr $nl::chipHeight * $top]
				dbg::msg "moveto vpY is $GUI::vpY"
			}
		}
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc horizScroll {args} {
		set prevFn [dbg::enterFn horizScroll]
		set nowat [$GUI::cnvs xview]
		set scrollPos [$GUI::hsb get]
		set start [lindex $scrollPos 0]
		dbg::msg "args is $args nowat $nowat scrollPos is $scrollPos start is $start"
		set cmdList [split $args]
		dbg::msg "cmdList is $cmdList"
		switch [lindex $cmdList 0] {
			"scroll" {
				dbg::msg "scroll"
				set foo [lindex $cmdList 2]
				dbg::msg "unit is $foo"
				set count [lindex $cmdList 1]
				if {[string first units $foo] >= 0} {
					set incr [expr 1 * $count]
					dbg::msg "incr is $count units"
				} else {
					set incr [expr $GUI::vpWidth * $count]
					dbg::msg "incr is $count pages"
				}
				dbg::msg "incr is $incr"
				set GUI::vpX [expr $GUI::vpX + $incr]
				dbg::msg "vpX is $GUI::vpX"
				if {0 > $GUI::vpX} {
					set GUI::vpX 0
				}
				dbg::msg "vpX is $GUI::vpX"
			}
			"moveto" {
				dbg::msg "moveto"
				set frac [lindex $cmdList 1]
				if {0.0 > $frac} {
					set frac 0.0
				}
				dbg::msg "moveto frac is $frac"
				set GUI::vpX [expr $nl::chipWidth * $frac]
				dbg::msg "moveto vpX is $GUI::vpX"
			}
		}
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc killSplash {w} {
		set prevFn [dbg::enterFn killSplash]
		dbg::msg "w is $w"
		$w delete foo
		if {! $GUI::splashOver} {
			set GUI::splashOver true
		}
		GUI::calcCnvsDims $w
		set GUI::status ""
		dbg::exitFn $prevFn
	}

	proc clearSelection {w} {
		set prevFn [dbg::enterFn clearSelection]
		dbg::msg "w is $w"
		set GUI::selectedInst ""
		set GUI::selectedRgn ""
		set GUI::selectedNet ""
		set GUI::mode 0
		dbg::msg "mode is normal"
		GUI::calcCnvsDims $w
		set GUI::status "Selection cleared"
		dbg::exitFn $prevFn
	}

	proc findObj {x y rectDict} {
		# See where the click falls in the rectDict and identify the obj.
		# Maybe an inst or a rgn
		set prevFn [dbg::enterFn findObj]
		set ret ""
		dbg::msg "click at $x $y"
		foreach obj [dict keys $rectDict] {
			set val [dict get $rectDict $obj]
			dbg::msg "obj is $obj val is $val"
			set x1 [dict get $val x1]
			dbg::msg "x1 is $x1"
			if {$x1 > $x} { continue }
			set x2 [dict get $val x2]
			dbg::msg "x2 is $x2"
			if {$x2 < $x} { continue }
			set y1 [dict get $val y1]
			dbg::msg "y1 is $y1"
			if {$y1 < $y} { continue }
			set y2 [dict get $val y2]
			dbg::msg "y2 is $y2"
			if {$y2 > $y} { continue }
			dbg::msg "obj is $obj"
			set ret $obj
			break
		}
		dbg::exitFn $prevFn
		return $ret
	}

	proc findInst {x y} {
		# See where the click falls among instRects and identify the inst.
		set prevFn [dbg::enterFn findInst]
		set ret [findObj $x $y $GUI::instRects]
		if { "" == $ret } {
			dbg::msg "no inst at click"
		}
		dbg::exitFn $prevFn
		return $ret
	}

	proc findRgn {x y} {
		# See where the click falls among rgnRects and identify the rgn.
		set prevFn [dbg::enterFn findRgn]
		set ret [findObj $x $y $GUI::rgnRects]
		if { "" == $ret } {
			dbg::msg "no rgn at click"
		}
		dbg::exitFn $prevFn
		return $ret
	}

	proc selectObj {w x y} {
		set prevFn [dbg::enterFn selectObj]
		focus $w
		if {! $GUI::splashOver} {
			killSplash $w
			dbg::exitFn $prevFn
			return
		}
		dbg::msg "w x y are $w $x $y"
		set dnd [ $GUI::cnvs find closest $x $y ]
		dbg::msg "dnd is $dnd"
		#for {set i 0} {$i<100} {incr i} {
		#	$GUI::cnvs move $dnd 1 1
		#}
		set obj [findInst $x $y]
		dbg::msg "inst is $obj"
		if { "" != $obj } {
			set GUI::selectedInst $obj
			dbg::msg "mode is instConn, obj is $obj"
		} else {
			set obj [findRgn $x $y]
			dbg::msg "rgn is $obj"
			if { "" != $obj } {
				set GUI::selectedRgn $obj
				dbg::msg "mode is rgnConn, obj is $obj"
			}
		}
		if { "" != $obj } {
			GUI::drawSchematic
			dbg::msg "inst/rgn is $obj mode is $GUI::mode"
			set GUI::status "Selected object (instance/region): $obj"
		}
		dbg::exitFn $prevFn
	}

	proc showNetConns {netName} {
		set prevFn [dbg::enterFn showNetConns]
		set GUI::selectedNet $netName
		set GUI::mode 3
		dbg::msg "mode is netConn, net is $netName"
		GUI::drawSchematic
		set GUI::status "Showing connections for net $netName"
		dbg::exitFn $prevFn
	}

	proc showRgnConns {rgnName} {
		set prevFn [dbg::enterFn showRgnConns]
		set GUI::selectedRgn $rgnName
		set GUI::mode 2
		dbg::msg "mode is rgnConn, net is $rgnName"
		GUI::drawSchematic
		set GUI::status "Showing connections for region $rgnName"
		dbg::exitFn $prevFn
	}

	proc showInstConns {instName} {
		set prevFn [dbg::enterFn showInstConns]
		set GUI::selectedInst $instName
		set GUI::mode 1
		dbg::msg "mode is instConn, inst is $instName"
		GUI::drawSchematic
		set GUI::status "Showing connections for instance $instName"
		dbg::exitFn $prevFn
	}

	proc filterConns {w x y} {
		set prevFn [dbg::enterFn filterConns]
		dbg::msg "w x y are $w $x $y"
		set dnd [ $GUI::cnvs find closest $x $y ]
		dbg::msg "dnd is $dnd"
		#for {set i 0} {$i<100} {incr i} {
			#$GUI::cnvs move $dnd -1 0
		#}
		set obj [findInst $x $y]
		if { "" != $obj } {
			dbg::msg "inst is $obj"
			showInstConns $obj
		} else {
			set obj [findRgn $x $y]
			if { "" != $obj } {
				dbg::msg "rgn is $obj"
				showRgnConns $obj
			} else {
				set GUI::mode 0
				dbg::msg "mode is normal"
			}
		}
		dbg::exitFn $prevFn
	}

	proc showAbout {} {
		set prevFn [dbg::enterFn showAbout]
		tk_messageBox -message "Prototype for Vineet Rashingkar\nVersion: 0.1\nAuthor: RV" -title "About SynProto"
		dbg::exitFn $prevFn
	}

	proc loadDesign {file} {
		set prevFn [dbg::enterFn loadDesign]
		nl::loadDesign $file
		GUI::drawSchematic
		set GUI::status "Loaded script $file"
		dbg::exitFn $prevFn
	}

	proc openDesign {} {
		set prevFn [dbg::enterFn openDesign]
		set types {
			{{TCL Scripts} {.tcl}}
			{{All Files} *}
		}
		set response [tk_getOpenFile -filetypes $types]
		GUI::loadDesign $response
		dbg::exitFn $prevFn
	}

	proc saveDesign {} {
		set prevFn [dbg::enterFn saveDesign]
		set response [tk_getSaveFile -title Save -defaultextension tcl -parent .]
		if { "" == $response } {
			dbg::exitFn $prevFn
			return; # Cancel was clicked.
		}
		nl::saveDesign $response
		dbg::exitFn $prevFn
	}

	proc clearDesign {} {
		set prevFn [dbg::enterFn clearDesign]
		nl::clearDesign
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc execCmd {} {
		set prevFn [dbg::enterFn execCmd]
		dbg::msg "command is $GUI::cmd"
		$GUI::slave eval $GUI::cmd
		dbg::exitFn $prevFn
	}

	proc setSelectInst {name} {
		set prevFn [dbg::enterFn setSelectInst]
		set GUI::selectedInst $name
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc setSelectRgn {name} {
		set prevFn [dbg::enterFn setSeletRgn]
		set GUI::selectedRgn $name
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc setSelectNet {name} {
		set prevFn [dbg::enterFn setSelectNet]
		set GUI::selectedNet $name
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc designInfo {} {
		set prevFn [dbg::enterFn designInfo]
		set info "# of Insts: $nl::instId\n# of Regions: $nl::rgnId\n# of Nets: $nl::netId"
		tk_messageBox -message $info -title "Design Info"
		dbg::exitFn $prevFn
	}

	proc instInfo {inst} {
		set prevFn [dbg::enterFn instInfo]
		set val [dict get $nl::insts $inst]
		set ins [dict get $val numInputs]
		set outs [dict get $val numOutputs]
		set rgn [dict get $val region]
		if { "" == $rgn } {
			set info "$inst\nInputs: $ins\nOutputs: $outs\nRegion assignment: None"
		} else {
			set info "$inst\nInputs: $ins\nOutputs: $outs\nRegion assignment: $rgn"
		}
		tk_messageBox -message $info -title "Instance Info"
		dbg::exitFn $prevFn
	}

	proc rgnInfo {rgn} {
		set prevFn [dbg::enterFn rgnInfo]
		set val [dict get $nl::rgns $rgn]
		set insts [dict get $val insts]
		set info ""
		if { 0 < [dict size $insts] } {
			set info "Assigns: [dict size $insts] instances"
			foreach inst [dict keys $insts] {
				set info "$info\n$inst\n"
			}
		}
		set title "$rgn Info"
		tk_messageBox -message $info -title -title
		dbg::exitFn $prevFn
	}

	proc netInfo {net} {
		set prevFn [dbg::enterFn netInfo]
		set info ""
		set val [dict get $nl::nets $net]
		set name [dict get $val name]
		if { "" != $name } {
			set info "name: $name\n"
		}
		set from [dict get $val from]
		set to [dict get $val to]
		set fromInst [string range $from 0 [expr ([string last . $from]) - 1]]
		set toInst [string range $to 0 [expr ([string last . $to]) - 1]]
		set fromPin [string range $from [expr ([string last . $from]) + 1] [string length $from]]
		set toPin [string range $to [expr ([string last . $to]) + 1] [string length $to]]
		set info "$info from: $fromInst.pin$fromPin to $toInst.pin$toPin\n"
		set fromRgn [dict get $nl::insts $fromInst region]
		if { "" != $fromRgn } {
			set info "$info from region $fromRgn"
		} else {
			set info "$info from chip"
		}
		set toRgn [dict get $nl::insts $toInst region]
		if { "" != $toRgn } {
			set info "$info to region $toRgn\n"
		} else {
			set info "$info to chip"
		}
		tk_messageBox -message $info -title "Net Info"
		dbg::exitFn $prevFn
	}

	proc unselectInst {} {
		set prevFn [dbg::enterFn unselectInst]
		set GUI::selectedInst ""
		set GUI::mode 0
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc unselectRgn {} {
		set prevFn [dbg::enterFn unselectRgn]
		set GUI::selectedRgn ""
		set GUI::mode 0
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc unselectNet {} {
		set prevFn [dbg::enterFn unselectNet]
		set GUI::selectedNet ""
		set GUI::mode 0
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc assignInstToRgn {inst rgn x y {considerGeometry true} } {
		set prevFn [dbg::enterFn assignInstToRgn]
		dbg::msg "GUI assignInst - $inst $rgn $x $y"
		nl::assignInstToRgn $inst $rgn $x $y $considerGeometry
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc error {msg} {
		set prevFn [dbg::enterFn error]
		bell
		set GUI::status $msg
		tk_messageBox -message $msg -title "Error"
		dbg::exitFn $prevFn
	}

	proc pickInstForDnD { x y } {
		set prevFn [dbg::enterFn pickInstForDnD]
		global oldx oldy
		$GUI::cnvs raise current
		dbg::msg "x is $x y is $y"
		set x [$GUI::cnvs canvasx $x]
		set y [$GUI::cnvs canvasy $y]
		dbg::msg "canvasx is $x canvasy is $y"
		set instName GUI::findInst x y
		if { "" != $instName } {
			# We are set for Drag and Drop
		}
		set canvas($can,obj) [ $can find closest $x $y ]
		set canvas($can,x) $x
		set canvas($can,y) $y
		dbg::exitFn $prevFn
	}

	proc startDnD { w x y } {
		set prevFn [dbg::enterFn startDnD]
		dbg::msg "w is $w x is $x y is $y"
		if {$GUI::splashOver} {
			set GUI::dndOldX $x
			set GUI::dndOldY $y
			set GUI::dndStartX $x
			set GUI::dndStartY $y
			set GUI::dndInstName [GUI::findInst $x $y]
			if { "" != $GUI::dndInstName } {
				# We are set for Drag and Drop
				$w raise $GUI::dndInstName
				update idletasks
				#$w itemconfigure $GUI::dndInstName -outline red
			}
		} else {
			GUI::killSplash $w
		}
		dbg::exitFn $prevFn
	}

	proc DnD { w x y } {
		set prevFn [dbg::enterFn DnD]
		dbg::msg "w is $w x is $x y is $y dndInstName is $GUI::dndInstName"
		if { "" != $GUI::dndInstName } {
			$w move $GUI::dndInstName [expr $x-$GUI::dndOldX] [expr $y-$GUI::dndOldY]
			update idletasks
			set GUI::dndOldX $x
			set GUI::dndOldY $y
		}
		dbg::exitFn $prevFn
	}

	proc endDnD { w x y } {
		set prevFn [dbg::enterFn endDnD]
		dbg::msg "w is $w x is $x y is $y dndInstName is $GUI::dndInstName"
		if { "" != $GUI::dndInstName } {
			#$w itemconfigure $GUI::dndInstName -outline darkgreen
			#dict set $nl::insts $dndInstName x [expr $oldX + $x - $GUI::dndStartX]
			#dict set $nl::insts $dndInstName y [expr $oldX + $x - $GUI::dndStartY]
			set rgn [GUI::findRgn $x $y]
			set inst [dict get $GUI::instRects $GUI::dndInstName]
			set oldX1 [dict get $inst x1]
			set oldY1 [dict get $inst y1]
			set oldX2 [dict get $inst x2]
			set oldY2 [dict get $inst y2]
			set nX1 [expr $oldX1 + $x - $GUI::dndStartX]
			set nY1 [expr $oldY1 + $y - $GUI::dndStartY]
			set nX2 [expr $oldX2 + $x - $GUI::dndStartX]
			set nY2 [expr $oldY2 + $y - $GUI::dndStartY]
			dict set $GUI::instRects inst x1 $nX1
			dict set $GUI::instRects inst y1 $nY1
			dict set $GUI::instRects inst x2 $nX2
			dict set $GUI::instRects inst y2 $nY2
			if { "" != $rgn } {
				set newX [getChipX $nX1]
				set newY [getChipY $nY1]
				dbg::msg "inst was at $oldX1 $oldY1, to be moved to $nX1 $nY1, chip is $newX $newY"
				dbg::msg "endDnd assignInst - $GUI::dndInstName $rgn $newX $newY"
				GUI::assignInstToRgn $GUI::dndInstName $rgn $newX $newY
			} else {
				GUI::drawSchematic
			}
		}
		GUI::selectObj $w $x $y
		dbg::exitFn $prevFn
	}

	proc drawFF {x y} {
		set prevFn [dbg::enterFn drawFF]
		set ffWidth 75
		set ffHeight 100
		set ffOffset 5
		set x2 [expr $x+$ffWidth]
		set y2 [expr $y+$ffHeight]
		dbg::msg "$x $y $x2 $y2"
# FF Rect
		$GUI::cnvs create rectangle $x $y $x2 $y2 -tag ff
# Clk conn
		set clkx2 [expr ($x+$x2)/2]
		set clkx1 [expr $clkx2 - $ffOffset]
		set clkx3 [expr $clkx2 + $ffOffset]
		set clky2 [expr $y2 - (2*$ffOffset)]
		$GUI::cnvs create line $clkx1 $y2 $clkx2 $clky2 -tag ff
		$GUI::cnvs create line $clkx2 $clky2 $clkx3 $y2 -tag ff
# Labels - S(et), R(eset), Q, Qbar
		set lx1 [expr $x + (2*$ffOffset)]
		set ly1 [expr $y + (2*$ffOffset)]
		set lx2 [expr $x2 - (2*$ffOffset)]
		set ly2 [expr $y2 - (2*$ffOffset)]
		$GUI::cnvs create text $lx1 $ly1 -text "S" -tag ff
		$GUI::cnvs create text $lx1 $ly2 -text "R" -tag ff
		$GUI::cnvs create text $lx2 $ly1 -text "Q" -tag ff
		$GUI::cnvs create text $lx2 $ly2 -text "Q'" -tag ff

		dbg::exitFn $prevFn
	}

	proc drawPort {portName} {
	}

	proc setPinDisplay {v} {
		set prevFn [dbg::enterFn setPinDisplay]
		set GUI::pinDisplay $v
		dbg::msg "v is $v pindisplay is $GUI::pinDisplay"
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc goIntoRgn {rgnName} {
		set prevFn [dbg::enterFn goIntoRgn]
		set rgn [dict get $nl::rgns $rgnName]
		set GUI::vpX [dict get $rgn x]
		set GUI::vpY [dict get $rgn y]
		set GUI::vpWidth [dict get $rgn width]
		set GUI::vpHeight [dict get $rgn height]
		set GUI::vpMinWidth [expr $GUI::vpWidth / 16 ]
		set GUI::vpMinHeight [expr $GUI::vpHeight / 16 ]
		GUI::drawSchematic
		dbg::exitFn $prevFn
	}

	proc rgnFlylines {rgnName} {
		set prevFn [dbg::enterFn rgnFlylines]
		if {! [dict exists $GUI::rgnRects $rgnName] } {
			return
		}
		set rgn [dict get $GUI::rgnRects $rgnName]
		setSelectRgn rgnName
		set x1 [dict get $rgn x1]
		set y1 [dict get $rgn y1]
		set x2 [dict get $rgn x2]
		set y2 [dict get $rgn y2]
		set lw 5
		set color red
		set item [$GUI::cnvs create rectangle $x1 $y1 $x2 $y2 -width $lw -dash {2 4} -outline $color -fill white -tag rgnflyline -tag $rgnName]
		set nlrgn [dict get $nl::rgns $rgnName]
		set insts [dict get $nlrgn insts]
		set tooltipText "$rgnName:"
		if { 0 < [dict size $insts] } {
			set tooltipText "$tooltipText: [dict size $insts] instances: "
			foreach inst [dict keys $insts] {
				set tooltipText "$tooltipText,$inst"
			}
		}
		tooltip::tooltip $GUI::cnvs -item $item $tooltipText
		set xstr [expr ($x1 + $x2)/2]
		set ystr [expr ($y1 + $y2) /2]
		dbg::msg "$xstr $ystr box is $x1 $y1 $x2 $y2 txt is $rgnName"
		$GUI::cnvs create text $xstr $ystr -text $rgnName -fill blue -tag rgn -tag rgnflyline -tag $rgnName -tag text
		dbg::exitFn $prevFn
	}
}

