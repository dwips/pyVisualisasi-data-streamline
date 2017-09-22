package require vtk
package require vtkinteraction

vtkLookupTable lut
    lut SetNumberOfColors 256
    lut SetHueRange 0.0 0.667
    lut Build

vtkStructuredGridReader reader
    reader SetFileName "Data/density.vtk"
    reader Update

vtkArrowSource arrow
    arrow SetTipResolution 6
    arrow SetTipRadius 0.1
    arrow SetTipLength 0.35
    arrow SetShaftResolution 6
    arrow SetShaftRadius 0.03

vtkGlyph3D glyph
    glyph SetInput [reader GetOutput]
    glyph SetSource [arrow GetOutput]
    glyph SetVectorModeToUseVector
    glyph SetColorModeToColorByScalar
#    glyph SetScaleModeToScaleByVector
    glyph SetScaleModeToDataScalingOff
    glyph OrientOn
  glyph SetScaleFactor 0.2

vtkPolyDataMapper glyphMapper
    glyphMapper SetInput [glyph GetOutput]
    glyphMapper SetLookupTable lut
    glyphMapper ScalarVisibilityOn
    eval glyphMapper SetScalarRange [[reader GetOutput] GetScalarRange]
#    glyphMapper SetScalarModeToUsePointData

vtkActor glyphActor
    glyphActor SetMapper glyphMapper

vtkStructuredGridOutlineFilter outline
    outline SetInputConnection [reader GetOutputPort]
vtkPolyDataMapper outlineMapper
    outlineMapper SetInputConnection [outline GetOutputPort]
vtkActor outlineActor
    outlineActor SetMapper outlineMapper

vtkRenderer ren1
vtkRenderWindow renWin
    renWin AddRenderer ren1
vtkRenderWindowInteractor iren
    iren SetRenderWindow renWin

ren1 AddActor outlineActor
ren1 AddActor glyphActor
ren1 SetBackground 0.5 0.5 0.5
renWin SetSize 500 500

iren AddObserver UserEvent {wm deiconify .vtkInteract}
renWin Render

wm withdraw .
