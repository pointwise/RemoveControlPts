#############################################################################
#
# (C) 2021 Cadence Design Systems, Inc. All rights reserved worldwide.
#
# This sample script is not supported by Cadence Design Systems, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#
#############################################################################

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

  label .buttons.logo -image [cadenceLogo]
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
# create the Cadence Design Systems logo image
###

proc cadenceLogo {} {
  set logoData "
R0lGODlhgAAYAPQfAI6MjDEtLlFOT8jHx7e2tv39/RYSE/Pz8+Tj46qoqHl3d+vq62ZjY/n4+NT
T0+gXJ/BhbN3d3fzk5vrJzR4aG3Fubz88PVxZWp2cnIOBgiIeH769vtjX2MLBwSMfIP///yH5BA
EAAB8AIf8LeG1wIGRhdGF4bXD/P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIe
nJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtdGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1w
dGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1Nzo
wMSAgICAgICAgIj48cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudy5vcmcvMTk5OS8wMi
8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmY6YWJvdXQ9IiIg/3htbG5zO
nhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0
cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUcGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh
0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0idX
VpZDoxMEJEMkEwOThFODExMUREQTBBQzhBN0JCMEIxNUM4NyB4bXBNTTpEb2N1bWVudElEPSJ4b
XAuZGlkOkIxQjg3MzdFOEI4MTFFQjhEMv81ODVDQTZCRURDQzZBIiB4bXBNTTpJbnN0YW5jZUlE
PSJ4bXAuaWQ6QjFCODczNkZFOEI4MTFFQjhEMjU4NUNBNkJFRENDNkEiIHhtcDpDcmVhdG9yVG9
vbD0iQWRvYmUgSWxsdXN0cmF0b3IgQ0MgMjMuMSAoTWFjaW50b3NoKSI+IDx4bXBNTTpEZXJpZW
RGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6MGE1NjBhMzgtOTJiMi00MjdmLWE4ZmQtM
jQ0NjMzNmNjMWI0IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOjBhNTYwYTM4LTkyYjItNDL/
N2YtYThkLTI0NDYzMzZjYzFiNCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g
6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PgH//v38+/r5+Pf29fTz8vHw7+7t7Ovp6Ofm5e
Tj4uHg397d3Nva2djX1tXU09LR0M/OzczLysnIx8bFxMPCwcC/vr28u7q5uLe2tbSzsrGwr66tr
KuqqainpqWko6KhoJ+enZybmpmYl5aVlJOSkZCPjo2Mi4qJiIeGhYSDgoGAf359fHt6eXh3dnV0
c3JxcG9ubWxramloZ2ZlZGNiYWBfXl1cW1pZWFdWVlVUU1JRUE9OTUxLSklIR0ZFRENCQUA/Pj0
8Ozo5ODc2NTQzMjEwLy4tLCsqKSgnJiUkIyIhIB8eHRwbGhkYFxYVFBMSERAPDg0MCwoJCAcGBQ
QDAgEAACwAAAAAgAAYAAAF/uAnjmQpTk+qqpLpvnAsz3RdFgOQHPa5/q1a4UAs9I7IZCmCISQwx
wlkSqUGaRsDxbBQer+zhKPSIYCVWQ33zG4PMINc+5j1rOf4ZCHRwSDyNXV3gIQ0BYcmBQ0NRjBD
CwuMhgcIPB0Gdl0xigcNMoegoT2KkpsNB40yDQkWGhoUES57Fga1FAyajhm1Bk2Ygy4RF1seCjw
vAwYBy8wBxjOzHq8OMA4CWwEAqS4LAVoUWwMul7wUah7HsheYrxQBHpkwWeAGagGeLg717eDE6S
4HaPUzYMYFBi211FzYRuJAAAp2AggwIM5ElgwJElyzowAGAUwQL7iCB4wEgnoU/hRgIJnhxUlpA
SxY8ADRQMsXDSxAdHetYIlkNDMAqJngxS47GESZ6DSiwDUNHvDd0KkhQJcIEOMlGkbhJlAK/0a8
NLDhUDdX914A+AWAkaJEOg0U/ZCgXgCGHxbAS4lXxketJcbO/aCgZi4SC34dK9CKoouxFT8cBNz
Q3K2+I/RVxXfAnIE/JTDUBC1k1S/SJATl+ltSxEcKAlJV2ALFBOTMp8f9ihVjLYUKTa8Z6GBCAF
rMN8Y8zPrZYL2oIy5RHrHr1qlOsw0AePwrsj47HFysrYpcBFcF1w8Mk2ti7wUaDRgg1EISNXVwF
lKpdsEAIj9zNAFnW3e4gecCV7Ft/qKTNP0A2Et7AUIj3ysARLDBaC7MRkF+I+x3wzA08SLiTYER
KMJ3BoR3wzUUvLdJAFBtIWIttZEQIwMzfEXNB2PZJ0J1HIrgIQkFILjBkUgSwFuJdnj3i4pEIlg
eY+Bc0AGSRxLg4zsblkcYODiK0KNzUEk1JAkaCkjDbSc+maE5d20i3HY0zDbdh1vQyWNuJkjXnJ
C/HDbCQeTVwOYHKEJJwmR/wlBYi16KMMBOHTnClZpjmpAYUh0GGoyJMxya6KcBlieIj7IsqB0ji
5iwyyu8ZboigKCd2RRVAUTQyBAugToqXDVhwKpUIxzgyoaacILMc5jQEtkIHLCjwQUMkxhnx5I/
seMBta3cKSk7BghQAQMeqMmkY20amA+zHtDiEwl10dRiBcPoacJr0qjx7Ai+yTjQvk31aws92JZ
Q1070mGsSQsS1uYWiJeDrCkGy+CZvnjFEUME7VaFaQAcXCCDyyBYA3NQGIY8ssgU7vqAxjB4EwA
DEIyxggQAsjxDBzRagKtbGaBXclAMMvNNuBaiGAAA7"

  return [image create photo -format GIF -data $logoData]
}

makeWindow
set cons [doPickCons]
updateWidgets
::tk::PlaceWindow . widget


#############################################################################
#
# This file is licensed under the Cadence Public License Version 1.0 (the
# "License"), a copy of which is found in the included file named "LICENSE",
# and is distributed "AS IS." TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE
# LAW, CADENCE DISCLAIMS ALL WARRANTIES AND IN NO EVENT SHALL BE LIABLE TO
# ANY PARTY FOR ANY DAMAGES ARISING OUT OF OR RELATING TO USE OF THIS FILE.
# Please see the License for the full text of applicable terms.
#
#############################################################################
