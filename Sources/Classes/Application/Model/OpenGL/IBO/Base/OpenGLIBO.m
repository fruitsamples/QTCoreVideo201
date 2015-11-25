//---------------------------------------------------------------------------
//
//	File: OpenGLIBO.m
//
//  Abstract: Class that implements a method for generating a
//            surface using IBOs.
//
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Apple Inc. ("Apple") in consideration of your agreement to the
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
//  Neither the name, trademarks, service marks or logos of Apple Inc.
//  may be used to endorse or promote products derived from the Apple
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

#import "OpenGLIBO.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLVertexAttributes
{
	GLuint         buffer;
	GLsizeiptr     size;
	GLenum         type;
	GLenum         target;
	GLenum         usage;
	GLenum         access;
	GLsizei        stride;
	GLint          count;
	const GLvoid  *data;
};

typedef struct OpenGLVertexAttributes  OpenGLVertexAttributes;

//---------------------------------------------------------------------------

struct OpenGLNormalAttributes
{
	GLuint         buffer;
	GLsizeiptr     size;
	GLintptr       offset;
	GLenum         type;
	GLenum         target;
	GLenum         usage;
	const GLvoid  *data;
};

typedef struct OpenGLNormalAttributes  OpenGLNormalAttributes;

//---------------------------------------------------------------------------

struct OpenGLIndexAttributes
{
	GLuint         buffer;
	GLsizeiptr     size;
	GLenum         type;
	GLenum         target;
	GLenum         usage;
	GLsizei        stride;
	const GLshort *data;
};

typedef struct OpenGLIndexAttributes  OpenGLIndexAttributes;

//---------------------------------------------------------------------------

struct OpenGLIBOAttributes
{
	OpenGLVertexAttributes  vertices;
	OpenGLNormalAttributes  normals;
	OpenGLIndexAttributes   indices;
	GLsizeiptr              size;
};

typedef struct OpenGLIBOAttributes   OpenGLIBOAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Macros

//---------------------------------------------------------------------------

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------

static OpenGLIBOAttributesRef OpenGLIBOCreate(const GLenum type)
{
	OpenGLIBOAttributesRef ibo = (OpenGLIBOAttributesRef)malloc( sizeof(OpenGLIBOAttributes) );
	
	if( ibo != NULL )
	{
		ibo->size = 0;
		
		ibo->vertices.buffer = 0;
		ibo->vertices.count  = 3;
		ibo->vertices.stride = 0;
		ibo->vertices.size   = 0;
		ibo->vertices.type   = type;
		ibo->vertices.target = GL_ARRAY_BUFFER;
		ibo->vertices.usage  = GL_STREAM_DRAW;
		ibo->vertices.access = GL_READ_WRITE;
		ibo->vertices.data   = NULL;
		
		ibo->normals.buffer = 0;
		ibo->normals.offset = 0;
		ibo->normals.size   = 0;
		ibo->normals.type   = type;
		ibo->normals.target = GL_ARRAY_BUFFER;
		ibo->normals.usage  = GL_STREAM_DRAW;
		ibo->normals.data   = NULL;
		
		ibo->indices.buffer = 0;
		ibo->indices.stride = 0;
		ibo->indices.size   = 0;
		ibo->indices.type   = GL_SHORT;
		ibo->indices.target = GL_ELEMENT_ARRAY_BUFFER;
		ibo->indices.usage  = GL_STATIC_DRAW;
		ibo->indices.data   = NULL;
	} // if
	
	return( ibo );
} // OpenGLIBOCreate

//---------------------------------------------------------------------------
//
// Release all buffers
//
//---------------------------------------------------------------------------

static void OpenGLIBORelease(OpenGLIBOAttributesRef ibo)
{
	if( ibo != NULL )
	{
		if( ibo->vertices.buffer )
		{
			glDeleteBuffers( 1, &ibo->vertices.buffer );
		} // if
		
		if( ibo->indices.buffer )
		{
			glDeleteBuffers( 1, &ibo->indices.buffer );
		} // if
		
		free( ibo );
		
		ibo = NULL;
	} // if
} // OpenGLIBORelease

//---------------------------------------------------------------------------
//
// Create a vertex buffer objects. Try to put both vertex coordinates 
// and normal arrays in the same buffer object.
//
//---------------------------------------------------------------------------

