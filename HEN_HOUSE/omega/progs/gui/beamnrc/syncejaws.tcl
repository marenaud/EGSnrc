
###############################################################################
#
#  EGSnrc BEAMnrc graphical user interface: SYNCEJAWS
#  Copyright (C) 2015 National Research Council Canada
#
#  This file is part of EGSnrc.
#
#  EGSnrc is free software: you can redistribute it and/or modify it under
#  the terms of the GNU Affero General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
#
#  EGSnrc is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for
#  more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with EGSnrc. If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################
#
#  Author:          Marc-Andre Renaud, 2018
#
#  Blatantly copied from SYNCJAWS (Tony Popescu, Julio Lobo)
#
#
###############################################################################
#
#  The contributors named above are only those who could be identified from
#  this file's revision history.
#
#  This code is part of the BEAMnrc code system for Monte Carlo simulation of
#  radiotherapy treatments units. BEAM was originally developed at the
#  National Research Council of Canada as part of the OMEGA collaborative
#  research project with the University of Wisconsin, and was originally
#  described in:
#
#  BEAM: A Monte Carlo code to simulate radiotherapy treatment units,
#  DWO Rogers, BA Faddegon, GX Ding, C-M Ma, J Wei and TR Mackie,
#  Medical Physics 22, 503-524 (1995).
#
#  BEAM User Manual
#  DWO Rogers, C-M Ma, B Walters, GX Ding, D Sheikh-Bagheri and G Zhang,
#  NRC Report PIRS-509A (rev D)
#
#  As well as the authors of this paper and report, Joanne Treurniet of NRC
#  made significant contributions to the code system, in particular the GUIs
#  and EGS_Windows. Mark Holmes, Brian Geiser and Paul Reckwerdt of Wisconsin
#  played important roles in the overall OMEGA project within which the BEAM
#  code system was developed.
#
#  There have been major upgrades in the BEAM code starting in 2000 which
#  have been heavily supported by Iwan Kawrakow, most notably: the port to
#  EGSnrc, the inclusion of history-by-history statistics and the development
#  of the directional bremsstrahlung splitting variance reduction technique.
#
###############################################################################


proc init_SYNCEJAWS { id } {
    global cmval sync_file

    for {set i 0} {$i<3} {incr i} {
        set cmval($id,$i) {}
    }
    for {set i 1} {$i<=20} {incr i} {
        set cmval($id,3,$i) {}
        for {set j 0} {$j<6} {incr j} {
            set cmval($id,4,$j,$i) {}
        }
    }
    for {set i 0} {$i<4} {incr i} {
	    set cmval($id,5,$i) {}
    }
    for {set i 1} {$i<=20} {incr i} {
        for {set j 0} {$j<4} {incr j} {
            set cmval($id,6,$j,$i) {}
        }
	    set cmval($id,7,$i) {}
    }
    set sync_file($id) {}
}

