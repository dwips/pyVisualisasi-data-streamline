from vtk import *

## read data
reader = vtkStructuredPointsReader()
reader.SetFileName("tes.vtk")
reader.Update()

## get extent data
W,H,D = reader.GetOutput().GetDimensions()

## creating an outline of the dataset
outline = vtkOutlineFilter()
if VTK_MAJOR_VERSION <=5:
    outline.SetInput(reader.GetOutput())
else:
    outline.SetInputData(reader.GetOutput())

outlineMapper = vtkPolyDataMapper()
if VTK_MAJOR_VERSION<=5:
    outlineMapper.SetInput( outline.GetOutput() )
else:
    outlineMapper.SetInputData( outline.GetOutput() )
outlineActor = vtkActor()
outlineActor.SetMapper( outlineMapper )
outlineActor.GetProperty().SetColor(1.0,1.0,1.0)
outlineActor.GetProperty().SetLineWidth(2.0)


## find the range of scalars
min,max = reader.GetOutput().GetScalarRange()

## a lookup table for mapping point scalar data to colors
lut = vtkColorTransferFunction()
lut.AddRGBPoint(min, 0.0, 0.0, 1.0)
lut.AddRGBPoint(min+(max-min)/4, 0.0, 1.0, 1.0)
lut.AddRGBPoint(min+(max-min)/2, 0.0, 1.0, 0.0)
lut.AddRGBPoint(max-(max-min)/4, 1.0, 1.0, 0.0)
lut.AddRGBPoint(max, 1.0, 0.0, 0.0)

## a lookup table for coloring glyphs
lut2 = vtkColorTransferFunction()
lut2.AddRGBPoint(min, 0.6, 0.6, 0.6)
lut2.AddRGBPoint(max, 0.6, 0.6, 0.6)

## a colorbar to display the colormap
scalarBar = vtkScalarBarActor()
scalarBar.SetLookupTable( lut )
scalarBar.SetTitle( "Wind speed" )
scalarBar.SetOrientationToHorizontal()
scalarBar.GetLabelTextProperty().SetColor(1,1,1)
scalarBar.GetTitleTextProperty().SetColor(1,1,1)

# position of the colorbar in window
coord = scalarBar.GetPositionCoordinate()
coord.SetCoordinateSystemToNormalizedViewport()
coord.SetValue(0.1,0.05)
scalarBar.SetWidth(0.8)
scalarBar.SetHeight(0.1)

## define slice plane
SlicePlane = vtkImageDataGeometryFilter()
SlicePlane.SetInputConnection( reader.GetOutputPort() )
SlicePlane.SetExtent(0, 42, 0, 102, 0, 0)
SlicePlane.ReleaseDataFlagOn()

SlicePlaneMapper = vtkPolyDataMapper()
SlicePlaneMapper.SetInputConnection( SlicePlane.GetOutputPort() )
SlicePlaneMapper.SetLookupTable( lut )
SlicePlaneActor = vtkActor()
SlicePlaneActor.SetMapper( SlicePlaneMapper )
SlicePlaneActor.GetProperty().SetOpacity(0.6)

## define oriented glyphs
# arrow source for glyph3D
Arrow = vtkArrowSource()

glyph = vtkGlyph3D()
glyph.SetInputConnection( SlicePlane.GetOutputPort() )
if VTK_MAJOR_VERSION<=5:
    glyph.SetSource( Arrow.GetOutput() )
else:
    glyph.SetSourceData( Arrow.GetOutput() )
glyph.SetScaleModeToScaleByScalar()
glyph.SetScaleFactor(2)
glyph.ClampingOn()

glyphMapper = vtkPolyDataMapper()
glyphMapper.SetInputConnection( glyph.GetOutputPort() )
glyphMapper.SetLookupTable( lut2 )
glyphActor = vtkActor()
glyphActor.SetMapper( glyphMapper )

seeds = vtkPointSource()
seeds.SetRadius(18.0) #radius persebaran
seeds.SetCenter(reader.GetOutput().GetCenter())
seeds.SetNumberOfPoints(150) #banyak point

integ = vtkRungeKutta4() # integrator for generating the streamlines #
streamer = vtkStreamLine()
streamer.SetInputConnection( reader.GetOutputPort() )
if VTK_MAJOR_VERSION<=5:
    streamer.SetSource( seeds.GetOutput() )
else:
    streamer.SetSourceData( seeds.GetOutput() )
streamer.SetMaximumPropagationTime(500)
streamer.SetIntegrationStepLength(1)
streamer.SetStepLength(0.1)
streamer.SetIntegrationDirectionToIntegrateBothDirections()
streamer.SetIntegrator( integ )

streamerMapper = vtkPolyDataMapper()
streamerMapper.SetInputConnection( streamer.GetOutputPort() )
streamerMapper.SetLookupTable( lut )
streamerActor = vtkActor()
streamerActor.SetMapper( streamerMapper )
streamerActor.VisibilityOn()

## renderer and render window
ren = vtkRenderer()
ren.SetBackground(0.1, 0.1, 0.1)
renWin = vtkRenderWindow()
renWin.SetSize(800, 600)
renWin.AddRenderer( ren )

## render window interactor
iren = vtkRenderWindowInteractor()
iren.SetRenderWindow( renWin )

## add the actors to the renderer
ren.AddActor( outlineActor )
ren.AddActor( streamerActor )
ren.AddActor( glyphActor )
ren.AddActor( scalarBar )
ren.AddActor( SlicePlaneActor )

## render
renWin.Render()

iren.Initialize()

ren.ResetCamera()
ren.GetActiveCamera().Zoom(1.5)
renWin.Render()

iren.Start()