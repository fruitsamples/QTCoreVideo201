//---------------------------------------------------------------------------
//
//	File: OpenGLFBO.m
//
//  Abstract: Utility class for managing FBOs
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

#import "OpenGLTextureSourceTypes.h"
#import "OpenGLImageBuffer.h"
#import "OpenGLFBOStatus.h"
#import "OpenGLFBO.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLTextureAttributes
{
	GLuint             name;				// texture id
	GLint              level;				// level-of-detail	number
	GLint              border;				// width of the border, either 0  or 1
	GLint              xoffset;				// x offset for texture copy
	GLint              yoffset;				// y offset for texture copy
	GLenum             target;				// e.g., texture 2D or texture rectangle
	GLenum             hint;				// type of texture storage
	GLenum             format;				// format
	GLenum             internalFormat;		// internal format
	GLenum             type;				// OpenGL specific type
	OpenGLImageBuffer  buffer;				// An image buffer
};

typedef struct OpenGLTextureAttributes  OpenGLTextureAttributes;

//---------------------------------------------------------------------------

struct OpenGLFramebufferAttributes
{
	GLuint   name;			// Framebuffer object id
	GLenum   target;		// Framebuffer target
	GLenum   attachment;	// Color attachment "n" extension
	BOOL     isValid;		// Framebuffer status
};

typedef struct OpenGLFramebufferAttributes  OpenGLFramebufferAttributes;

//---------------------------------------------------------------------------

struct OpenGLRenderbufferAttributes
{
	GLuint   name;				// Depth renderbuffer id
	GLenum   internalFormat;	// Renderbuffer internal format
	GLenum   target;			// Target type for renderbuffer
	GLenum   attachment;		// Type of frameBufferAttachment for renderbuffer
};

typedef struct OpenGLRenderbufferAttributes  OpenGLRenderbufferAttributes;

//---------------------------------------------------------------------------

struct OpenGLViewportAttributes
{
	GLint    x;			// lower left x coordinate
	GLint    y;			// lower left y coordinate
	GLsizei  width;		// viewport height
	GLsizei  height;	// viewport width
};

typedef struct OpenGLViewportAttributes  OpenGLViewportAttributes;

//---------------------------------------------------------------------------

struct OpenGLOrthoProjAttributes
{
	GLdouble left;		// left vertical clipping plane
	GLdouble right;		// right vertical clipping plane
	GLdouble bottom;	// bottom horizontal clipping plane
	GLdouble top;		// top horizontal clipping plane
	GLdouble zNear;		// nearer depth clipping plane
	GLdouble zFar;		// farther depth clipping plane
};

typedef struct OpenGLOrthoProjAttributes  OpenGLOrthoProjAttributes;

//---------------------------------------------------------------------------

struct OpenGLFBOAttributes
{
	OpenGLOrthoProjAttributes     orthographic;		// Attributes for orthographic projection
	OpenGLViewportAttributes      viewport;			// FBO viewport dimensions
	OpenGLTextureAttributes       texture;			// Texture bound to the framebuffer
	OpenGLFramebufferAttributes   framebuffer;		// Framebuffer object attributes
	OpenGLRenderbufferAttributes  renderbuffer;		// Depth render buffer
};

typedef struct OpenGLFBOAttributes  OpenGLFBOAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------
//
// Some other initialization values may come from:
//
//		theAttributes->texture.target         = GL_TEXTURE_RECTANGLE_EXT;
//		theAttributes->texture.format         = GL_BGRA_EXT;
//		theAttributes->texture.internalFormat = GL_RGBA;
//
// For samples-per-pixel with OpenGL type GL_UNSIGNED_INT_8_8_8_8 or 
// GL_UNSIGNED_INT_8_8_8_8_REV:
//
//		theAttributes->texture.samplesPerPixel = 4;
//
//---------------------------------------------------------------------------