proc read_SYNCEJAWS { fileid id } {
    global cmval GUI_DIR cm_ident sync_file

    # read a trash line
    gets $fileid data

    # if $data doesn't start with *, it's not a BEAM comment line and there's
    # something wrong with the file.  Later, let it search for a line
    # beginning with * and start reading again from there.
    set data [string trimleft $data]
    if [string compare [string range $data 0 0] "*"]!=0 {
	tk_dialog .error "Read Error" "Error in the input file when starting\
		to read SYNCEJAWS $cm_ident($id).  The inputs don't begin where\
		they should.  There is either an error in the CM preceding\
		this, or the accelerator module file is not the correct one\
		for use with this input file." error 0 OK
	return -code break
	# breaks out of the loops this procedure was called from.
    }

    # read rmax 0
    gets $fileid data
    set data [get_val $data cmval $id,0]

    # read title 1
    gets $fileid data
    set cmval($id,1) $data

    # read number of paired jaws 2,0 and mode of dynamic opening 2,1
    gets $fileid data
    for {set j 0} {$j<2} {incr j} {
       set data [get_val $data cmval $id,2,$j]
    }

    # read stuff for each pair
    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
        gets $fileid data

        # X or Y orientation:
        set indx [string first , $data]
        if { $indx<1 } { set indx [string length $data] }
        set cmval($id,3,$i) [string range $data 0 [incr indx -1] ]

        # Make sure it's upper case:
        if [string compare $cmval($id,3,$i) x]==0 { set cmval($id,3,$i) X }
        if [string compare $cmval($id,3,$i) y]==0 { set cmval($id,3,$i) Y }

        # Read zzrad, rad
        gets $fileid data
        for {set j 0} {$j<2} {incr j} {
            set data [get_val $data cmval $id,4,$j,$i]
        }

        if {"$cmval($id,2,1)"!="1" && "$cmval($id,2,1)"!="2"} {
            #static mode, read jaw settings
            # Read zmin, zmax, xn, xp
            gets $fileid data
            for {set j 2} {$j<6} {incr j} {
                set data [get_val $data cmval $id,4,$j,$i]
            }
        }
    }
    if {"$cmval($id,2,1)"=="1" || "$cmval($id,2,1)"=="2"} {
        gets $fileid sync_file($id)
        #now, if possible read the jaw settings for the first field
        #this is really only necessary to have a definition of zmax for preview_accel
        if { [file readable $sync_file($id)] } {
            set jaws_fileid [open $sync_file($id) "r"]
            #first three lines are title, no. of fields and index of first field
            gets $jaws_fileid data
            gets $jaws_fileid data
            gets $jaws_fileid data
            for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
                gets $jaws_fileid data
                for {set j 2} {$j<6} {incr j} {
                    set data [get_val $data cmval $id,4,$j,$i]
                }
            }
        }
    }
    gets $fileid data
    for {set j 0} {$j<4} {incr j} {
	set data [get_val $data cmval $id,5,$j]
    }
    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
	gets $fileid data
	for {set j 0} {$j<4} {incr j} {
	    set data [get_val $data cmval $id,6,$j,$i]
	}
	gets $fileid data
	set data [get_str $data cmval $id,7,$i]
    }
}

