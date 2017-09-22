import vtk
r = vtk.vtkDataSetReader()
r.SetFileName('wind.vtk')

w = vtk.vtkDataSetWriter()
w.SetInput( r.GetOutput() )
w.SetFileName('windNew.vtk')
w.Write()