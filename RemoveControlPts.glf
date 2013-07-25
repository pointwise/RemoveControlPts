#
# Copyright 2012 (c) Pointwise, Inc.
# All rights reserved.
#
# This sample Pointwise script is not supported by Pointwise, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#

################################################################################
# Remove control points from connector curves
################################################################################

package require PWI_Glyph 2
pw::Script loadTk

###
# utility function to squeeze branch segments down to avoid having connector
# points become unconstrained
###

proc squeezeBranchSegments { con } {
  if { [$con getSegmentCount] < 2 } return

  set numsegs [$con getSegmentCount]
  for { set i 1 } { $i <= $numsegs } { } {
    # look for branch segments separating surface segments
    set seg1 [$con getSegment $i]
    set segb {}
    set seg2 {}
    if [$seg1 isOfType pw::SegmentSurfaceSpline] {
      incr i
      if { $i <= $numsegs } {
        set segb [$con getSegment $i]
        if { [$segb isOfType pw::SegmentSpline] && \
             [$segb getPointCount] == 2 } {
          incr i
          if { $i <= $numsegs } {
            set seg2 [$con getSegment $i]
          }
        }
      }
    } else {
      incr i
    }

    if { $seg2 != "" } {
      # slide the ends of the db segments as close to the edge as possible
      set cp1 [$segb getPoint 1]
      set cp2 [$segb getPoint 2]

      set db1 [$seg1 getSurface]
      set db2 [$seg2 getSurface]

      set dir [pwu::Vector3 subtract [pw::Application getXYZ $cp2] \
        [pw::Application getXYZ $cp1]]

      set cp1i [$db1 closestPoint [$db2 closestPoint $cp1 $dir]]
      set cp2i [$db2 closestPoint [$db1 closestPoint $cp2 $dir]]

      $seg1 setPoint [$seg1 getPointCount] $cp1i
      $segb setPoint 1 [pw::Application getXYZ $cp1i]
      $segb setPoint 2 [pw::Application getXYZ $cp2i]
      $seg2 setPoint 1 $cp2i
    }
  }
}

###
# simplify connector spline segments by removing interior control points
###

proc doSimplify { cons } {
  set modify [pw::Application begin Modify $cons]

  if [catch {
      foreach con $cons {
        # since removal of control points will probably change the
        # underlying curve parameterization, we want to prevent grid
        # points that are on database segments from moving onto non-database
        # segments

        squeezeBranchSegments $con

        set numsegs [$con getSegmentCount]
        set newsegs [list]
        for { set i 1 } { $i <= $numsegs } { incr i } {
          set seg [$con getSegment -copy $i]
          lappend newsegs $seg
          if { [$seg isOfType pw::SegmentSpline] || \
               [$seg isOfType pw::SegmentSurfaceSpline] } {
            if { [$seg getSlope] == "Free" } {
              $seg setSlope CatmullRom
            }
            # remove the interior control points
            while { [$seg getPointCount] > 2 } {
              $seg removePoint 2
            }
          }
        }
        $con replaceAllSegments $newsegs
      }
  } msg] {
    $modify abort
    return -code error $msg
  } else {
    $modify end
  }
  pw::Display update
}

###
# update button state
###

proc updateWidgets { } {
  global cons
  if [llength $cons] {
    .removeButton configure -state normal
  } else {
    .removeButton configure -state disabled
  }
}

###
# pick connectors interactively
###

proc doPickCons { } {
  if [winfo exists .] { wm withdraw .  }

  set mask [pw::Display createSelectionMask -requireConnector {}]
  set add [pw::Display selectEntities -selectionmask $mask \
      -description "Select connector(s) to simplify." picked]

  if [winfo exists .] { wm deiconify .  }

  return $picked(Connectors)
}

###
# create the GUI
###

