from vtk import *

lut = vtkLookupTable()
lut.SetNumberOfColors(256)
lut.SetHueRange(0.0, 0.667)
lut.Build()

reader = vtkStructuredGridReader()
reader.SetFileName("density1.vtk")
reader.Update()

hhog = vtkHedgeHog()
hhog.SetInput(reader.GetOutput())
hhog.SetScaleFactor(0.001)

hhogMapper = vtkPolyDataMapper()
hhogMapper.SetInput(hhog.GetOutput())
hhogMapper.SetLookupTable(lut)
hhogMapper.ScalarVisibilityOn()
hhogMapper.SetScalarRange(reader.GetOutput().GetScalarRange())

hhogActor = vtkActor()
hhogActor.SetMapper(hhogMapper)

outline = vtkStructuredGridOutlineFilter()
outline.SetInputConnection(reader.GetOutputPort())

outlineMapper = vtkPolyDataMapper()
outlineMapper.SetInputConnection(outline.GetOutputPort())

outlineActor = vtkActor()
outlineActor.SetMapper(outlineMapper)

ren = vtkRenderer()
renWin = vtkRenderWindow()
renWin.AddRenderer(ren)
iren = vtk.vtkRenderWindowInteractor()
iren.SetRenderWindow(renWin)

ren.AddActor(outlineActor)
ren.AddActor(hhogActor)
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
