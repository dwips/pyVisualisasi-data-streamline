# WeatherDisplay.tcl

# Written Spring 2004 for CS 526 by John Bell

# load the necessary VTK libraries.

package require vtk
package require vtkinteraction
package require vtktesting

# Initial values for key parameters

set mapOpacity 50
set tempOpacity 50
set hedgeOpacity 50
set streamOpacity 50
set moistureOpacity 50
set day 14
set month 5
set inputFile May.vtk
set mapFilename ICNstationsmap.jpg

# Create the RenderWindow, Renderer and both Actors

vtkRenderer ren1
vtkRenderWindow renWin
    renWin AddRenderer ren1
vtkRenderWindowInteractor iren
    iren SetRenderWindow renWin

# set the background and size.

ren1 SetBackground 0.8 0.8 0.8
renWin SetSize 720 720

# First the pipeline for the map layer  ###########
# ( Parameters set for ICNstations.jpg.  See below. )

vtkPlaneSource mapPlane
	mapPlane SetResolution 1 1
	mapPlane SetOrigin -91.63 36.95 -0.01
	mapPlane SetPoint1 -87.41 36.95 -0.01
	mapPlane SetPoint2 -91.63 42.65 -0.01

vtkPolyDataMapper mapMapper
	mapMapper SetInput [ mapPlane GetOutput ]

vtkJPEGReader mapReader
	mapReader SetFileName $mapFilename

vtkTexture mapTexture
	mapTexture SetInput [ mapReader GetOutput ]

vtkActor mapActor
	mapActor SetMapper mapMapper
	mapActor SetTexture mapTexture
	[ mapActor GetProperty ] SetOpacity [ expr $mapOpacity / 100.0 ]

ren1 AddActor mapActor

#
# Then the pipeline for the temperature layer  ########
# Initial conditions are the air temperatures
#

vtkStructuredGridReader tempReader
	tempReader SetFileName $inputFile
	tempReader SetScalarsName AirTemp

vtkStructuredGridGeometryFilter tempGeometry
	tempGeometry SetInput [ tempReader GetOutput ]
	tempGeometry SetExtent 0 100 0 100 $day $day

# Lookup table from the Chicago Tribune weather maps

vtkLookupTable tempLUT
	tempLUT SetNumberOfColors 18
	tempLUT SetTableValue 0 0 0 0 1
	tempLUT SetTableValue 1 0.6 0 0.6 1
	tempLUT SetTableValue 2 0.8 0 0.8 1
	tempLUT SetTableValue 3 1 0 1 1
	tempLUT SetTableValue 4 0.6 0 1 1
	tempLUT SetTableValue 5 0 0 1 1
	tempLUT SetTableValue 6 0 0.45 1 1
	tempLUT SetTableValue 7 0 0.8 1 1
	tempLUT SetTableValue 8 0 1 1 1
	tempLUT SetTableValue 9 0.5 1 0 1
	tempLUT SetTableValue 10 1 1 0 1
	tempLUT SetTableValue 11 1 0.8 0 1
	tempLUT SetTableValue 12 1 0.6 0 1
	tempLUT SetTableValue 13 1 0.3 0 1
	tempLUT SetTableValue 14 1 0.25 0.25 1
	tempLUT SetTableValue 15 1 0.5 0.5 1
	tempLUT SetTableValue 16 1 0.7 0.7 1
	tempLUT SetTableValue 17 1 1 1 1

vtkDataSetMapper tempMapper
	tempMapper SetInput [ tempGeometry GetOutput ]
	tempMapper SetLookupTable tempLUT
	tempMapper SetScalarRange -50 120
	
vtkActor tempActor
	tempActor SetMapper tempMapper
	[ tempActor GetProperty ] SetOpacity [ expr $tempOpacity / 100.0 ]

ren1 AddActor tempActor

vtkScalarBarActor tempScalarBar
	tempScalarBar SetLookupTable tempLUT
	tempScalarBar SetMaximumNumberOfColors 18
	tempScalarBar SetNumberOfLabels 18
	tempScalarBar SetTitle "Temperature"

ren1 AddActor tempScalarBar

#
# Then the pipeline for the hedgehog layer  ########
#