static void InitOpenGLTextureAttributes( const NSSize *theTextureSize, OpenGLFBOAttributesRef theAttributes )
{
	theAttributes->texture.name           = 0;
	theAttributes->texture.hint           = GL_STORAGE_PRIVATE_APPLE;
	theAttributes->texture.level          = 0;
	theAttributes->texture.border         = 0;
	theAttributes->texture.xoffset        = 0;
	theAttributes->texture.yoffset        = 0;
	theAttributes->texture.target         = GL_TEXTURE_RECTANGLE_ARB;
	theAttributes->texture.format         = kTextureSourceFormat;
	theAttributes->texture.type           = kTextureSourceType;
	theAttributes->texture.internalFormat = kTextureInternalFormat;
	
	theAttributes->texture.buffer.samplesPerPixel = kTextureMaxSPP;
	theAttributes->texture.buffer.width           = (GLuint)theTextureSize->width;
	theAttributes->texture.buffer.height          = (GLuint)theTextureSize->height;
	theAttributes->texture.buffer.rowBytes        = theAttributes->texture.buffer.width  * theAttributes->texture.buffer.samplesPerPixel;
	theAttributes->texture.buffer.size            = theAttributes->texture.buffer.height * theAttributes->texture.buffer.rowBytes;
	theAttributes->texture.buffer.data            = NULL;
} // InitOpenGLTextureAttributes

//---------------------------------------------------------------------------

static void InitOpenGLFramebufferAttributes( OpenGLFBOAttributesRef theAttributes )
{
	theAttributes->framebuffer.name       = 0;
	theAttributes->framebuffer.target     = GL_FRAMEBUFFER_EXT;
	theAttributes->framebuffer.attachment = GL_COLOR_ATTACHMENT0_EXT;
	theAttributes->framebuffer.isValid    = NO;
} // InitOpenGLFramebufferAttributes

//---------------------------------------------------------------------------

static void InitOpenGLRenderbufferAttributes( OpenGLFBOAttributesRef theAttributes )
{
	theAttributes->renderbuffer.name           = 0;
	theAttributes->renderbuffer.target         = GL_RENDERBUFFER_EXT;
	theAttributes->renderbuffer.internalFormat = GL_DEPTH_COMPONENT24;
	theAttributes->renderbuffer.attachment     = GL_DEPTH_ATTACHMENT_EXT;
} // InitOpenGLRenderbufferAttributes

//---------------------------------------------------------------------------

static void InitOpenGLViewportAttributes( OpenGLFBOAttributesRef theAttributes )
{
	theAttributes->viewport.x      = 0;
	theAttributes->viewport.y      = 0;
	theAttributes->viewport.width  = theAttributes->texture.buffer.width;
	theAttributes->viewport.height = theAttributes->texture.buffer.height;
} // InitOpenGLViewportAttributes

//---------------------------------------------------------------------------

static void InitOpenGLOrthoProjAttributes( OpenGLFBOAttributesRef theAttributes )
{
	theAttributes->orthographic.left   =  0;
	theAttributes->orthographic.right  =  theAttributes->texture.buffer.width;
	theAttributes->orthographic.bottom =  0;
	theAttributes->orthographic.top    =  theAttributes->texture.buffer.height;
	theAttributes->orthographic.zNear  = -10.0;
	theAttributes->orthographic.zFar   =  10.0;
} // InitOpenGLOrthoProjAttributes

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLFBO

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------

- (void) initOpenGLFramebuffer:(const NSSize *)theTextureSize
{
	InitOpenGLTextureAttributes( theTextureSize, fboAttribs );
	InitOpenGLViewportAttributes( fboAttribs );
	InitOpenGLOrthoProjAttributes( fboAttribs );
	InitOpenGLRenderbufferAttributes( fboAttribs );
	InitOpenGLFramebufferAttributes( fboAttribs );
} // initOpenGLFramebuffer

//---------------------------------------------------------------------------
//
// Initialize the fbo bound texture
//
//---------------------------------------------------------------------------	