proc edit_SYNCEJAWS { id zmax } {
    global cmval GUI_DIR omega helvfont help_syncejaws_text values sync_file inp_file_dir

    catch { destroy .syncejaws$id }
    toplevel .syncejaws$id
    wm title .syncejaws$id "Edit SYNCEJAWS, CM\#$id"
    # MAIN WINDOW - PUT ON THE MAIN STUFF; A >> BUTTON BY NJAWS.
    frame .syncejaws$id.frm -bd 4
    set top .syncejaws$id.frm

    label $top.mainlabel -text "SYNCEJAWS" -font $helvfont
    pack $top.mainlabel -pady 10

    #JAWS_macros.mortran:REPLACE {$MAX_N_$JAWS} WITH {10}
    get_1_default SYNCEJAWS $top "maximum number of paired bars or jaws"

    label $top.zmax -text $zmax -font $helvfont
    pack $top.zmax -pady 5

    add_rmax_square $top.inp0 $id,0
    add_title $top.inp1 $id,1

    frame $top.inp3 -bd 4
    label $top.inp3.label -text {Number of paired bars}
    entry $top.inp3.inp -textvariable cmval($id,2,0) -width 8
    frame $top.inp3.fieldtype
    label $top.inp3.fieldtype.label -text {Select field type:}
    radiobutton $top.inp3.fieldtype.r1 -text "Static" -variable cmval($id,2,1) -value 0 \
         -command "$top.inp3.leafdef.filespec.fname configure -state disabled;\
                   $top.inp3.leafdef.filespec.browse configure -state disabled;\
                   $top.inp3.leafdef.nextproc configure \
                     -text {Define jaw orientation/openings/media};\
                   $top.inp3.leafdef.label configure -fg grey"
    radiobutton $top.inp3.fieldtype.r2 -text "Dynamic"\
         -variable cmval($id,2,1) -value 1 \
         -command "$top.inp3.leafdef.filespec.fname configure -state normal;\
                   $top.inp3.leafdef.filespec.browse configure -state normal;\
                   $top.inp3.leafdef.nextproc configure \
                     -text {Define jaw orientation/media};\
                   $top.inp3.leafdef.label configure -fg black"
    radiobutton $top.inp3.fieldtype.r3 -text "Step-and-shoot"\
         -variable cmval($id,2,1) -value 2 \
         -command "$top.inp3.leafdef.filespec.fname configure -state normal;\
                   $top.inp3.leafdef.filespec.browse configure -state normal;\
                   $top.inp3.leafdef.nextproc configure \
                     -text {Define jaw orientation/media};\
                   $top.inp3.leafdef.label configure -fg black"
    pack $top.inp3.fieldtype.label $top.inp3.fieldtype.r1 \
        $top.inp3.fieldtype.r2 $top.inp3.fieldtype.r3 -side top -anchor w
    frame $top.inp3.leafdef
    if {"$cmval($id,2,1)" == "1" || "$cmval($id,2,1)" == "2"} {
        button $top.inp3.leafdef.nextproc -text "Define jaw orientation/media"\
	    -command "define_syncejaws $id"
    } else {
        button $top.inp3.leafdef.nextproc -text "Define jaw orientation/openings/media"\
            -command "define_syncejaws $id"
    }
    label $top.inp3.leafdef.label -text {File containing jaw opening data:}
    frame $top.inp3.leafdef.filespec
    entry $top.inp3.leafdef.filespec.fname -textvariable sync_file($id) -width 20
    button $top.inp3.leafdef.filespec.browse -text "Browse"\
         -command "browse set_syncfile $inp_file_dir $id"
    pack $top.inp3.leafdef.filespec.fname $top.inp3.leafdef.filespec.browse \
         -side left
    pack $top.inp3.leafdef.nextproc $top.inp3.leafdef.label \
         $top.inp3.leafdef.filespec -side top -anchor w -pady 5
    pack $top.inp3.label -anchor w -side left
    pack $top.inp3.inp -side left -padx 5
    pack $top.inp3.fieldtype -side left
    pack $top.inp3.leafdef -anchor e -side right -fill x -expand true -padx 5
    pack $top.inp3 -side top -fill x

    label $top.airlabel -text "Openings:" -font $helvfont
    pack $top.airlabel -anchor w -pady 10

    add_ecut $top.inp4 $id,5,0
    add_pcut $top.inp5 $id,5,1
    add_dose $top.inp6 $id,5,2
    add_latch $top.inp7 $id,5,3

    frame $top.buts -bd 4
    button $top.buts.okb -text "OK" -command "destroy .syncejaws$id"\
	    -relief groove -bd 8
    button $top.buts.helpb -text "Help" -command \
	    "help_gif .syncejaws$id.help {$help_syncejaws_text} help_jaws"\
	    -relief groove -bd 8
    button $top.buts.prev -text "Preview" -command \
	    "show_SYNCEJAWS $id" -relief groove -bd 8
    pack $top.buts.helpb $top.buts.okb $top.buts.prev -padx 10 -side left
    pack $top.buts -pady 5
    pack $top
}

