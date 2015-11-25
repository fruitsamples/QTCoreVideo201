//---------------------------------------------------------------------------
//
//	File: OpenGLVBOQuad.m
//
//  Abstract: Utility toolkit for handling a quad VBO
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
//  Copyright (c) 2008-2009 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLVBOQuad.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private Data Structures

//---------------------------------------------------------------------------

struct OpenGLVBOQuadAttributes
{
	GLuint    name;			// buffer identifier
	GLuint    count;		// vertex count
	GLuint    size;			// size of vertices or texture coordinates
	GLuint    capacity;		// vertex size + texture coordinate size
	GLsizei   stride;		// vbo stride
	GLenum    target;		// vbo target
	GLenum    usage;		// vbo usage
	GLenum    type;			// vbo type
	GLenum    mode;			// vbo mode
	GLfloat   width;		// quad width
	GLfloat   height;		// quad height
	GLfloat   aspect;		// aspect ratio
	GLfloat  *data;			// vbo data
	GLenum    quadType;		// vbo quad type
};

typedef struct OpenGLVBOQuadAttributes  OpenGLVBOQuadAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#define BUFFER_OFFSET(i) ((GLchar *)NULL + (i))

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLVBOQuad

//---------------------------------------------------------------------------

- (void) initVBOQuad:(const NSSize *)theSize
				type:(const OpenGLVBOQuadType)theType
{
	vboQuadAttribs->count    = 4;
	vboQuadAttribs->size     = 8 * sizeof(GLfloat);
	vboQuadAttribs->capacity = 2 * vboQuadAttribs->size;
	vboQuadAttribs->target   = GL_ARRAY_BUFFER;
	vboQuadAttribs->usage    = GL_STREAM_DRAW;
	vboQuadAttribs->type     = GL_FLOAT;
	vboQuadAttribs->mode     = GL_QUADS;
	vboQuadAttribs->stride   = 0;
	vboQuadAttribs->data     = NULL;
	vboQuadAttribs->width    = theSize->width;
	vboQuadAttribs->height   = theSize->height;
	vboQuadAttribs->aspect   = theSize->width / theSize->height;
	vboQuadAttribs->quadType = theType;
} // initVBOQuad

//---------------------------------------------------------------------------

- (void) newVBOQuad:(const GLfloat *)theVertices
		  texCoords:(const GLfloat *)theTexCoords
{
	glGenBuffers(1, &vboQuadAttribs->name);
	
	glBindBuffer(vboQuadAttribs->target, vboQuadAttribs->name);
	
	glBufferData(vboQuadAttribs->target, vboQuadAttribs->capacity, NULL, vboQuadAttribs->usage);
	glBufferSubData(vboQuadAttribs->target, 0, vboQuadAttribs->size, theVertices);
	glBufferSubData(vboQuadAttribs->target, vboQuadAttribs->size, vboQuadAttribs->size, theTexCoords);
	
	glBindBuffer(vboQuadAttribs->target, 0);
} // newVBOQuad

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	
	if( self )
	{
		vboQuadAttribs = (OpenGLVBOQuadAttributesRef)malloc(sizeof(OpenGLVBOQuadAttributes));
		
		if( vboQuadAttribs != NULL )
		{
			GLfloat data[8] = { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f };
			NSSize  size    = NSMakeSize( 0.0f, 0.0f );
			
			[self initVBOQuad:&size
						 type:OpenGLVBOQuadDefault];
			
			[self newVBOQuad:data 
				   texCoords:data];			
		} // if
		else
		{
			NSLog( @">> ERROR: OpenGL VBO Quad - Failure Allocating Memory For Attributes!" );
			NSLog( @">>                          From the default initializer." );
		}  // else
	} // if
	
	return( self );
} // init

//---------------------------------------------------------------------------

- (void) initVerticesWithSize:(const NSSize *)theSize
					 vertices:(GLfloat *)theVertices
{
	switch( vboQuadAttribs->quadType ) 
	{
		case OpenGLVBOQuadForTex:
		{
			theVertices[0]  = 0.0f;
			theVertices[1]  = 0.0f;
			theVertices[2]  = 0.0f;
			theVertices[3]  = theSize->height;
			theVertices[4]  = theSize->width;
			theVertices[5]  = theSize->height;
			theVertices[6]  = theSize->width;
			theVertices[7]  = 0.0f;
			
			break;
		}
		case OpenGLVBOQuadForVRTex:
		{
			theVertices[0]  = 0.0f;
			theVertices[1]  = theSize->height;
			theVertices[2]  = 0.0f;
			theVertices[3]  = 0.0f;
			theVertices[4]  = theSize->width;
			theVertices[5]  = 0.0f;
			theVertices[6]  = theSize->width;
			theVertices[7]  = theSize->height;
			
			break;
		}
		case OpenGLVBOQuadDefault:
		default:
		{
			theVertices[0]  = -1.0f;
			theVertices[1]  = -1.0f;
			theVertices[2]  = -1.0f;
			theVertices[3]  =  1.0f;
			theVertices[4]  =  1.0f;
			theVertices[5]  =  1.0f;
			theVertices[6]  =  1.0f;
			theVertices[7]  = -1.0f;
			
			break;
		}
	} // switch
} // initVerticesWithType

//---------------------------------------------------------------------------

