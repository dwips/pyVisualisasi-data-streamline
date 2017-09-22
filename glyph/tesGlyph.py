from vtk import *

lut = vtkLookupTable()
lut.SetNumberOfColors(256)
lut.SetHueRange(0.0, 0.667)
lut.Build()

reader = vtkStructuredGridReader()
reader.SetFileName("density.vtk")
reader.Update()

arrow = vtkArrowSource()
arrow.SetTipResolution(6)
arrow.SetTipRadius(0.1)
arrow.SetShaftResolution(6)
arrow.SetShaftRadius(0.03)

glyph = vtkGlyph3D()
glyph.SetInput(reader.GetOutput())
glyph.SetSource(arrow.GetOutput())
glyph.SetVectorModeToUseVector()
glyph.SetColorModeToColorByScalar()
glyph.SetScaleModeToDataScalingOff()
glyph.OrientOn()
glyph.SetScaleFactor(0.2)

glyphMapper = vtkPolyDataMapper()
glyphMapper.SetInput(glyph.GetOutput())
glyphMapper.SetLookupTable(lut)
glyphMapper.ScalarVisibilityOn()
glyphMapper.SetScalarRange(reader.GetOutput().GetScalarRange())

glyphActor = vtkActor()
glyphActor.SetMapper(glyphMapper)

outline = vtkStructuredGridOutlineFilter()
outline.SetInputConnection(reader.GetOutputPort())

outlineMapper = vtkPolyDataMapper()
outlineMapper.SetInputConnection(outline.GetOutputPort())

outlineActor = vtkActor()
outlineActor.SetMapper(outlineMapper)

ren = vtkRenderer()
renWin = vtkRenderWindow()
renWin.AddRenderer(ren)
iren = vtkRenderWindowInteractor()
iren.SetRenderWindow(renWin)

ren.AddActor(outlineActor)
ren.AddActor(glyphActor)
ren.SetBackground(0.5, 0.5, 0.5)
renWin.SetSize(500, 500)

iren.Initialize()

# We'll zoom in a little by accessing the camera and invoking a "Zoom"
# method on it.
ren.ResetCamera()
ren.GetActiveCamera().Zoom(1.5)
renWin.Render()

# Start the event loop.
iren.Start()