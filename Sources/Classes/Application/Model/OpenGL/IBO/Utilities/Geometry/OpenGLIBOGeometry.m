//---------------------------------------------------------------------------
//
//	File: OpenGLIBOGeometry.m
//
//  Abstract: Utility class to deserialize a property list that describes
//            a IBO normals, vertices, colors, and texture coordinates.
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//  Computer, Inc. ("Apple") in consideration of your agreement to the
//  following terms, and your use, installation, modification or
//  redistribution of this Apple software constitutes acceptance of these
//  terms.  If you do not agree with these terms, please do not use,
//  install, modify or redistribute this Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Computer,
//  Inc. may be used to endorse or promote products derived from the Apple
//  Software without specific prior written permission from Apple.  Except
//  as expressly stated in this notice, no other rights or licenses, express
//  or implied, are granted by Apple herein, including but not limited to
//  any patent rights that may be infringed by your derivative works or by
//  other works in which the Apple Software may be incorporated.
//  
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//  
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// 
//  Copyright (c) 2009 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

#import "OpenGLIBOGeometry.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLArray
{
	GLsizeiptr   count;
	GLsizeiptr   size;
	GLfloat     *values;
};

typedef struct OpenGLArray   OpenGLArray;
typedef struct OpenGLArray  *OpenGLArrayRef;

//---------------------------------------------------------------------------

struct OpenGLIBOGeometryAttributes
{
	GLsizeiptr      count;
	GLsizeiptr      size;
	OpenGLArrayRef  arrays;
};

typedef struct OpenGLIBOGeometryAttributes   OpenGLIBOGeometryAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

static OpenGLIBOGeometryAttributesRef  OpenGLIBOGeometryCreateFromTable(const GLsizeiptr rowCount,
																		const GLsizeiptr rowSize,
																		NSArray *table)
{
	OpenGLIBOGeometryAttributesRef geometryRef = NULL;

	GLsizeiptr colCount = [table count];
	
	if( colCount > 0 )
	{
		geometryRef = (OpenGLIBOGeometryAttributesRef)malloc(sizeof(OpenGLIBOGeometryAttributes));
		
		if( geometryRef != NULL )
		{
			geometryRef->count  = colCount;
			geometryRef->size   = geometryRef->count * sizeof(OpenGLArray);
			geometryRef->arrays = (OpenGLArrayRef)malloc(geometryRef->size);
			
			if( geometryRef->arrays != NULL )
			{
				GLsizeiptr   colIndex;
				GLsizeiptr   rowIndex;
				NSArray     *column;
				NSNumber    *value;
				
				for( colIndex = 0; colIndex < geometryRef->count; colIndex++ )
				{
					geometryRef->arrays[colIndex].count  = rowCount;
					geometryRef->arrays[colIndex].size   = rowSize;
					geometryRef->arrays[colIndex].values = (GLfloat *)malloc( rowSize );
					
					if( geometryRef->arrays[colIndex].values != NULL )
					{
						column = [table objectAtIndex:colIndex];
						
						if( column )
						{
							for( rowIndex = 0; rowIndex < rowCount; rowIndex++ )
							{
								value = [column objectAtIndex:rowIndex];
								
								if( value )
								{
									geometryRef->arrays[colIndex].values[rowIndex] = [value floatValue];
								} // if
							} // for
						} // if
					} // if
				} // for
			} // if
		} // if
	} // if
	
	return( geometryRef );
} // OpenGLIBOGeometryCreateFromTable

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLIBOGeometry

//---------------------------------------------------------------------------

- (id) initGeometryWithDictionary:(NSDictionary *)theDictionary
{
	self = [super init];
	
	if( self )
	{
		NSDictionary *geometry = [theDictionary objectForKey:@"Geometry"];
		
		if( geometry )
		{
			NSNumber *rows = [geometry objectForKey:@"Rows"]; 
			
			if( rows )
			{
				GLsizeiptr rowCount = [rows integerValue];
				GLsizeiptr rowSize  = rowCount * sizeof(GLfloat);
				
				NSArray *table = [geometry objectForKey:@"Table"];
				
				if( table )
				{
					geometryRef = OpenGLIBOGeometryCreateFromTable(rowCount,rowSize,table);
				} // if
			} // if
		} // if
	} // if
	
	return( self );
} // initGeometryWithDictionary

//---------------------------------------------------------------------------

- (void) cleanUpIBOGeometry
{
	if( geometryRef != NULL )
	{
		if( geometryRef->arrays != NULL )
		{
			GLsizeiptr i;
			
			for( i = 0; i < geometryRef->count; i++ )
			{
				if( geometryRef->arrays[i].values != NULL )
				{
					free( geometryRef->arrays[i].values );
				} // if
			} // for
			
			free( geometryRef->arrays );
		} // if
		
		free( geometryRef );
		
		geometryRef = NULL;
	} // if
} // cleanUpIBOGeometry

//---------------------------------------------------------------------------

- (void) dealloc
{
	[self cleanUpIBOGeometry];
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

- (GLsizeiptr) count
{
	return( geometryRef->arrays[0].count );
} // count

//---------------------------------------------------------------------------

- (GLsizeiptr) size
{
	return( geometryRef->arrays[0].size );
} // size

//---------------------------------------------------------------------------

- (GLfloat *) normals
{
	return( geometryRef->arrays[0].values );
} // normals

//---------------------------------------------------------------------------

- (GLfloat *) vertices
{
	return( geometryRef->arrays[1].values );
} // vertices

//---------------------------------------------------------------------------

- (GLfloat *) colors
{
	return( geometryRef->arrays[2].values );
} // vertices

//---------------------------------------------------------------------------

- (GLfloat *) texcoords
{
	return( geometryRef->arrays[3].values );
} // vertices

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