vtkStructuredGridReader windReader
	windReader SetFileName $inputFile
	windReader SetVectorsName WindVector
	windReader Update

vtkExtractGrid windExtractor
	windExtractor SetInput [ windReader GetOutput ]
	windExtractor SetVOI 0 100 0 100 $day $day
	windExtractor Update

vtkHedgeHog hedge
	hedge SetInput [ windExtractor GetOutput ]
	hedge SetVectorModeToUseVector

vtkConeSource hedgeCone
	hedgeCone SetRadius 0.0005
	hedgeCone SetHeight 0.002

vtkGlyph3D hedgeGlyphs
	hedgeGlyphs SetSource [ hedgeCone GetOutput ]
	hedgeGlyphs SetInput [ windExtractor GetOutput ]

vtkPolyDataMapper hedgeMapper
	hedgeMapper SetInput [ hedgeGlyphs GetOutput ]

vtkActor hedgeActor
	hedgeActor SetMapper hedgeMapper
	[ hedgeActor GetProperty ] SetOpacity [ expr $hedgeOpacity / 100.0 ]

ren1 AddActor hedgeActor

#
# Then the pipeline for the streams layer  ########
# ( No reader - uses same data as the hedgehog layer )
#

set length [ [ windExtractor GetOutput] GetLength]

set maxVelocity \
  [[[[windExtractor GetOutput] GetPointData] GetVectors] GetMaxNorm]
set maxTime [expr 35.0 * $length / $maxVelocity]

#Station locations are output by the preprocessor 

vtkPolyDataReader stationLocationReader
	stationLocationReader SetFileName stationLocations.vtk
	stationLocationReader Update

vtkRungeKutta4 integ

vtkStreamLine windStreamer
    windStreamer SetInput [ windExtractor GetOutput ]
    windStreamer SetSource [ stationLocationReader GetOutput ]
    windStreamer SetStartPosition -88.37 40.05 0.0
    windStreamer SetMaximumPropagationTime 500
    windStreamer SetStepLength 0.25
    windStreamer SetIntegrationStepLength 0.025
    windStreamer SetIntegrationDirectionToIntegrateBothDirections
    windStreamer SetIntegrator integ

# The tube is wrapped around the generated streamline. By varying the radius
# by the inverse of vector magnitude, we are creating a tube whose radius is
# proportional to mass flux (in incompressible flow).

vtkTubeFilter windTube
    windTube SetInput [ windStreamer GetOutput]
    windTube SetRadius 0.01
    windTube SetNumberOfSides 12
    windTube SetVaryRadiusToVaryRadiusByVector

vtkPolyDataMapper windTubeMapper
    windTubeMapper SetInput [ windTube GetOutput ]
    eval windTubeMapper SetScalarRange \
       [[[[windExtractor GetOutput] GetPointData] GetScalars] GetRange]

vtkActor windTubeActor
    windTubeActor SetMapper windTubeMapper
    [ windTubeActor GetProperty ] BackfaceCullingOn
    [ windTubeActor GetProperty ] SetOpacity [ expr $streamOpacity / 100.0 ]

ren1 AddActor windTubeActor

#
# Then the pipeline for the moisture glyphs layer  ########
# ( Two readers required, for precipitation and relative humidity )
#

vtkStructuredGridReader humidityReader
	humidityReader SetFileName $inputFile
	humidityReader SetScalarsName Humidity
	humidityReader Update

vtkExtractGrid humidityExtractor
	humidityExtractor SetInput [ humidityReader GetOutput ]
	humidityExtractor SetSampleRate 1 1 1
	humidityExtractor SetVOI 0 1000 0 1000 $day $day
	humidityExtractor Update

vtkStructuredGridReader precipReader
	precipReader SetFileName $inputFile
	precipReader SetScalarsName Precipitation
	precipReader Update

vtkExtractGrid precipExtractor
	precipExtractor SetInput [ precipReader GetOutput ]
	precipExtractor SetSampleRate 1 1 1
	precipExtractor SetVOI 0 1000 0 1000 $day $day
	precipExtractor Update

vtkCubeSource cube
	cube SetXLength 0.1
	cube SetYLength 0.1
	cube SetZLength 1.0