- (BOOL) newOpenGLTexture
{
	BOOL createdTexture = NO;
	
	glDisable(GL_TEXTURE_2D);
	glEnable(fboAttribs->texture.target);
	
	glTextureRangeAPPLE(fboAttribs->texture.target, 0, NULL);
	glTextureRangeAPPLE(GL_TEXTURE_2D, 0, NULL);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_FALSE);
	
	glGenTextures(1, &fboAttribs->texture.name);
	
	if( fboAttribs->texture.name )
	{
		glBindTexture(fboAttribs->texture.target, fboAttribs->texture.name);
		
		glTexParameteri(fboAttribs->texture.target, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_PRIVATE_APPLE);
		glTexParameteri(fboAttribs->texture.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(fboAttribs->texture.target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(fboAttribs->texture.target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(fboAttribs->texture.target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		glTexImage2D(fboAttribs->texture.target, 
					 fboAttribs->texture.level,
					 fboAttribs->texture.internalFormat, 
					 fboAttribs->texture.buffer.width, 
					 fboAttribs->texture.buffer.height, 
					 fboAttribs->texture.border, 
					 fboAttribs->texture.format, 
					 fboAttribs->texture.type, 
					 fboAttribs->texture.buffer.data);
		
		createdTexture = YES;
	} // if
	
	return( createdTexture );
} // newOpenGLTexture

//---------------------------------------------------------------------------
//
// Initialize depth render buffer
//
//---------------------------------------------------------------------------

- (BOOL) newOpenGLRenderbuffer
{
	BOOL createdRenderbuffer = NO;
	
	glGenRenderbuffersEXT(1, &fboAttribs->renderbuffer.name);
	
	if( fboAttribs->renderbuffer.name )
	{
		glBindRenderbufferEXT(fboAttribs->renderbuffer.target, 
							  fboAttribs->renderbuffer.name);
		
		glRenderbufferStorageEXT(fboAttribs->renderbuffer.target, 
								 fboAttribs->renderbuffer.internalFormat, 
								 fboAttribs->texture.buffer.width, 
								 fboAttribs->texture.buffer.height);
		
		createdRenderbuffer = YES;
	} // if
	
	return( createdRenderbuffer );
} // newOpenGLRenderbuffer

//---------------------------------------------------------------------------
//
// Bind to FBO before checking status
//
//---------------------------------------------------------------------------

- (void) newOpenGLFramebuffer
{	
	glGenFramebuffersEXT(1, &fboAttribs->framebuffer.name);
	
	if( fboAttribs->framebuffer.name )
	{
		glBindFramebufferEXT(fboAttribs->framebuffer.target, fboAttribs->framebuffer.name);
		
		glFramebufferTexture2DEXT(fboAttribs->framebuffer.target, 
								  fboAttribs->framebuffer.attachment, 
								  fboAttribs->texture.target, 
								  fboAttribs->texture.name,
								  fboAttribs->texture.level);
		
		glFramebufferRenderbufferEXT(fboAttribs->framebuffer.target, 
									 fboAttribs->renderbuffer.attachment, 
									 fboAttribs->renderbuffer.target, 
									 fboAttribs->renderbuffer.name);
		
		glBindRenderbufferEXT(fboAttribs->renderbuffer.target, 0);
		glBindFramebufferEXT(fboAttribs->framebuffer.target, 0);
		
		fboAttribs->framebuffer.isValid = [[OpenGLFBOStatus statusWithFBOTarget:fboAttribs->framebuffer.target 
																		   exit:YES] framebufferComplete];
	} // if
} // newOpenGLFramebuffer

//---------------------------------------------------------------------------

- (void) newOpenGLFBO:(const NSSize *)theTextureSize
{
	[self initOpenGLFramebuffer:theTextureSize];
	
	if( [self newOpenGLTexture] )
	{		
		if( [self newOpenGLRenderbuffer] )
		{
			[self newOpenGLFramebuffer];
		} // if
	} // if
} // newOpenGLFBO

//---------------------------------------------------------------------------
//
// Initialize on startup
//
//---------------------------------------------------------------------------

- (id) initFBOWithSize:(const NSSize *)theTextureSize
{
	self = [super init];
	
	if( self )
	{
		fboAttribs = (OpenGLFBOAttributesRef)malloc( sizeof(OpenGLFBOAttributes) );
		
		if( fboAttribs != NULL )
		{
			[self newOpenGLFBO:theTextureSize];
		} // if
		else
		{
			NSLog( @">> ERROR: OpenGL FBO - Allocating Memory For FBO Attributes Failed!" );
		} // else
	} // if
	
	return  self;
} // initFBOWithSize

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Cleanup Resources

//---------------------------------------------------------------------------

- (void) cleanUpOpenGLRenderbuffer
{
	if( fboAttribs->renderbuffer.name )
	{
		glDeleteRenderbuffersEXT( 1, &fboAttribs->renderbuffer.name );
	} // if
} // cleanUpOpenGLRenderbuffer

//---------------------------------------------------------------------------

- (void) cleanUpOpenGLFramebuffer
{
	if( fboAttribs->framebuffer.name )
	{
		glDeleteFramebuffersEXT( 1, &fboAttribs->framebuffer.name );
	} // if
} // cleanUpOpenGLFramebuffer

//---------------------------------------------------------------------------

- (void) cleanUpOpenGLTexture
{
	if( fboAttribs->texture.name )
	{
		glDeleteTextures( 1, &fboAttribs->texture.name );
	} // if
} // cleanUpOpenGLTexture

//---------------------------------------------------------------------------

- (void) cleanUpOpenGLFBO
{
	if( fboAttribs != NULL )
	{
		[self cleanUpOpenGLRenderbuffer];
		[self cleanUpOpenGLFramebuffer];
		[self cleanUpOpenGLTexture];
		
		free( fboAttribs );
	} // if
} // cleanUpOpenGLFBO

//---------------------------------------------------------------------------

- (void) dealloc 
{
	[self  cleanUpOpenGLFBO];
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Reset Framebuffer

//---------------------------------------------------------------------------
//
// Reset the current viewport
//
//---------------------------------------------------------------------------

- (void) reset
{
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	
	glViewport(fboAttribs->viewport.x, 
			   fboAttribs->viewport.y, 
			   fboAttribs->viewport.width, 
			   fboAttribs->viewport.height);
	
	// select the projection matrix
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	// Orthographic projection
	
	glOrtho(fboAttribs->orthographic.left, 
			fboAttribs->orthographic.right, 
			fboAttribs->orthographic.bottom, 
			fboAttribs->orthographic.top, 
			fboAttribs->orthographic.zNear, 
			fboAttribs->orthographic.zFar);
	
	// Go back to texture and model-view modes
	
	glMatrixMode(GL_TEXTURE);
	glLoadIdentity();
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
} // reset

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Render-to-Texture

//---------------------------------------------------------------------------
//
// Default rendering method. Must be implemented upon subclassing.
//
//---------------------------------------------------------------------------

- (void) render
{
	return;
} // render

//---------------------------------------------------------------------------
//
// Update the framebuffer by using the implementation of "render" method.
// If the shader method is not implemented, the default implementation wiil
// be used whereby, the second texture is simply bound to a quad.
//
//---------------------------------------------------------------------------

- (void) update
{
	// bind buffers and make attachments
	
	glBindFramebufferEXT( fboAttribs->framebuffer.target, fboAttribs->framebuffer.name );
	glBindRenderbufferEXT( fboAttribs->renderbuffer.target, fboAttribs->renderbuffer.name );
	
	// we have a video frame so draw to fbo
	
	// reset the current viewport
	
	[self reset];
	
	// draw to FBO
	
	[self render];
	
	// unbind buffers
	
	glBindRenderbufferEXT( fboAttribs->renderbuffer.target, 0 ); 
	glBindFramebufferEXT( fboAttribs->framebuffer.target, 0 );
} // update

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------
//
// Bind the texture attached to a framebuffer, to a quad or surface.
//
//---------------------------------------------------------------------------

- (void) bind
{
	glBindTexture(fboAttribs->texture.target, 
				  fboAttribs->texture.name );
} // bind

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (GLuint) texture
{
	return(fboAttribs->texture.name);
} // texture

//---------------------------------------------------------------------------

- (GLenum) target
{
	return(fboAttribs->texture.target);
} // target

//---------------------------------------------------------------------------

- (GLvoid) setSize:(const NSSize *)theTextureSize
{
	GLuint width  = (GLuint)theTextureSize->width;
	GLuint height = (GLuint)theTextureSize->height;
	
	if(		( width  != fboAttribs->texture.buffer.width  ) 
	   ||	( height != fboAttribs->texture.buffer.height ) )
	{
		[self cleanUpOpenGLRenderbuffer];
		[self cleanUpOpenGLFramebuffer];
		[self cleanUpOpenGLTexture];
		
		[self newOpenGLFBO:theTextureSize];
	} // if
} // setSize

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
