/* WeatherDisplay.cpp

	Written April 2004 by John Bell for CS 526

*/

#include <iostream>
#include <fstream>
#include <cstdlib>
#include <string>
#define _USE_MATH_DEFINES
#include <math.h>

#pragma warning( disable : 4244 )

using namespace std;

#define NREGIONS 19
#define NDATA 18
#define MAXDAYS 31
#define NX 10
#define NY 12
#define ZSCALE 0.001
#define WINDSCALE 69.6

int main( int argc, char **argv ) {

	const bool binary = false;
	bool invalid[ NREGIONS ][ MAXDAYS ][ NDATA ] = {0};
	char buffer[ 256 ], code[ 20 ];
	int nDays, nPoints, i, ix, iy, d, ir, day;
	float wind[ MAXDAYS ][ NY ][ NX ][ 3 ] = {0};
	float soilTemp[ MAXDAYS ][ NY ][ NX ], airTemp[ MAXDAYS ][ NY ][ NX ], 
		humidity[ MAXDAYS ][ NY ][ NX ], precip[ MAXDAYS ][ NY ][ NX ],
		positions[ NY ][ NX ][ 3 ] = {0.0f};
	double x, y, z, x0, deltax, a, s, h, p, w[ 2 ], theta;
	double data[ NREGIONS ][ MAXDAYS ][ NDATA ];
	double avgHumidity[ NREGIONS ][ MAXDAYS ];
	double windVector[ NREGIONS ][ MAXDAYS ][ 2 ];
	double distances[ NREGIONS ], sum, distance, dist;
	double stationLocations[ NREGIONS ][ 3 ] = {
		{ -88.37, 40.05, 213.0 }, { -88.67, 37.45, 165.0 }, 
		{ -88.95, 38.95, 177.0 }, { -90.83, 39.80, 206.0 },
		{ -88.85, 41.85, 265.0 }, { -90.73, 40.92, 229.0 },
		{ -90.08, 40.17, 152.0 }, { -89.52, 40.70, 207.0 },
		{ -89.62, 39.68, 177.0 }, { -89.88, 38.52, 133.0 },
		{ -89.23, 37.70, 137.0 }, { -88.10, 38.73, 134.0 },
		{ -89.67, 42.28, 265.0 }, { -88.92, 38.13, 130.0 },
		{ -88.17, 40.95, 213.0 }, { -89.75, 40.73, 186.0 },
		{ -88.37, 41.90, 226.0 }, { -88.38, 38.38, 136.0 },
		{ -88.23, 40.08, 219.0 } };
	double stateEdges[ NY ][ 3 ] = { // Y value, West X edge, East X edge
		{ 37.0, -89.3,   -88.5   }, { 37.5,   -89.5,   -88.067 },
		{ 38.0, -90.05,  -88.025 }, { 38.5,   -90.267, -87.683 },
		{ 39.0, -90.683, -87.583 }, { 39.5,   -91.067, -87.533 },
		{ 40.0, -91.467, -87.533 }, { 40.5,   -91.367, -87.525 },
		{ 41.0, -90.933, -87.525 }, { 41.5,   -91.125, -87.525 },
		{ 42.0, -90.142, -87.65  }, { 42.508, -90.65,  -87.8   } };

	// Check the command line arguments

	if( argc != 3 ) {
		cout << "Usage: " << argv[ 0 ] << " inputFile outputFile\n";
		return -1;
	}
	
	// Open up the input and output files

	ifstream fin( argv[ 1 ] );
	ofstream fout( argv[ 2 ] );

	if( !fin || !fout ) {
		cout << "Error:  Unable to open files\n";
		return -1;
	}
	
	// Read in the data from the input file.  Process a little

	for( ir = 0; ir < NREGIONS; ir++ ) {

		stationLocations[ ir ][ 2 ] = 0.0; // Flatten the state for wind integration

		fin.getline( buffer, 256 );
		while( ! strstr( buffer, "-----" ) )
			fin.getline( buffer, 256 );
		for( d = 0; d < 32; d++ ) {

			fin.getline( buffer, 256 );
			if( strstr( buffer, "-----" ) ) break;

			if( d >= 31 ) {
				cerr << "Error:  Number of days exceeded 31\n";
				cerr << buffer;
				return -3;
			}

			sscanf( buffer, "%d %lf%c %lf%c %lf%c %lf%c %lf%c %lf%c %lf%c %lf%c %lf%c" 
				" %lf%c %lf%c %lf%c %lf%c %lf%c %lf%c %lf%c %lf%c %lf%c", &day, 
				&data[ ir ][ d ][ 0 ], &code[ 0 ], &data[ ir ][ d ][ 1 ], 
				&code[ 1 ], &data[ ir ][ d ][ 2 ], &code[ 2 ], 
				&data[ ir ][ d ][ 3 ], &code[ 3 ], &data[ ir ][ d ][ 4 ], 
				&code[ 4 ], &data[ ir ][ d ][ 5 ], &code[ 5 ], 
				&data[ ir ][ d ][ 6 ], &code[ 6 ], &data[ ir ][ d ][ 7 ], 
				&code[ 7 ], &data[ ir ][ d ][ 8 ], &code[ 8 ], 
				&data[ ir ][ d ][ 9 ], &code[ 9 ], &data[ ir ][ d ][ 10 ], 
				&code[ 10 ],  &data[ ir ][ d ][ 11 ], &code[ 11 ], 
				&data[ ir ][ d ][ 12 ], &code[ 12 ], &data[ ir ][ d ][ 13 ], 
				&code[ 13 ],  &data[ ir ][ d ][ 14 ], &code[ 14 ], 
				&data[ ir ][ d ][ 15 ], &code[ 15 ], &data[ ir ][ d ][ 16 ], 
				&code[ 16 ], &data[ ir ][ d ][ 17 ], &code[ 17 ] );

			for( i = 0; i < NDATA; i++ )
				if( code[ i ] == 'M' )
					invalid[ ir ][ d ][ i ] = true;

			// Calculate average humidity and wind direction vector

			avgHumidity[ ir ][ d ] = ( data[ ir ][ d ][ 7 ] + 
				data[ ir ][ d ][ 8 ] ) / 2.0;

			theta = data[ ir ][ d ][ 2 ] * M_PI / 180.0;
			windVector[ ir ][ d ][ 0 ] = -data[ ir ][ d ][ 1 ] * sin( theta ) / WINDSCALE;
			windVector[ ir ][ d ][ 1 ] =  data[ ir ][ d ][ 1 ] * cos( theta ) / WINDSCALE;

		} // Days
	} // Regions

	fin.close( );

	nDays = d;
	nPoints = NX * NY * nDays;

	// Print header information into the output file

	fout << "# vtk DataFile Version 3.0\n";
	fout << "Autogenerated from " << argv[ 1 ] << " by " << argv[ 0 ] << endl;
	if( binary )
		fout << "BINARY\n";
	else
		fout << "ASCII\n";
	fout << "DATASET STRUCTURED_GRID\n";
	fout << "DIMENSIONS " << NX << " " << NY << " " << nDays << endl;
	fout << "POINTS " << nPoints << " float\n";

	// Now to start interpolating data, using Shephard's Method

	for( iy = 0; iy < NY; iy++ ) {
		
		y = stateEdges[ iy ][ 0 ];
		x0 = stateEdges[ iy ][ 1 ];
		deltax = ( stateEdges[ iy ][ 2 ] - stateEdges[ iy ][ 1 ] ) / ( NX -1 );

		for( ix = 0; ix < NX; ix++ ) {

			x = x0 + ix * deltax;

			positions[ iy ][ ix ][ 0 ] = x;
			positions[ iy ][ ix ][ 1 ] = y;

			for( ir = 0, sum = 0.0; ir < NREGIONS; ir++ ) {

				dist = stationLocations[ ir ][ 0 ] - x;
				distance = dist * dist;
				dist = stationLocations[ ir ][ 1 ] - y;
				distance += dist * dist;

				if( distance < 0.01 ) {

					positions[ iy ][ ix ][ 2 ] = stationLocations[ ir ][ 2 ] * ZSCALE;

					for( d = 0; d < nDays; d++ ) {

						wind[ d ][ iy ][ ix ][ 0 ] = windVector[ ir ][ d ][ 0 ];
						wind[ d ][ iy ][ ix ][ 1 ] = windVector[ ir ][ d ][ 1 ];
						
						airTemp[ d ][ iy ][ ix ] = data[ ir ][ d ][ 6 ];
						soilTemp[ d ][ iy ][ ix ] = data[ ir ][ d ][ 14 ];
						precip[ d ][ iy ][ ix ] = data[ ir ][ d ][ 10 ];
						humidity[ d ][ iy ][ ix ] = avgHumidity[ ir ][ d ];

					} // d through nDays

					break;  // Only one loop, need to continue on the next loop

				} // if distance < 0.01

				distance = 1.0 / distance;
				distances[ ir ] = distance;
				sum += distance;
				
			} // ir through NREGIONS

			if( ir < NREGIONS ) continue;  // Second break from above if.

			z = 0.0;
			for( ir = 0; ir < NREGIONS; ir++ )
				z += distances[ ir ] * stationLocations[ ir ][ 2 ];

			positions[ iy ][ ix ][ 2 ] = z / sum * ZSCALE;

			for( d = 0; d < nDays; d++ ) {
				a = s = h = p = w[ 0 ] = w[ 1 ] = 0.0;

				for( ir = 0; ir < NREGIONS; ir++ ) {

					a += distances[ ir ] * data[ ir ][ d ][ 6 ];
					s += distances[ ir ] * data[ ir ][ d ][ 14 ];
					p += distances[ ir ] * data[ ir ][ d ][ 10 ];
					h += distances[ ir ] * avgHumidity[ ir ][ d ];
					w[ 0 ] += distances[ ir ] * windVector[ ir ][ d ][ 0 ];
					w[ 1 ] += distances[ ir ] * windVector[ ir ][ d ][ 1 ];

				} // ir

				airTemp[ d ][ iy ][ ix ] = a / sum;
				soilTemp[ d ][ iy ][ ix ] = s / sum;
				precip[ d ][ iy ][ ix ] = p / sum;
				humidity[ d ][ iy ][ ix ] = h / sum;
				wind[ d ][ iy ][ ix ][ 0 ] = w[ 0 ] / sum;
				wind[ d ][ iy ][ ix ][ 1 ] = w[ 1 ] / sum;

			} // d through nDays
	
		} // ix through NX

	} // iy throught NY

	// Okay!  All calculations done - write it all out to the file!

	// First the grid coordinates

	for( d = 0; d < nDays; d++ ) // Kludgy way to put all the days in one file
		if( binary )
			fout.write( ( const char * ) positions, NX * NY * 3 * sizeof( float ) );
		else 
			for( iy = 0; iy < NY; iy++ )
				for( ix = 0; ix < NX; ix++ ) {
					for( i = 0; i < 3; i++ )
						fout << positions[ iy ][ ix ][ i ] << " ";
					fout << endl;
				}

	fout << "\nPOINT_DATA " << nPoints << endl;

	// Wind vector data

	fout << "VECTORS WindVector float\n";
	if( binary )
		fout.write( ( const char * ) wind, nDays * NX * NY * 3 * sizeof( float ) );
	else
		for( d = 0; d < nDays; d++ )
			for( iy = 0; iy < NY; iy++ )
				for( ix = 0; ix < NX; ix++ ) {
					for( i = 0; i < 3; i++ )
						fout << wind[ d ][ iy ][ ix ][ i ] << " ";
					fout << endl;
				}


	// Air Temperatures

	fout << "SCALARS AirTemp float 1\nLOOKUP_TABLE default\n";
	if( binary ) 
		fout.write( ( const char * ) airTemp, nDays * NY * NX * sizeof( float ) );
	else 
		for( d = 0; d < nDays; d++ )
			for( iy = 0; iy < NY; iy++ ) {
				for( ix = 0; ix < NX; ix++ )
					fout << airTemp[ d ][ iy ][ ix ] << " ";
				fout << endl;
			}

	// Soil Temperatures

	fout << "SCALARS SoilTemp float 1\nLOOKUP_TABLE default\n";
	if( binary )
		fout.write( ( const char * ) soilTemp, nDays * NY * NX * sizeof( float ) );
	else
		for( d = 0; d < nDays; d++ )
			for( iy = 0; iy < NY; iy++ ) {
				for( ix = 0; ix < NX; ix++ )
					fout << soilTemp[ d ][ iy ][ ix ] << " ";
				fout << endl;
			}

	// Relative Humidity

	fout << "SCALARS Humidity float 1\nLOOKUP_TABLE default\n";
	if( binary )
		fout.write( ( const char * ) humidity, nDays * NY * NX * sizeof( float ) );
	else
		for( d = 0; d < nDays; d++ )
			for( iy = 0; iy < NY; iy++ ) {
				for( ix = 0; ix < NX; ix++ )
					fout << humidity[ d ][ iy ][ ix ] << " ";
				fout << endl;
			}

	// Precipitation

	fout << "SCALARS Precipitation float 1\nLOOKUP_TABLE default\n";
	if( binary )
		fout.write( ( const char * ) precip, nDays * NY * NX * sizeof( float ) );
	else
		for( d = 0; d < nDays; d++ )
			for( iy = 0; iy < NY; iy++ ) {
				for( ix = 0; ix < NX; ix++ )
					fout << precip[ d ][ iy ][ ix ] << " ";
				fout << endl;
			}

	fout << endl;

	fout.close( );

	// Extra code to save positions in a vtk format file

	fout.open( "stationLocations.vtk" );

	fout << "# vtk DataFile Version 2.0\n";
	fout << "Autogenerated from " << argv[ 1 ] << " by " << argv[ 0 ] << endl;
	if( binary )
		fout << "BINARY\n";
	else
		fout << "ASCII\n";
	fout << "DATASET POLYDATA\n";
	fout << "POINTS " << NREGIONS << " float\n";
	if( binary )
		fout.write( ( const char * ) stationLocations, NREGIONS * sizeof( float ) );
	else
		for( ir = 0; ir < NREGIONS; ir++ ) {
			for( i = 0; i < 3; i++ )
				fout << stationLocations[ ir ][ i ] << " ";
			fout << endl;
		}

	fout << "POINTS " << NREGIONS << " float\n";
	if( binary )
		fout.write( ( const char * ) stationLocations, NREGIONS * sizeof( float ) );
	else
		for( ir = 0; ir < NREGIONS; ir++ ) {
			for( i = 0; i < 3; i++ )
				fout << stationLocations[ ir ][ i ] << " ";
			fout << endl;
		}

	fout.close( );

	return 0;

}// main