vtkProgrammableGlyphFilter glypher1
	glypher1 SetInput [ humidityExtractor GetOutput ]
	glypher1 SetSource [ cube GetOutput ]
	glypher1 SetColorModeToColorByInput
	glypher1 SetGlyphMethod humidityProc1

proc humidityProc1 { } {
	set ptID [ glypher1 GetPointId ]
	precipExtractor Update
	eval set height [[[[ precipExtractor GetOutput ] GetPointData ] GetScalars ] GetComponent $ptID 0 ]
	puts [[[[ humidityExtractor GetOutput ] GetPointData ] GetScalars ] GetComponent $ptID 0 ]
	cube SetZLength $height

	set xyz [ glypher1 GetPoint ]
	set x [ lindex $xyz 0 ]
	set y [ lindex $xyz 1 ]
	set z [ expr $height / 2.0 ]
	cube SetCenter $x $y $z

}

vtkLookupTable moistureTable
	moistureTable SetNumberOfColors 32
	moistureTable SetHueRange 0.6666 0.6666
	moistureTable SetValueRange 1.0 1.0
	moistureTable SetSaturationRange 0.0 1.0
	moistureTable SetAlphaRange 1.0 1.0

vtkPolyDataMapper moistureMapper
	moistureMapper SetInput [ glypher1 GetOutput ]
	moistureMapper SetLookupTable moistureTable
	eval moistureMapper SetScalarRange [ [ humidityReader GetOutput ] GetScalarRange ]

vtkActor moistureActor
	moistureActor SetMapper moistureMapper
	[ moistureActor GetProperty ] SetOpacity [ expr $moistureOpacity / 100.0 ]

ren1 AddActor moistureActor

vtkScalarBarActor moistureScalarBar
	moistureScalarBar SetLookupTable moistureTable
	moistureScalarBar SetMaximumNumberOfColors 20
	moistureScalarBar SetNumberOfLabels 11
	moistureScalarBar SetTitle "Relative Humidity"
	moistureScalarBar SetDisplayPosition 20 100

ren1 AddActor moistureScalarBar

#
# Render the image ####################################
#

ren1 ResetCamera
renWin Render 

#############################################################################
#
# Create Tk user interface. 
#

