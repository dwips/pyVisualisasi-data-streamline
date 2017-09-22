from vtk import *

## read data
reader = vtkStructuredPointsReader()
reader.SetFileName("density.vtk")
reader.Update()

## get extent data
W,H,D = reader.GetOutput().GetDimensions()

## find the range of scalars
min = reader.GetOutput().GetPointData().GetScalarRange()

print "Reading '%s', width=%i, height=%i, depth=%i" %("wind.vtk", W, H, D)
print "%f %f" %(min)