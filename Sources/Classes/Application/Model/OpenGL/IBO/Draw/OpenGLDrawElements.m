//---------------------------------------------------------------------------
//
//	File: OpenGLDrawElements.m
//
//  Abstract: Utility class to deserialize a property list that describes
//            a VBO draw elements parameters and draws an object using
//            the parameters values (cached in an array).
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

//---------------------------------------------------------------------------

#import "OpenGLDrawElements.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Macros

//---------------------------------------------------------------------------

#define BUFFER_OFFSET(i) ((GLushort *)NULL + (i))

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

struct OpenGLDEParams
{
	GLenum    mode;
	GLsizei   count;
	GLenum    type;
	GLushort  offset;
};

typedef struct OpenGLDEParams   OpenGLDEParams;
typedef struct OpenGLDEParams  *OpenGLDEParamsRef;

//---------------------------------------------------------------------------

struct OpenGLDrawElementsAttributes
{
	GLsizeiptr         count;
	GLsizeiptr         size;
	OpenGLDEParamsRef  params;
};

typedef struct OpenGLDrawElementsAttributes  OpenGLDrawElementsAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLDrawElements

//---------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	
	if( self )
	{
		drawElementsRef = (OpenGLDrawElementsAttributesRef)malloc(sizeof(OpenGLDrawElementsAttributes));
		
		if( drawElementsRef != NULL )
		{
			drawElementsRef->count  = 0;
			drawElementsRef->size   = 0;
			drawElementsRef->params = NULL; 
		} // if
	} // if
	
	return( self );
} // init

//---------------------------------------------------------------------------

- (void) dealloc
{
	if( drawElementsRef != NULL )
	{
		if( drawElementsRef->params != NULL )
		{
			free( drawElementsRef->params );
		} // if
		
		free( drawElementsRef );
		
		drawElementsRef = NULL;
	} // if
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

- (void) setDictionary:(NSDictionary *)theDictionary
{
	if( theDictionary )
	{
		if( drawElementsRef->params != NULL )
		{
			free( drawElementsRef->params );
			
			drawElementsRef->count  = 0;
			drawElementsRef->size   = 0;
			drawElementsRef->params = NULL;
		} // if
		
		NSDictionary *elements = [theDictionary objectForKey:@"Elements"];
		
		if( elements )
		{
			NSNumber *count = [elements objectForKey:@"Rows"]; 
			
			if( count )
			{
				drawElementsRef->count  = [count integerValue];
				drawElementsRef->size   = drawElementsRef->count * sizeof(OpenGLDEParams);
				drawElementsRef->params = (OpenGLDEParamsRef)malloc( drawElementsRef->size ); 
				
				if( drawElementsRef->params != NULL )
				{
					NSArray *table = [elements objectForKey:@"Table"];
					
					if( table )
					{
						NSArray *element;
						
						GLuint i = 0;
						
						for( element in table )
						{
							drawElementsRef->params[i].mode   = [[element objectAtIndex:0] intValue];
							drawElementsRef->params[i].count  = [[element objectAtIndex:1] intValue];
							drawElementsRef->params[i].type   = [[element objectAtIndex:2] intValue];
							drawElementsRef->params[i].offset = [[element objectAtIndex:3] intValue];
							
							i++;
						} // for
					} // if
				} // if
			} // if
		} // if
	} // if
} // setDictionary

//---------------------------------------------------------------------------

- (void) drawElements
{
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	{
		GLuint i;
		
		for( i = 0; i < drawElementsRef->count; i++ )
		{
			glDrawElements(drawElementsRef->params[i].mode,
						   drawElementsRef->params[i].count,
						   drawElementsRef->params[i].type,
						   BUFFER_OFFSET(drawElementsRef->params[i].offset));
		} // for
	}
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
} // drawElements

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