proc define_syncejaws { id } {
    global cmval helvfont values help_syncejaws_text nmed medium med_per_column

    catch { destroy .syncejaws$id.child }
    toplevel .syncejaws$id.child
    set top .syncejaws$id.child
    wm title $top "Define dynamic jaws"

    frame $top.f -bd 10
    set w $top.f

    label $w.lo -text "Orientation"
    label $w.l0 -text "Distance from front of jaw to center of radius(cm)"
    label $w.l1 -text "Radius of curvature of the rounded ends (cm)"
    label $w.l2 -text "Distance from front of jaw to reference plane (cm)"
    label $w.l3 -text "Distance from back of jaw to reference plane (cm)"
    label $w.l4 -text "x/y coordinate of center of radius for negative jaw (cm)"
    label $w.l5 -text "x/y coordinate of center of radius for positive jaw (cm)"
    label $w.l6 -text "Electron cutoff (default ECUTIN) (MeV)"
    label $w.l7 -text "Photon cutoff (default PCUTIN) (MeV)"
    label $w.l8 -text "Dose zone (0 for no scoring)"
    label $w.l9 -text "Associate with LATCH bit"
    label $w.l10 -text "Material"

    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
        menubutton $w.xy$i -text $cmval($id,3,$i) -menu $w.xy$i.m -bd 1 \
            -relief raised -indicatoron 0 -width 20
        menu $w.xy$i.m -tearoff no
        $w.xy$i.m add command -label X \
            -command "set cmval($id,3,$i) X; \
            $w.xy$i configure -text X"
        $w.xy$i.m add command -label Y \
            -command "set cmval($id,3,$i) Y; \
            $w.xy$i configure -text Y"
        for {set j 0} {$j<6} {incr j} {
            set indx [expr $j+1]
            entry $w.e$i-$indx -textvariable cmval($id,4,$j,$i)
        }
        for {set j 0} {$j<4} {incr j} {
            set indx [expr $j+7]
            if $j==0 {
                if [string compare $cmval($id,6,0,$i) ""]==0 {
                    set cmval($id,6,0,$i) $values(ecut)
                }
            } elseif $j==1 {
                if [string compare $cmval($id,6,1,$i) ""]==0 {
                    set cmval($id,6,1,$i) $values(pcut)
                }
            }
            entry $w.e$i-$indx -textvariable cmval($id,6,$j,$i) -width 20
        }
    	set indx 11
        # material option menu
        menubutton $w.e$i-11 -text $cmval($id,7,$i) -menu \
            $w.e$i-11.m -bd 1 -relief raised -indicatoron 0 -width 20
        menu $w.e$i-11.m -tearoff no
        for {set iopt 0} {$iopt <= $nmed} {incr iopt} {
            $w.e$i-11.m add command -label $medium($iopt) \
                -command "set_grid_material $w.e$i-11 $iopt $id,7,$i" -columnbreak [expr $iopt % $med_per_column==0]
        }
    }

    grid configure $w.lo -row 0 -column 1 -sticky w
    if {"$cmval($id,2,1)"=="1" || "$cmval($id,2,1)"=="2"} {
        set istart 6
    } else { set istart 0 }
    for {set i $istart} {$i<11} {incr i} {
	    grid configure $w.l$i -row [expr $i-$istart+1] -column 1 -sticky w
    }
    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
	    grid configure $w.xy$i -row 0 -column [expr $i+1]
    }
    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
        for {set j [expr $istart+1]} {$j<12} {incr j} {
            grid configure $w.e$i-$j -row [expr $j-$istart] -column [expr $i+1]
        }
    }
    pack $w
    frame $top.b
    button $top.b.okb -text "OK" -command "destroy .syncejaws$id.child"\
	    -relief groove -bd 8
    button $top.b.helpb -text "Help" -command\
	    "help_gif .syncejaws$id.child.help {$help_syncejaws_text} help_jaws"\
	    -relief groove -bd 8
    pack $top.b.helpb $top.b.okb -side left -padx 10
    pack $top.b -pady 5
}