- (id) initVBOQuadWithSize:(const NSSize *)theSize
					  type:(const OpenGLVBOQuadType)theType
{
	self = [super init];
	
	if( self )
	{
		vboQuadAttribs = (OpenGLVBOQuadAttributesRef)malloc(sizeof(OpenGLVBOQuadAttributes));
		
		if( vboQuadAttribs != NULL )
		{
			if( theSize != NULL )
			{
				GLfloat texCoords[8] = { 0.0f, 0.0f, 0.0f, theSize->height, theSize->width, theSize->height, theSize->width, 0.0f };
				GLfloat vertices[8];
				
				[self initVBOQuad:theSize 
							 type:theType];
				
				[self initVerticesWithSize:theSize
								  vertices:vertices];

				[self newVBOQuad:vertices 
					   texCoords:texCoords];		
			} // if
			else
			{
				GLfloat data[8] = { 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f };
				NSSize  size    = NSMakeSize( 0.0f, 0.0f );
				
				[self initVBOQuad:&size
							 type:OpenGLVBOQuadDefault];
				
				[self newVBOQuad:data 
					   texCoords:data];			
			} // else
		} // if
		else
		{
			NSLog( @">> ERROR: OpenGL VBO Quad - Failure Allocating Memory For Attributes!" );
			NSLog( @">>                          From the designated initializer using size." );
		}  // else
	} // if
	
	return( self );
} // initVBOWithSize

//---------------------------------------------------------------------------

+ (id) vboQuadWithSize:(const NSSize *)theSize
				  type:(const OpenGLVBOQuadType)theType
{
	return( [[[OpenGLVBOQuad allocWithZone:[self zone]] initVBOQuadWithSize:theSize 
																	   type:theType] autorelease] );
} // vboQuadWithSize

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Delete VBO

//---------------------------------------------------------------------------

- (void) cleanUpVBOQuad
{
	if( vboQuadAttribs != NULL )
	{
		if( vboQuadAttribs->name )
		{
			glDeleteBuffers( 1, &vboQuadAttribs->name );
		} // if
		
		free( vboQuadAttribs );
		
		vboQuadAttribs = NULL;
	} // if
} // cleanUpVBOQuad

//---------------------------------------------------------------------------

- (void) dealloc 
{
	[self cleanUpVBOQuad];

    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark VBO Update

//---------------------------------------------------------------------------

- (void) setType:(const OpenGLVBOQuadType)theType
{
	vboQuadAttribs->quadType = theType;
} // setType

//---------------------------------------------------------------------------

- (void) setSize:(const NSSize *)theSize
{
	if( theSize != NULL )
	{
		GLfloat texCoords[8] = { 0.0f, 0.0f, 0.0f, theSize->height, theSize->width, theSize->height, theSize->width, 0.0f };
		GLfloat vertices[8];
		
		[self initVerticesWithSize:theSize
						  vertices:vertices];

		vboQuadAttribs->width  = theSize->width;
		vboQuadAttribs->height = theSize->height;
		vboQuadAttribs->aspect = vboQuadAttribs->width / vboQuadAttribs->height;
		
		glBindBuffer(vboQuadAttribs->target, 
					 vboQuadAttribs->name);
		
		glBufferData(vboQuadAttribs->target, 
					 vboQuadAttribs->capacity, 
					 NULL, 
					 vboQuadAttribs->usage);
		
		vboQuadAttribs->data = (GLfloat *)glMapBuffer(vboQuadAttribs->target, GL_READ_WRITE);
		
		if( vboQuadAttribs->data != NULL )
		{
			// Vertices
			
			vboQuadAttribs->data[0] = vertices[0];
			vboQuadAttribs->data[1] = vertices[1];
			vboQuadAttribs->data[2] = vertices[2];
			vboQuadAttribs->data[3] = vertices[3];
			vboQuadAttribs->data[4] = vertices[4];
			vboQuadAttribs->data[5] = vertices[5],
			vboQuadAttribs->data[6] = vertices[6];
			vboQuadAttribs->data[7] = vertices[7];
			
			// Texture coordinates
			
			vboQuadAttribs->data[8]  = texCoords[0];
			vboQuadAttribs->data[9]  = texCoords[1];
			vboQuadAttribs->data[10] = texCoords[2];
			vboQuadAttribs->data[11] = texCoords[3];
			vboQuadAttribs->data[12] = texCoords[4];
			vboQuadAttribs->data[13] = texCoords[5],
			vboQuadAttribs->data[14] = texCoords[6];
			vboQuadAttribs->data[15] = texCoords[7];
			
			glUnmapBuffer(vboQuadAttribs->target);
		} // if
		
		glBindBuffer(vboQuadAttribs->target, 0);
	} // if
} // setSize

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark VBO Draw

//---------------------------------------------------------------------------
//
// Draw a quad using texture & vertex coordinates
//
//---------------------------------------------------------------------------

- (void) display
{
	glBindBuffer(vboQuadAttribs->target, vboQuadAttribs->name);
	{
		glPushMatrix();
		{
			if( vboQuadAttribs->quadType == OpenGLVBOQuadDefault )
			{
				glScalef( vboQuadAttribs->aspect, 1.0f, 1.0f );
			} // if
			
			glEnableClientState(GL_TEXTURE_COORD_ARRAY);
			glEnableClientState(GL_VERTEX_ARRAY);
			{
				glTexCoordPointer(2, vboQuadAttribs->type, vboQuadAttribs->stride, BUFFER_OFFSET(vboQuadAttribs->size));
				glVertexPointer(2, vboQuadAttribs->type, vboQuadAttribs->stride, BUFFER_OFFSET(0));
				
				glDrawArrays(vboQuadAttribs->mode, 0, vboQuadAttribs->count);
			}
			glDisableClientState(GL_VERTEX_ARRAY);
			glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		}
		glPopMatrix();
	}
	glBindBuffer(vboQuadAttribs->target, 0);
} // display

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
