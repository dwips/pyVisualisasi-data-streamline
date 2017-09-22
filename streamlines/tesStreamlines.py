from vtk import *

reader = vtkStructuredGridReader()
reader.SetFileName("pressure.vtk")
reader.Update()

seeds = vtkPointSource()
seeds.SetRadius(3.0)
seeds.SetCenter(reader.GetOutput().GetCenter())
seeds.SetNumberOfPoints(100)

integ = vtkRungeKutta4()

streamer = vtkStreamTracer()
streamer.SetInputConnection(reader.GetOutputPort())
streamer.SetSourceConnection(seeds.GetOutputPort())
streamer.SetMaximumPropagation(100)
#streamer.SetMaximumPropagationUnitToTimeUnit()
streamer.SetInitialIntegrationStep(0.1)
#streamer.SetInitialIntegrationStepUnitToCellLengthUnit()
streamer.SetIntegrationDirectionToBoth()
streamer.SetIntegrator(integ)

mapStreamLines = vtkPolyDataMapper()
mapStreamLines.SetInputConnection(streamer.GetOutputPort())
mapStreamLines.SetScalarRange(reader.GetOutput().GetScalarRange())

streamLineActor = vtkActor()
streamLineActor.SetMapper(mapStreamLines)

#outlinenya
outline = vtkStructuredGridOutlineFilter()
outline.SetInputConnection(reader.GetOutputPort())

outlineMapper = vtkPolyDataMapper()
outlineMapper.SetInputConnection(outline.GetOutputPort())

outlineActor = vtkActor()
outlineActor.SetMapper(outlineMapper)

#rendering
ren = vtkRenderer()
renWin = vtkRenderWindow()
renWin.AddRenderer(ren)
iren = vtkRenderWindowInteractor()
iren.SetRenderWindow(renWin)

ren.AddActor(outlineActor)
ren.AddActor(streamLineActor)
ren.SetBackground(0.8, 0.8, 0.8)
renWin.SetSize(500, 500)

iren.Initialize()

# We'll zoom in a little by accessing the camera and invoking a "Zoom"
# method on it.
ren.ResetCamera()
ren.GetActiveCamera().Zoom(1.5)
renWin.Render()

# Start the event loop.
iren.Start()