proc write_SYNCEJAWS {fileid id} {
    global cmval cm_names cm_ident cm_type sync_file

    puts $fileid "$cmval($id,0), RMAX"
    puts $fileid $cmval($id,1)
    puts $fileid "$cmval($id,2,0), $cmval($id,2,1), # PAIRED BARS OR JAWS, field type"

    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
	    puts $fileid $cmval($id,3,$i)
        set str {}
        for {set j 0} {$j<2} {incr j} {
            set str "$str$cmval($id,4,$j,$i), "
        }
        puts $fileid $str
        if {"$cmval($id,2,1)"!="1" && "$cmval($id,2,1)"!="2"} {
            set str {}
            for {set j 2} {$j<6} {incr j} {
                set str "$str$cmval($id,4,$j,$i), "
            }
            puts $fileid $str
        }
    }
    if {"$cmval($id,2,1)"=="1" || "$cmval($id,2,1)"=="2"} {
        puts $fileid $sync_file($id)
    }
    set str {}
    for {set i 0} {$i<4} {incr i} {
    	set str "$str$cmval($id,5,$i), "
    }
    puts $fileid $str
    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
        set str {}
        for {set k 0} {$k<4} {incr k} {
            set str "$str$cmval($id,6,$k,$i), "
        }
        puts $fileid $str
        puts $fileid $cmval($id,7,$i)
    }
}


proc show_SYNCEJAWS { id } {
    global cmval helvfont medium nmed xrange yrange zrange med cm_ticks sync_file

    catch { destroy .syncejaws$id.show }
    toplevel .syncejaws$id.show
    wm title .syncejaws$id.show "Preview"

    set cm_ticks($id,x) 6
    set cm_ticks($id,y) 6
    set cm_ticks($id,z) 10

    if {"$cmval($id,2,1)"=="1" || "$cmval($id,2,1)"=="2"} {
        #open up jaws_file and read coordinates for first field
        if { [file readable $sync_file($id)] } {
            set fileid [open $sync_file($id) "r"]
            #first three lines are title, no. of fields and index of first field
            gets $fileid data
            gets $fileid data
            gets $fileid data
            for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
                gets $fileid data
                for {set j 2} {$j<6} {incr j} {
                    set data [get_val $data cmval $id,4,$j,$i]
                }
            }
        } else {
            tk_dialog tk_dialog .syncejaws$id.nojawfile1 "No jaw opening file" "No\
            jaw opening file has been specified or the specified file does not exist\
            or is not readable.  This is required for showing jaw openings in the\
            preview if dynamic or step-and-shoot fields are specified." error 0 OK
            return
        }
    }

    # have to make an initial xrange,zrange:
    catch {
        set xrange(0) -$cmval($id,0)
        set xrange(1) $cmval($id,0)
        set yrange(0) -$cmval($id,0)
        set yrange(1) $cmval($id,0)
        set zrange(0) [get_zmax [expr $id-1]]
        set zrange(1) [get_zmax $id]
    }

    if [catch { draw_SYNCEJAWS $id }]==1 {
	destroy .syncejaws$id.show
	tk_dialog .syncejaws$id.error "Preview error" "There was an error in\
		attempting to display this CM.  Please make sure that\
		all numerical values are defined." error 0 OK
	return
    }

    if {"$cmval($id,2,1)"=="1"} {
      #output a message saying depicted openings are for first field in file
      message .syncejaws$id.show.message -text "NOTE: Jaw openings displayed \
         are for the first field in a series of dynamic fields." -width 500
      pack .syncejaws$id.show.message -side top -pady 5
    } elseif {"$cmval($id,2,1)"=="2"} {
      message .syncejaws$id.show.message -text "NOTE: Jaw openings displayed \
         are for the first field in a series of step-and-shoot fields." -width 500
      pack .syncejaws$id.show.message -side top -pady 5
    }

    frame .syncejaws$id.show.buts
    button .syncejaws$id.show.buts.range -text "Change plot properties" -command\
	    "change_cm_range $id .syncejaws$id.show xyz" -relief groove -bd 8
    button .syncejaws$id.show.buts.print1 -text "Print xz..." -command\
	    "print_canvas .syncejaws$id.show.can.one 450 450" -relief groove -bd 8
    button .syncejaws$id.show.buts.print2 -text "Print yz..." -command\
	    "print_canvas .syncejaws$id.show.can.two 450 450" -relief groove -bd 8
    button .syncejaws$id.show.buts.done -text "Done" -command\
	    "destroy .syncejaws$id.show" -relief groove -bd 8
    pack .syncejaws$id.show.buts.range .syncejaws$id.show.buts.print1\
	    .syncejaws$id.show.buts.print2 .syncejaws$id.show.buts.done\
	    -side left -padx 10
    pack .syncejaws$id.show.buts -side bottom -anchor s -pady 15
}