proc makeWindow { } {
  wm title . "Remove Control Points"

  label .title -text "Remove All Connector Control Points"
  set font [.title cget -font]
  .title configure -font [font create -family [font actual $font -family]]

  frame .hr1 -relief sunken -height 2 -bd 1

  button .pickButton -text "Re-Pick Connectors" -command {
    global cons
    set cons [doPickCons]
    updateWidgets
  }

  button .removeButton -text "Remove Control Points" -command {
    global cons
    if [catch { doSimplify $cons } msg] {
      puts $msg
    }
    set cons [list]
    updateWidgets
  }

  frame .hr2 -relief sunken -height 2 -bd 1
  frame .buttons
  button .buttons.close -text "Close" -command { exit }

  label .buttons.logo -image [pwLogo]
  .buttons.logo configure -bd 0 -relief flat

  pack .title -expand 1 -side top
  pack .hr1 -side top -padx 2 -fill x -pady 2
  pack .pickButton -pady 10
  pack .removeButton -pady 10
  pack .hr2 -side top -padx 2 -fill x -pady 2
  pack .buttons -fill x -padx 2 -pady 1
  pack .buttons.close -side right -padx 2
  pack .buttons.logo -side left -padx 5 -fill y

  bind . <Key-Return> {
    global cons
    doSimplify $cons
    exit
  }

  bind . <KeyPress-Escape> {
    .buttons.close invoke
  }
}

###
# create the Pointwise logo image
###