static BOOL OpenGLIBOAcquire(OpenGLIBOAttributesRef ibo)
{
	BOOL isValid = NO;
	
	glGenBuffersARB(1, &ibo->vertices.buffer);
	
	if( ibo->vertices.buffer )
	{
		ibo->normals.buffer = ibo->vertices.buffer;
		
		ibo->size = ibo->vertices.size + ibo->normals.size;
		
		glBindBuffer(ibo->vertices.target, ibo->vertices.buffer);
		
		glBufferData(ibo->vertices.target, 
					 ibo->size, 
					 0, 
					 ibo->vertices.usage);
		
		glBufferSubData(ibo->vertices.target, 
						0, 
						ibo->vertices.size, 
						ibo->vertices.data);
		
		glBufferSubData(ibo->normals.target, 
						ibo->vertices.size, 
						ibo->normals.size, 
						ibo->normals.data);
		
		// Create a VBO for an index array.
		//
		// Target of this VBO is GL_ELEMENT_ARRAY_BUFFER
		// and usage is GL_STATIC_DRAW
		
		glGenBuffers(1, &ibo->indices.buffer);
		
		if( ibo->indices.buffer )
		{
			glBindBuffer( ibo->indices.target, ibo->indices.buffer );
			
			glBufferData(ibo->indices.target, 
						 ibo->indices.size, 
						 ibo->indices.data, 
						 ibo->indices.usage);
			
			isValid = YES;
		} // if
		else 
		{
			glDeleteBuffers(1, &ibo->vertices.buffer);
		} // else
	} // if
	
	return( isValid );
} // OpenGLIBOAcquire

//---------------------------------------------------------------------------
//
// Bind to display the geometry
//
//---------------------------------------------------------------------------

static void OpenGLIBOBind(OpenGLIBOAttributesRef ibo)
{
	glBindBuffer(ibo->vertices.target, ibo->vertices.buffer);
	
	glNormalPointer(ibo->vertices.type, 0, BUFFER_OFFSET(ibo->normals.offset));
	glVertexPointer(ibo->vertices.count, ibo->vertices.type, ibo->vertices.stride, BUFFER_OFFSET(0));
	
	glBindBuffer(ibo->indices.target, ibo->indices.buffer);
	glIndexPointer(ibo->indices.type, ibo->indices.stride, BUFFER_OFFSET(0));
} // OpenGLIBOBind

//---------------------------------------------------------------------------
//
// Unbind to revert back to the original state(s)
//
//---------------------------------------------------------------------------

static void OpenGLIBOUnbind(OpenGLIBOAttributesRef ibo)
{
	glBindBuffer(ibo->indices.target, 0);
	glBindBuffer(ibo->vertices.target, 0);
} // OpenGLIBOUnbind

//---------------------------------------------------------------------------
//
// Update the vertices in an IBO.
//
//---------------------------------------------------------------------------

static void OpenGLIBOCopy(const GLvoid *thePtr,
						  const GLsizeiptr theSize,
						  const GLsizeiptr theOffset,
						  OpenGLIBOAttributesRef ibo)
{
	if( ( theSize + theOffset ) < ibo->size )
	{
		glBindBuffer(ibo->vertices.target, ibo->vertices.buffer);
		
		GLvoid *ptr = glMapBuffer(ibo->vertices.target, 
								  ibo->vertices.access);
		
		if( ptr != NULL )
		{
			if( theOffset > 0 )
			{
				ptr += theOffset;
			} // if
			
			memcpy(ptr, thePtr, theSize);
			
			glUnmapBuffer(ibo->vertices.target);
		} // if
		
		glBindBuffer(ibo->vertices.target, 0);
	} // if
} // OpenGLIBOCopy

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLIBO

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------