proc draw_SYNCEJAWS { id } {
    global helvfont zrange yrange xrange zscale yscale xscale l m
    global cm_ticks

    catch { destroy .syncejaws$id.show.can }

    # put the canvas up
    canvas .syncejaws$id.show.can -width 900 -height 400

    # need 2 canvases (canvi?) to show an xz and yz cross-section.
    # let each be 300x300, with 100 on the left of each:
    # |100|300|150|300|50|

    set width 300.0
    set canwidth 450.0
    set xscale [expr $width/double(abs($xrange(1)-$xrange(0)))]
    set yscale [expr $width/double(abs($yrange(1)-$yrange(0)))]
    set zscale [expr $width/double(abs($zrange(1)-$zrange(0)))]

    # left canvas, x/z cross-section
    set l 100.0
    set m 50.0

    canvas .syncejaws$id.show.can.one -width $canwidth -height $canwidth

    add_air $id .syncejaws$id.show.can.one $xrange(0) $zrange(0)\
	    $xscale $zscale $l $m

    add_SYNCEJAWS $id $xscale $zscale $xrange(0) $zrange(0)\
	    $l $m .syncejaws$id.show.can.one

    coverup $l $m $width .syncejaws$id.show.can.one

    set curx 0
    set cury 0
    label .syncejaws$id.show.can.one.xy -text [format "(%6.3f, %6.3f)" $curx $cury]\
	    -bg white -bd 5 -width 16 -font $helvfont
    .syncejaws$id.show.can.one create window [expr $l/2+$width] [expr 2*$m+$width-10]\
	    -window .syncejaws$id.show.can.one.xy
    bind .syncejaws$id.show.can.one <Motion> {
	global l m xscale zscale xrange zrange
	set curx %x
	set cury %y
	set curx [expr ($curx-$l)/$xscale+$xrange(0)]
	set cury [expr ($cury-$m)/$zscale+$zrange(0)]
        if { $curx<=$xrange(1) & $curx>=$xrange(0) & $cury<=$zrange(1) & \
                $cury>=$zrange(0) } {
	    set text [format "(%%6.3f, %%6.3f)" $curx $cury]
	    %W.xy configure -text $text
	}
    }

    add_axes xz $cm_ticks($id,x) $cm_ticks($id,z) $l $m $width $xrange(0)\
	    $xrange(1) $zrange(0) $zrange(1)\
	    $xscale $zscale .syncejaws$id.show.can.one

    .syncejaws$id.show.can create window [expr $canwidth/2.0]\
	    [expr $canwidth/2.0] -window .syncejaws$id.show.can.one

    # right canvas, YZ cross-section

    canvas .syncejaws$id.show.can.two -width $canwidth -height $canwidth

    add_air $id .syncejaws$id.show.can.two $yrange(0) $zrange(0)\
	    $yscale $zscale $l $m

    add_SYNCEJAWS_yz $id $yscale $zscale $yrange(0) $zrange(0)\
	    $l $m .syncejaws$id.show.can.two

    coverup $l $m $width .syncejaws$id.show.can.two

    label .syncejaws$id.show.can.two.xy -text [format "(%6.3f, %6.3f)" $curx $cury]\
	    -bg white -bd 5 -width 16 -font $helvfont
    .syncejaws$id.show.can.two create window [expr $l/2+$width] [expr 2*$m+$width-10]\
	    -window .syncejaws$id.show.can.two.xy
    bind .syncejaws$id.show.can.two <Motion> {
	global l m yscale zscale yrange zrange
	set curx %x
	set cury %y
	set curx [expr ($curx-$l)/$yscale+$yrange(0)]
	set cury [expr ($cury-$m)/$zscale+$zrange(0)]
        if { $curx<=$yrange(1) & $curx>=$yrange(0) & $cury<=$zrange(1) & \
                $cury>=$zrange(0) } {
	    set text [format "(%%6.3f, %%6.3f)" $curx $cury]
	    %W.xy configure -text $text
	}
    }

    add_axes yz $cm_ticks($id,y) $cm_ticks($id,z) $l $m $width $yrange(0)\
	    $yrange(1) $zrange(0) $zrange(1)\
	    $yscale $zscale .syncejaws$id.show.can.two

    .syncejaws$id.show.can create window [expr $canwidth+$canwidth/2.0]\
	    [expr $canwidth/2.0] -window .syncejaws$id.show.can.two

    pack .syncejaws$id.show.can -side top -anchor n
}

