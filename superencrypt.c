//
// TPCTF 2017
// 'Super Encryption' CTF Challenge
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

/*
[blynden@localhost tpctf] $ ./superenc "dufhyuc>bi{{f0|;vwh<~b5p5thjq6goj}"
Input: dufhyuc>bi{{f0|;vwh<~b5p5thjq6goj}
Output: tpctf{Y4Y_f0r_r3v3rse_3ngin33ring}
*/

void decrypt( char *input, char *output )
{
	// We don't have a carriage return atm so this is fine
	int length = strlen( input );

	// A temporary buffer for the first stage
	char first_output[ length ];
	memset( &first_output, 0, sizeof( first_output ) );

	// We do stage 3 first now to decrypt.
	int i = 0;

	// This'll swap our input 3 bytes at a time until it reaches the length
	while ( i + 3 < length )
	{
		first_output[ i + 2 ] = input[ i ];
		first_output[ i + 1 ] = input[ i + 1 ];
		first_output[ i ] = input[ i + 2 ];

		i += 3;
	}

	// There's a chance that i will still be less than our length as we increment
	// 3 bytes at a time, so we pad with the input string.
	while ( i < length )
	{
		strncpy( &first_output[ i ], &input[ i ], 2 );
		++i;
	}

	// A temporary buffer for the second stage
	char second_output[ length ];
	memset( &second_output, 0, sizeof( second_output ) );

	// And same swapping bs.
	i = 0;
	while ( i + 4 < length )
	{
		second_output[ i + 4 ] = first_output[ i ];
		second_output[ i + 3 ] = first_output[ i + 1 ];
		second_output[ i + 2 ] = first_output[ i + 2 ];
		second_output[ i + 1 ] = first_output[ i + 3 ];
		second_output[ i ] = first_output[ i + 4 ];

		i += 5;
	}

	while ( i < length )
	{
		strncpy( &second_output[ i ], &first_output[ i ], 2 );
		++i;
	}

	for ( i = 0; i != length; ++i )
	{
		// I had to steal this from Hex-Rays...
		int offset = floor( ( ( i + 22 ) / 2 ^ 0x1b ) % 11 );
		output[ i ] = second_output[ i ] - offset;
	}
}

int main( int argc, char **argv )
{
	if ( argc != 2 )
	{
		puts( "You need to specify the string to decrypt" );
		return EXIT_FAILURE;
	}

	char output[ 256 ] = {};

	char *input = strdup( argv[ 1 ] );
	decrypt( input, output );

	printf( "Input: %s\n", input );
	printf( "Output: %s\n", output );

	free( input );

	return 0;
}
