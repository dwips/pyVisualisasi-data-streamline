import vtk

lut = vtk.vtkLookupTable()
lut.SetNumberOfColors(8)
lut.SetHueRange(0.0, 0.667)
lut.Build()

reader = vtk.vtkStructuredGridReader()
reader.SetFileName("density.vtk")
reader.Update()

mapper = vtk.vtkDataSetMapper()
mapper.SetInputConnection(reader.GetOutputPort())
mapper.SetLookupTable(lut)
mapper.SetScalarRange(reader.GetOutput().GetScalarRange())

actor = vtk.vtkActor()
actor.SetMapper(mapper)

#renderer
ren = vtk.vtkRenderer()
renWin = vtk.vtkRenderWindow()
renWin.AddRenderer(ren)
iren = vtk.vtkRenderWindowInteractor()
iren.SetRenderWindow(renWin)

# Add the actors to the renderer, set the background and size
ren.AddActor(actor)
ren.SetBackground(0.5, 0.5, 0.5)
renWin.SetSize(500, 500)

# This allows the interactor to initalize itself. It has to be
# called before an event loop.
iren.Initialize()

# We'll zoom in a little by accessing the camera and invoking a "Zoom"
# method on it.
ren.ResetCamera()
ren.GetActiveCamera().Zoom(1.5)
renWin.Render()

# Start the event loop.
iren.Start()