proc add_SYNCEJAWS {id xscale zscale xmin zmin l m parent_w} {
    global cmval colorlist nmed medium meds_used values colornum sync_file

    # assign numbers to the media
    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
	set med($i) $colornum
	for {set j 0} {$j<=$nmed} {incr j} {
	    if [string compare $cmval($id,7,$i) $medium($j)]==0 {
		set med($i) [min_nrc $j $colornum]
		set meds_used($j) 1
		break
	    }
	}
    }
    set med(air) $colornum
    for {set j 0} {$j<=$nmed} {incr j} {
	if [string compare $values(2) $medium($j)]==0 {
	    set med(air) [min_nrc $j $colornum]
	    set meds_used($j) 1
	    break
	}
    }

    if {"$cmval($id,2,1)"=="1" || "$cmval($id,2,1)"=="2"} {
       #open up jaws_file and read coordinates for first field
     if { [file readable $sync_file($id)] } {
       set fileid [open $sync_file($id) "r"]
       #first three lines are title, no. of fields and index of first field
       gets $fileid data
       gets $fileid data
       gets $fileid data
       for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
           gets $fileid data
           for {set j 2} {$j<6} {incr j} {
              set data [get_val $data cmval $id,4,$j,$i]
           }
       }
     } else {
       tk_dialog tk_dialog .syncejaws$id.nojawfile1 "No jaw opening file" "No\
    jaw opening file has been specified or the specified file does not exist\
    or is not readable.  This is required for showing jaw openings in the\
    preview if dynamic or step-and-shoot fields are specified." error 0 OK
       return
     }
    }

    # air in background
    set z(1) [expr ($cmval($id,4,0,1)-$zmin)*$zscale+$m]
    set z(2) [expr ($cmval($id,4,1,$cmval($id,2,0))-$zmin)*$zscale+$m]
    set x(1) [expr (-$cmval($id,0)-$xmin)*$xscale+$l]
    set x(2) [expr ($cmval($id,0)-$xmin)*$xscale+$l]
    set color [lindex $colorlist $med(air)]
    $parent_w create rectangle $x(1) $z(1) $x(2) $z(2) -fill $color -outline {}

    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
        if [string compare $cmval($id,3,$i) "X"]==0 {
            set y1 [expr ($cmval($id,4,0,$i)-$zmin)*$zscale+$m]
            set y2 [expr ($cmval($id,4,1,$i)-$zmin)*$zscale+$m]
            set x(xmn) [expr (-$cmval($id,0)-$xmin)*$xscale+$l]
            set x(xmp) [expr ($cmval($id,0)-$xmin)*$xscale+$l]
            set x(xfn) [expr ($cmval($id,4,4,$i)-$xmin + $cmval($id,4,1,$i))*$xscale+$l]
            set x(xfp) [expr ($cmval($id,4,5,$i)-$xmin - $cmval($id,4,1,$i))*$xscale+$l]
            set color [lindex $colorlist $med($i)]
            $parent_w create polygon $x(xfp) $y1 $x(xmp) $y1 $x(xmp) $y2\
                $x(xfp) $y2 -fill $color -outline $color
            $parent_w create polygon $x(xfn) $y1 $x(xfn) $y2 $x(xmn) $y2\
                $x(xmn) $y1 -fill $color -outline $color
        }
    }
}