proc pwLogo {} {
  set logoData "
R0lGODlheAAYAIcAAAAAAAICAgUFBQkJCQwMDBERERUVFRkZGRwcHCEhISYmJisrKy0tLTIyMjQ0
NDk5OT09PUFBQUVFRUpKSk1NTVFRUVRUVFpaWlxcXGBgYGVlZWlpaW1tbXFxcXR0dHp6en5+fgBi
qQNkqQVkqQdnrApmpgpnqgpprA5prBFrrRNtrhZvsBhwrxdxsBlxsSJ2syJ3tCR2siZ5tSh6tix8
ti5+uTF+ujCAuDODvjaDvDuGujiFvT6Fuj2HvTyIvkGKvkWJu0yUv2mQrEOKwEWNwkaPxEiNwUqR
xk6Sw06SxU6Uxk+RyVKTxlCUwFKVxVWUwlWWxlKXyFOVzFWWyFaYyFmYx16bwlmZyVicyF2ayFyb
zF2cyV2cz2GaxGSex2GdymGezGOgzGSgyGWgzmihzWmkz22iymyizGmj0Gqk0m2l0HWqz3asznqn
ynuszXKp0XKq1nWp0Xaq1Hes0Xat1Hmt1Xyt0Huw1Xux2IGBgYWFhYqKio6Ojo6Xn5CQkJWVlZiY
mJycnKCgoKCioqKioqSkpKampqmpqaurq62trbGxsbKysrW1tbi4uLq6ur29vYCu0YixzYOw14G0
1oaz14e114K124O03YWz2Ie12oW13Im10o621Ii22oi23Iy32oq52Y252Y+73ZS51Ze81JC625G7
3JG825K83Je72pW93Zq92Zi/35G+4aC90qG+15bA3ZnA3Z7A2pjA4Z/E4qLA2KDF3qTA2qTE3avF
36zG3rLM3aPF4qfJ5KzJ4LPL5LLM5LTO4rbN5bLR6LTR6LXQ6r3T5L3V6cLCwsTExMbGxsvLy8/P
z9HR0dXV1dbW1tjY2Nra2tzc3N7e3sDW5sHV6cTY6MnZ79De7dTg6dTh69Xi7dbj7tni793m7tXj
8Nbk9tjl9N3m9N/p9eHh4eTk5Obm5ujo6Orq6u3t7e7u7uDp8efs8uXs+Ozv8+3z9vDw8PLy8vL0
9/b29vb5+/f6+/j4+Pn6+/r6+vr6/Pn8/fr8/Pv9/vz8/P7+/gAAACH5BAMAAP8ALAAAAAB4ABgA
AAj/AP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNqZCioo0dC0Q7Sy2btlitisrjpK4io4yF/
yjzKRIZPIDSZOAUVmubxGUF88Aj2K+TxnKKOhfoJdOSxXEF1OXHCi5fnTx5oBgFo3QogwAalAv1V
yyUqFCtVZ2DZceOOIAKtB/pp4Mo1waN/gOjSJXBugFYJBBflIYhsq4F5DLQSmCcwwVZlBZvppQtt
D6M8gUBknQxA879+kXixwtauXbhheFph6dSmnsC3AOLO5TygWV7OAAj8u6A1QEiBEg4PnA2gw7/E
uRn3M7C1WWTcWqHlScahkJ7NkwnE80dqFiVw/Pz5/xMn7MsZLzUsvXoNVy50C7c56y6s1YPNAAAC
CYxXoLdP5IsJtMBWjDwHHTSJ/AENIHsYJMCDD+K31SPymEFLKNeM880xxXxCxhxoUKFJDNv8A5ts
W0EowFYFBFLAizDGmMA//iAnXAdaLaCUIVtFIBCAjP2Do1YNBCnQMwgkqeSSCEjzzyJ/BFJTQfNU
WSU6/Wk1yChjlJKJLcfEgsoaY0ARigxjgKEFJPec6J5WzFQJDwS9xdPQH1sR4k8DWzXijwRbHfKj
YkFO45dWFoCVUTqMMgrNoQD08ckPsaixBRxPKFEDEbEMAYYTSGQRxzpuEueTQBlshc5A6pjj6pQD
wf9DgFYP+MPHVhKQs2Js9gya3EB7cMWBPwL1A8+xyCYLD7EKQSfEF1uMEcsXTiThQhmszBCGC7G0
QAUT1JS61an/pKrVqsBttYxBxDGjzqxd8abVBwMBOZA/xHUmUDQB9OvvvwGYsxBuCNRSxidOwFCH
J5dMgcYJUKjQCwlahDHEL+JqRa65AKD7D6BarVsQM1tpgK9eAjjpa4D3esBVgdFAB4DAzXImiDY5
vCFHESko4cMKSJwAxhgzFLFDHEUYkzEAG6s6EMgAiFzQA4rBIxldExBkr1AcJzBPzNDRnFCKBpTd
gCD/cKKKDFuYQoQVNhhBBSY9TBHCFVW4UMkuSzf/fe7T6h4kyFZ/+BMBXYpoTahB8yiwlSFgdzXA
5JQPIDZCW1FgkDVxgGKCFCywEUQaKNitRA5UXHGFHN30PRDHHkMtNUHzMAcAA/4gwhUCsB63uEF+
bMVB5BVMtFXWBfljBhhgbCFCEyI4EcIRL4ChRgh36LBJPq6j6nS6ISPkslY0wQbAYIr/ahCeWg2f
ufFaIV8QNpeMMAkVlSyRiRNb0DFCFlu4wSlWYaL2mOp13/tY4A7CL63cRQ9aEYBT0seyfsQjHedg
xAG24ofITaBRIGTW2OJ3EH7o4gtfCIETRBAFEYRgC06YAw3CkIqVdK9cCZRdQgCVAKWYwy/FK4i9
3TYQIboE4BmR6wrABBCUmgFAfgXZRxfs4ARPPCEOZJjCHVxABFAA4R3sic2bmIbAv4EvaglJBACu
IxAMAKARBrFXvrhiAX8kEWVNHOETE+IPbzyBCD8oQRZwwIVOyAAXrgkjijRWxo4BLnwIwUcCJvgP
ZShAUfVa3Bz/EpQ70oWJC2mAKDmwEHYAIxhikAQPeOCLdRTEAhGIQKL0IMoGTGMgIBClA9QxkA3U
0hkKgcy9HHEQDcRyAr0ChAWWucwNMIJZ5KilNGvpADtt5JrYzKY2t8nNbnrzm+B8SEAAADs="

  return [image create photo -format GIF -data $logoData]
}

makeWindow
set cons [doPickCons]
updateWidgets
::tk::PlaceWindow . widget


#
# DISCLAIMER:
# TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, POINTWISE DISCLAIMS
# ALL WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED
# TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE, WITH REGARD TO THIS SCRIPT.  TO THE MAXIMUM EXTENT PERMITTED
# BY APPLICABLE LAW, IN NO EVENT SHALL POINTWISE BE LIABLE TO ANY PARTY
# FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES
# WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF
# BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE
# USE OF OR INABILITY TO USE THIS SCRIPT EVEN IF POINTWISE HAS BEEN
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF THE
# FAULT OR NEGLIGENCE OF POINTWISE.
#
