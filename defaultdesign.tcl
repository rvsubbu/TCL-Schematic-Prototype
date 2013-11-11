#set nl::chipWidth 40000
#set nl::chipHeight 20000

set x 100
set y 100

#Create some insts
for {set i 0} {$i<10} {incr i} {
	nl::makeInst inst$i -numInputs 50 -numOutputs 50 -x $x -y $y -width 2000 -height 1000
	set x [expr $x + 4000]
	set y [expr $y + 2000]
}

#Create some nets
for {set i 0} {$i<9} {incr i} {
	for {set j 0} {$j<50} {incr j} {
		nl::makeNet -name net{$i}_[expr 50+$j]_[expr $i+1]_$j -from inst$i.[expr 50+$j] -to inst[expr $i+1].$j
	}
}
#nl::makeNet -name feedback -from inst2.50 -to inst1.0

#Create some regions
set x 1000
set y 7500
for {set i 0} {$i<5} {incr i} {
	nl::makeRgn rgn$i -x $x -y $y -width 3000 -height 6000
	set x [expr $x + 8000]
}

dbg::msg "numInsts is $nl::instId [dict values $nl::insts]\n"
dbg::msg "numRegions is $nl::rgnId[dict values $nl::rgns]\n"
dbg::msg "numNets is $nl::netId [dict values $nl::nets]\n"

#GUI::showInstConns inst5
#GUI::calcWinDimensions $GUI::cnvs