proc add_SYNCEJAWS_yz {id xscale zscale xmin zmin l m parent_w} {
    global cmval colorlist nmed medium values colornum sync_file

    # assign numbers to the media
    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
	set med($i) $colornum
	for {set j 0} {$j<=$nmed} {incr j} {
	    if [string compare $cmval($id,7,$i) $medium($j)]==0 {
		set med($i) [min_nrc $j $colornum]
		break
	    }
	}
    }
    set med(air) $colornum
    for {set j 0} {$j<=$nmed} {incr j} {
	if [string compare $values(2) $medium($j)]==0 {
	    set med(air) [min_nrc $j $colornum]
	    break
	}
    }

    if {"$cmval($id,2,1)"=="1" || "$cmval($id,2,1)"=="2"} {
       #open up jaws_file and read coordinates for first field
     if { [file readable $sync_file($id)] } {
       set fileid [open $sync_file($id) "r"]
       #first three lines are title, no. of fields and index of first field
       gets $fileid data
       gets $fileid data
       gets $fileid data
       for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
           gets $fileid data
           for {set j 2} {$j<6} {incr j} {
              set data [get_val $data cmval $id,4,$j,$i]
           }
       }
     } else {
       tk_dialog tk_dialog .syncejaws$id.nojawfile2 "No jaw opening file" "No\
    jaw opening file has been specified or the specified file does not exist\
    or is not readable.  This is required for showing jaw openings in the\
    preview if dynamic or step-and-shoot fields are specified." error 0 OK
       return
     }
    }

    # The x's here are really y's...
    # air in background, 2 rectangles
    set z(1) [expr $zmin*$zscale+$m]
    set z(2) [expr (-$cmval($id,4,1,$cmval($id,2,0)))*$zscale+$m]
    set x(1) [expr (-$cmval($id,0)-$xmin)*$xscale+$l]
    set x(2) [expr ($cmval($id,0)-$xmin)*$xscale+$l]
    set color [lindex $colorlist $med(air)]
    $parent_w create rectangle $x(1) $z(1) $x(2) $z(2) -fill $color -outline {}

    for {set i 1} {$i<=$cmval($id,2,0)} {incr i} {
        if [string compare $cmval($id,3,$i) "Y"]==0 {
            set y1 [expr ($cmval($id,4,0,$i)-$zmin)*$zscale+$m]
            set y2 [expr ($cmval($id,4,1,$i)-$zmin)*$zscale+$m]
            set x(xmn) [expr (-$cmval($id,0)-$xmin)*$xscale+$l]
            set x(xmp) [expr ($cmval($id,0)-$xmin)*$xscale+$l]
            set x(xfn) [expr ($cmval($id,4,4,$i)-$xmin + $cmval($id,4,1,$i))*$xscale+$l]
            set x(xfp) [expr ($cmval($id,4,5,$i)-$xmin - $cmval($id,4,1,$i))*$xscale+$l]
            set color [lindex $colorlist $med($i)]
            $parent_w create polygon $x(xfp) $y1 $x(xmp) $y1 $x(xmp) $y2\
                $x(xfp) $y2 -fill $color -outline $color
            $parent_w create polygon $x(xfn) $y1 $x(xfn) $y2 $x(xmn) $y2\
                $x(xmn) $y1 -fill $color -outline $color
        }
    }
}

proc set_jawsfile { } {

# procedure to set file of jaw openings to whatever the user
# selected in the browser

global filename jaws_file

# if nothing was entered, return
    if { [string compare $filename ""]==0 } {
        tk_dialog .query.empty "Empty string" "No filename was entered.  \
                Please try again." error 0 OK
        return
    }
    set jaws_file [file join [pwd] $filename]
}
