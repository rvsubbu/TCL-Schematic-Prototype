#!/usr/local/bin/wish

# All code (c)2013 R.V. Subramanyan All rights reserved.
# Developer: RV (rv@gmail.com)
# UI look and feel - windows, menus, scrollbars etc.

package require Tk
package require Tktable
package require tooltip
package require struct

# This shows up as the window title
wm title . "TK GUI Prototype for Synopsys"
bind . <Control-KeyPress-c> { exit }
bind . "<Key F1>" {GUI::showAbout}
bind . "<Command-f>" {GUI::openDesign}
bind . "<Command-s>" {GUI::saveDesign}
bind . "<Command-x>" {GUI::clearDesign}
bind . "<Command-q>" {exit}

# Frame is the container widget for the UI
pack [ttk::frame .f] -anchor nw -expand 1 -fill both

# Canvas with vertical & horizontal scrollbars.
# Purpose: To draw the schematic
# Empty label widget at the intersection of the scrollbars for grid layout
# Alternative is to just set one of the scrollbars to 2 rows (cols) wide
set GUI::cnvs [tk::canvas .f.cnvs -width 1000 -heigh 500 -bg white]
set GUI::vsb [ttk::scrollbar .f.vsb -orient vertical -command GUI::vertScroll]
set GUI::hsb [ttk::scrollbar .f.hsb -orient horizontal -command GUI::horizScroll]
ttk::label .f.corner
grid .f.cnvs .f.vsb -sticky news
grid .f.hsb .f.corner -sticky news
# Event bindings
# Todo: Difficulties in binding the usual Command-minus and Command-plus
#		keys to zoom, hence bound upper and lower case Z to zoom.
# Todo: What does unit mean in the context of scroll event?
#bind $GUI::cnvs "<Command-Key-minus>" { GUI::zoomOut %W}
#bind $GUI::cnvs "<Command-Key-plus>" { GUI::zoomIn %W}
bind $GUI::cnvs <Configure> {GUI::calcCnvsDims %W}
#bind $GUI::cnvs <1> {GUI::selectObj %W %x %y}
bind $GUI::cnvs <ButtonPress-1> {GUI::startDnD %W %x %y}
bind $GUI::cnvs <ButtonRelease-1> {GUI::endDnD %W %x %y}
bind $GUI::cnvs <B1-Motion> {GUI::DnD %W %x %y}
bind $GUI::cnvs <Double-1> {GUI::filterConns %W %x %y}
bind $GUI::cnvs "<Key Z>" { GUI::zoomOut %W}
bind $GUI::cnvs "<Key z>" { GUI::zoomIn %W}
bind $GUI::cnvs "<Key Escape>" { GUI::clearSelection %W}
bind $GUI::cnvs "<Key Return>" { GUI::killSplash %W}
bind $GUI::cnvs "<Key Down>" { GUI::vertScroll scroll 1 unit}
bind $GUI::cnvs "<Key Up>" { GUI::vertScroll scroll -1 unit}
bind $GUI::cnvs "<Key Left>" { GUI::horizScroll scroll -1 unit}
bind $GUI::cnvs "<Key Right>" { GUI::horizScroll scroll 1 unit}

# Command window
# Purpose: user can type commands to create/select inst/rgn etc.
set GUI::cmdWdgt [ttk::entry .f.cmd -textvariable GUI::cmd]
grid .f.cmd -columnspan 2 -sticky news
# A button makes the look ugly, so I commented this out.
# Instead when the user presses return key, execute the command
#ttk::button .f.go -text "Go" -command GUI::execCmd
#grid .f.cmd .f.go -sticky news
bind .f.cmd <Return> { GUI::execCmd }

# Status window.
# Purpose: Display status messages, if any.
set GUI::statusWdgt [ttk::label .f.status -textvariable GUI::status]
grid .f.status -columnspan 2 -sticky news

# Menubar
menu .menubar
. configure -menu .menubar
# File menu
# Todo: Should Clear Design go to "Edit menu"?
# Todo: Why doesn't the accelerator for Quit show up?
set File [menu .menubar.file]
.menubar add cascade -label File -menu .menubar.file
$File add command -label "Open..." -accelerator "Command-O" -underline 0 -command GUI::openDesign
$File add command -label "Save..." -accelerator "Command-S" -underline 0 -command GUI::saveDesign
$File add command -label "Clear Design" -accelerator "Command-X" -underline 0 -command GUI::clearDesign
$File add command -label "Quit SynProto" -accelerator "Command-Q" -underline 0 -command exit
# Help menu
# Todo: How do I avoid the mac's default Help item coming up?
set Help [menu .menubar.help]
.menubar add cascade -label Help -menu .menubar.help
$Help add command -label "About SynProto..." -accelerator "F1" -underline 0 -command GUI::showAbout

# Grid to resize the canvas and nothing else 
grid rowconfigure .f 0 -weight 1
grid rowconfigure .f 1 -weight 0
grid rowconfigure .f 2 -weight 0
grid rowconfigure .f 3 -weight 0
grid columnconfigure .f 0 -weight 1
grid columnconfigure .f 1 -weight 0

# Force focus to canvas widget, otherwise events seem to go to toplevel.
focus $GUI::cnvs