frame .f

  # First the title frame

  frame .f.f0 -borderwidth 2 -relief ridge
    label .f.f0.l1 -text "Weather Viewer" -font { Helvetica -20 bold }
    label .f.f0.l2 -text "John T. Bell - CS 526 Spring 2004" -font { Helvetica -12 bold }
  pack .f.f0.l1 .f.f0.l2 -side top

  # Date Selector

  frame .f.d -borderwidth 2 -relief ridge
    label .f.d.l -text "Date Selector" -font { Helvetica -16 bold }

      frame .f.d.f0
      # Labels
      frame .f.d.f0.labels
	label .f.d.f0.labels.l1 -text "Month:"  -font { Helvetica -12 bold }
	label .f.d.f0.labels.l2 -text "Day:"  -font { Helvetica -12 bold }
      pack .f.d.f0.labels.l1 .f.d.f0.labels.l2 -side top -pady 11

      # Scales
      frame .f.d.f0.scales

    scale .f.d.f0.scales.month -from 1 -to 12 -orient horizontal \
	-command adjustMonth
      .f.d.f0.scales.month set $month

    scale .f.d.f0.scales.day -from 1 -to 31 -orient horizontal \
	-command adjustDay
      .f.d.f0.scales.day set $day

	pack .f.d.f0.scales.month .f.d.f0.scales.day -side top

	pack .f.d.f0.labels .f.d.f0.scales -side left -padx 10
	
     frame .f.d.f1
	button .f.d.f1.month -text "Month" -font { Helvetica -12 bold } \
		-command { animateMonth }
	button .f.d.f1.year -text "Year" -font { Helvetica -12 bold }
     pack .f.d.f1.month .f.d.f1.year -side left -padx 40

  pack .f.d.l .f.d.f0 .f.d.f1 -side top -fill x

  # Opacity sliders

  frame .f.o -borderwidth 2 -relief ridge
    label .f.o.l -text "Visibility" -font { Helvetica -16 bold }

      frame .f.o.f0
      # Labels
      frame .f.o.f0.labels
	label .f.o.f0.labels.l1 -text "Map:"  -font { Helvetica -12 bold }
	label .f.o.f0.labels.l2 -text "Temperatures:"  -font { Helvetica -12 bold }
	label .f.o.f0.labels.l3 -text "Wind Vectors:"  -font { Helvetica -12 bold }
	label .f.o.f0.labels.l4 -text "Wind Streams:"  -font { Helvetica -12 bold }
	label .f.o.f0.labels.l5 -text "Moisture Icons:"  -font { Helvetica -12 bold }
      pack .f.o.f0.labels.l1 .f.o.f0.labels.l2 .f.o.f0.labels.l3 .f.o.f0.labels.l4 \
	 .f.o.f0.labels.l5 -side top -pady 11

      # Scales

      frame .f.o.f0.scales

	scale .f.o.f0.scales.map -from 0 -to 100 -orient horizontal \
	    -variable mapOpacity -command adjustMapOpacity
	  .f.o.f0.scales.map set $mapOpacity

	scale .f.o.f0.scales.temp -from 0 -to 100 -orient horizontal \
	    -variable tempOpacity -command adjustTempOpacity
	  .f.o.f0.scales.temp set $tempOpacity

	scale .f.o.f0.scales.hedge -from 0 -to 100 -orient horizontal \
	    -variable hedgeOpacity -command adjustHedgeOpacity
	  .f.o.f0.scales.hedge set $hedgeOpacity

	scale .f.o.f0.scales.stream -from 0 -to 100 -orient horizontal \
	    -variable streamOpacity -command adjustStreamOpacity
	  .f.o.f0.scales.stream set $streamOpacity

	scale .f.o.f0.scales.moisture -from 0 -to 100 -orient horizontal \
	    -variable moistureOpacity -command adjustMoistureOpacity
	  .f.o.f0.scales.moisture set $moistureOpacity

      pack .f.o.f0.scales.map .f.o.f0.scales.temp .f.o.f0.scales.hedge \
	.f.o.f0.scales.stream .f.o.f0.scales.moisture -side top

	pack .f.o.f0.labels .f.o.f0.scales -side left -padx 10

    pack .f.o.l .f.o.f0 -side top

  # Map selector radio buttons

  frame .f.m -borderwidth 2 -relief ridge
    label .f.m.l -text "Map Selector" -font { Helvetica -16 bold }

    radiobutton .f.m.rb1 -variable mapFilename -text "ICN Stations" \
	-value "ICNstationsmap.jpg"  -font { Helvetica -12 bold } \
	-command { selectMap 1 }
    radiobutton .f.m.rb2 -variable mapFilename -text "CNN Map" \
	-value "bigIllinois.jpg"  -font { Helvetica -12 bold } \
	-command { selectMap 1 }
    radiobutton .f.m.rb3 -variable mapFilename -text "IL Tourism" \
	-value "ILTourism.jpg"  -font { Helvetica -12 bold } \
	-command { selectMap 1 }
    radiobutton .f.m.rb4 -variable mapFilename -text "World Sites Atlas" \
	-value "WorldSitesAtlas.jpg"  -font { Helvetica -12 bold } \
	-command { selectMap 1 }
    radiobutton .f.m.rb5 -variable mapFilename -text "County Outline" \
	-value "CountyOutline.jpg"  -font { Helvetica -12 bold } \
	-command { selectMap 1 }
    radiobutton .f.m.rb6 -variable mapFilename -text "County Detail" \
	-value "CountyDetail.jpg"  -font { Helvetica -12 bold } \
	-command { selectMap 1 }
    .f.m.rb1 select
  pack .f.m.l .f.m.rb1 .f.m.rb2 .f.m.rb3 .f.m.rb4 .f.m.rb5 .f.m.rb6 -side top

  # Temperature selectors

  frame .f.t -borderwidth 2 -relief ridge
    label .f.t.l -text "Temperature Selector" -font { Helvetica -16 bold }
    radiobutton .f.t.rb1 -variable tempChoice -text "Air Temp" \
	-value "Air"  -font { Helvetica -12 bold } \
	-command { selectTemp 1 }
    radiobutton .f.t.rb2 -variable tempChoice -text "Soil Temp" \
	-value "Soil"  -font { Helvetica -12 bold } \
	-command { selectTemp 1 }
    .f.t.rb1 select
  pack .f.t.l .f.t.rb1 .f.t.rb2 -side top

  pack .f.f0 .f.d .f.o .f.m .f.t -side top -fill x
