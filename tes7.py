from vtk import *

reader = vtkStructuredGridReader()
reader.SetFileName("density.vtk")
reader.Update()

iso = vtkContourFilter()
iso.SetInputConnection(reader.GetOutputPort())
iso.SetValue(0, 0.26)

isoMapper = vtkPolyDataMapper()
isoMapper.SetInputConnection(iso.GetOutputPort())
isoMapper.ScalarVisibilityOn()
isoMapper.SetScalarRange(reader.GetOutput().GetScalarRange())

isoActor = vtkActor()
isoActor.SetMapper(isoMapper)

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
ren.AddActor(isoActor)
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