- (id) initIBOWithType:(const GLenum)theType
{
	self = [super init];
	
	if( self )
	{
		ibo = OpenGLIBOCreate(theType);
	} // if
	
	return  self;
} // initIBOWithVertices

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc
{
	OpenGLIBORelease(ibo);
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Setters

//---------------------------------------------------------------------------

- (void) setVertices:(const GLvoid *)theVertices
				size:(const GLsizeiptr)theVerticesSize
{
	ibo->vertices.data = theVertices;
	ibo->vertices.size = theVerticesSize;
} // setVertices

//---------------------------------------------------------------------------

- (void) setNormals:(const GLvoid *)theNormals
			   size:(const GLsizeiptr)theNormalsSize
			 offset:(const GLsizeiptr)theNormalsOffset
{
	ibo->normals.data   = theNormals;
	ibo->normals.size   = theNormalsSize;
	ibo->normals.offset = theNormalsOffset;
} // setNormals

//---------------------------------------------------------------------------

- (void) setIndices:(const GLshort *)theIndices
			   size:(const GLsizeiptr)theIndicesSize
{
	ibo->indices.data = theIndices;
	ibo->indices.size = theIndicesSize;
} // setNormals

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (void) acquire
{
	OpenGLIBOAcquire(ibo);
} // acquire

//---------------------------------------------------------------------------

- (void) bind
{
	OpenGLIBOBind(ibo);
} // bind

//---------------------------------------------------------------------------

- (void) unbind
{
	OpenGLIBOUnbind(ibo);
} // unbind

//---------------------------------------------------------------------------
//
// Copy an array of vertices into an acquired IBO.
//
//---------------------------------------------------------------------------

- (void) copyVertices:(const GLvoid *)theVertices
				 size:(const GLsizeiptr)theVerticesSize
{
	OpenGLIBOCopy(theVertices, theVerticesSize, 0, ibo);
} // copyVertices

//---------------------------------------------------------------------------
//
// Copy an array of normals into an acquired IBO.
//
//---------------------------------------------------------------------------

- (void) copyNormals:(const GLvoid *)theNormals
				size:(const GLsizeiptr)theNormalsSize
			  offset:(const GLsizeiptr)theNormalsOffset
{
	OpenGLIBOCopy(theNormals, theNormalsSize, theNormalsOffset, ibo);
} // copyNormals

//---------------------------------------------------------------------------
//
// Upon subclassing, implement this method to update vertices in an
// acquired IBO.
//
//---------------------------------------------------------------------------

- (void) updateVertices:(const GLvoid *)theVertexPtr
{
	return;
} // updateVertices

//---------------------------------------------------------------------------
//
// After implementing the vertex update method, call this method.
//
//---------------------------------------------------------------------------

- (void) mapVertices:(const GLsizeiptr)theVertexOffset
{
	if( ( theVertexOffset >= 0 ) && ( theVertexOffset < ibo->vertices.size ) )
	{
		glBindBuffer(ibo->vertices.target, ibo->vertices.buffer);
		
		GLvoid *ptr = glMapBuffer(ibo->vertices.target, 
								  ibo->vertices.access);
		
		if( ptr != NULL )
		{
			if( theVertexOffset > 0 )
			{
				ptr += theVertexOffset;
			} // if

			[self updateVertices:ptr];
			
			glUnmapBuffer(ibo->vertices.target);
		} // if
		
		glBindBuffer(ibo->vertices.target, 0);
	} // if
} // mapVertices

//---------------------------------------------------------------------------
//
// Upon subclassing, implement this method to update normals in an
// acquired IBO.
//
//---------------------------------------------------------------------------

- (void) updateNormals:(const GLvoid *)theNormalsPtr
{
	return;
} // updateNormals

//---------------------------------------------------------------------------
//
// After implementing the normals update method, call this method.
//
//---------------------------------------------------------------------------

- (void) mapNormals:(const GLsizeiptr)theNormalsOffset
{
	GLsizeiptr  pos = theNormalsOffset + ibo->vertices.size;
	
	if( ( theNormalsOffset >= 0 ) && ( pos < ibo->size ) )
	{
		glBindBuffer(ibo->vertices.target, ibo->vertices.buffer);
		
		GLvoid *ptr = glMapBuffer(ibo->vertices.target, 
								  ibo->vertices.access);
		
		if( ptr != NULL )
		{
			ptr += pos;
			
			[self updateNormals:ptr];
			
			glUnmapBuffer(ibo->vertices.target);
		} // if
		
		glBindBuffer(ibo->vertices.target, 0);
	} // if
} // mapNormals

//---------------------------------------------------------------------------
//
// Upon subclassing, implement this method to update vertices & normals in 
// an acquired IBO.
//
//---------------------------------------------------------------------------

- (void) update:(const GLvoid *)thePtr
{
	return;
} // update

//---------------------------------------------------------------------------
//
// After implementing the vertices & normals update method, call this method.
//
//---------------------------------------------------------------------------

- (void) map
{
	glBindBuffer(ibo->vertices.target, ibo->vertices.buffer);
	
	GLvoid *ptr = glMapBuffer(ibo->vertices.target, 
							  ibo->vertices.access);
	
	if( ptr != NULL )
	{
		[self update:ptr];
		
		glUnmapBuffer(ibo->vertices.target);
	} // if
	
	glBindBuffer(ibo->vertices.target, 0);
} // map

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------


