#!/usr/local/bin/wish

set nl::chipWidth 550000
set nl::chipHeight 250000
set i 0
for {set x 50000} {$x < 500000} {incr x 45000} {
	for {set y 30000} {$y < 230000} {incr y 20000} {
		nl::makeInst inst$i -numInputs 50 -numOutputs 50 -x $x -y $y -width 22000 -height 5000
		incr i
		dbg::msg "inst $i at $x $y"
	}
}

#Create some nets
for {set j 0} {$j<[expr $i-1]} {incr j} {
	for {set k 0} {$k<50} {incr k} {
		nl::makeNet -name net{$j}_[expr 50+$k]_[expr $j+1]_$k -from inst$j.[expr 50+$k] -to inst[expr $j+1].$k
	}
}

#Create 5 regions
set x 50000
set y 100000
for {set i 0} {$i<5} {incr i} {
	nl::makeRgn rgn$i -x $x -y 75000 -width 75000 -height 150000
	set x [expr $x + 100000]
}

set x 17500
set x 11000
for {set i 0} {$i<5} {incr i} {
	set y 76000
	for {set j $i} {$j<100} {incr j 10} {
		#GUI::assignInstToRgn inst$j rgn$i $x $y
		set y [expr $y + 1500]
	}
	set x [expr $x + 8000]
}