pack .f

################################################################################

# Procedures invoked by the UI Controls

proc adjustMapOpacity { value } {
	[ mapActor GetProperty ] SetOpacity [ expr $value / 100.0 ]
	renWin Render
}


proc adjustTempOpacity { value } {
	[ tempActor GetProperty ] SetOpacity [ expr $value / 100.0 ]
	renWin Render
}


proc adjustHedgeOpacity { value } {
	[ hedgeActor GetProperty ] SetOpacity [ expr $value / 100.0 ]
	renWin Render
}


proc adjustStreamOpacity { value } {
	[ windTubeActor GetProperty ] SetOpacity [ expr $value / 100.0 ]
	renWin Render
}


proc adjustMoistureOpacity { value } {
	[ moistureActor GetProperty ] SetOpacity [ expr $value / 100.0 ]
	renWin Render
}

proc adjustMonth { value } {
	global month
	global inputFile

	set month $value

	switch $value {
		1 { set inputFile January.vtk }
		2 { set inputFile February.vtk }
		3 { set inputFile March.vtk }
		4 { set inputFile April.vtk }
		5 { set inputFile May.vtk }
		6 { set inputFile June.vtk }
		7 { set inputFile July.vtk }
		8 { set inputFile August.vtk }
		9 { set inputFile September.vtk }
		10 { set inputFile October.vtk }
		11 { set inputFile November.vtk }
		12 { set inputFile December.vtk }
	}
	tempReader SetFileName $inputFile
	windReader SetFileName $inputFile
	precipReader SetFileName $inputFile
	humidityReader SetFileName $inputFile
	humidityReader Update
	
	renWin Render
}

proc adjustDay { value } {
	global day
	set day [ expr $value - 1 ]
	tempGeometry SetExtent 0 100 0 100 $day $day
	windExtractor SetVOI 0 100 0 100 $day $day
	precipExtractor SetVOI 0 100 0 100 $day $day
	humidityExtractor SetVOI 0 100 0 100 $day $day
	renWin Render
}

proc selectMap { value } {

	global mapFilename
	mapReader SetFileName $mapFilename

	switch $mapFilename {
		ICNstationsmap.jpg {
			mapPlane SetOrigin -91.63 36.95 -0.01
			mapPlane SetPoint1 -87.41 36.95 -0.01
			mapPlane SetPoint2 -91.63 42.65 -0.01
		}
		bigIllinois.jpg {
			mapPlane SetOrigin -92.145 36.09 -0.01
			mapPlane SetPoint1 -86.54 36.09 -0.01
			mapPlane SetPoint2 -92.145 43.2 -0.01
		}
		ILTourism.jpg {
			mapPlane SetOrigin -91.88 36.89 -0.01
			mapPlane SetPoint1 -87.14 36.89 -0.01
			mapPlane SetPoint2 -91.88 42.55 -0.01
		}
		WorldSitesAtlas.jpg {
			mapPlane SetOrigin -92.08 36.71 -0.01
			mapPlane SetPoint1 -86.98 36.71 -0.01
			mapPlane SetPoint2 -92.08 42.75 -0.01
		}
		CountyOutline.jpg {
			mapPlane SetOrigin -91.67 36.83 -0.01
			mapPlane SetPoint1 -87.1 36.83 -0.01
			mapPlane SetPoint2 -91.67 42.69 -0.01
		}
		CountyDetail.jpg {
			mapPlane SetOrigin -91.55 36.88 -0.01
			mapPlane SetPoint1 -86.94 36.88 -0.01
			mapPlane SetPoint2 -91.55 42.72 -0.01
		}
	}
	renWin Render
}

proc selectTemp {  value } {

	global tempChoice

	switch $tempChoice {
		Air { tempReader SetScalarsName AirTemp }
		Soil { tempReader SetScalarsName SoilTemp }
	}

	renWin Render
}

proc animateMonth { } {

	for { set day 1 } { $day < 29 } { incr day } {
		
		.f.d.f0.scales.day set $day
		renWin Render
		# Sleep command here didn't work :-(
	}
}











