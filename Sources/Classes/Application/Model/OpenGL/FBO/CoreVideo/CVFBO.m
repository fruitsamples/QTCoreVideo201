//---------------------------------------------------------------------------
//
//	File: CVFBO.m
//
//  Abstract: Utility class for managing FBOs using CoreVideo opaque
//            texture references
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

#import "CVFBO.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct CVFBOAttributes
{
	GLfloat             width;		// quad width
	GLfloat             height;		// quad height
	CVOpenGLTextureRef  image;		// texture reference
};

typedef struct CVFBOAttributes  CVFBOAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation CVFBO

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------

- (void) newOpenGLQuadsWithSize:(const NSSize *)theSize
{
	cvFBOAttribs->width  = theSize->width;
	cvFBOAttribs->height = theSize->height;

	// A Quad, when using CoreVideo clean texture coordinates
	
	quads[0] = [[OpenGLVBOQuad alloc] initVBOQuadWithSize:theSize 
													 type:OpenGLVBOQuadForTex];
	
	quads[1] = [[OpenGLVBOQuad alloc] initVBOQuadWithSize:theSize 
													 type:OpenGLVBOQuadForVRTex];
} // newOpenGLQuads

//---------------------------------------------------------------------------
//
// Initialize on startup
//
//---------------------------------------------------------------------------

- (id) initCVFBOWithSize:(const NSSize *)theSize
{
	self = [super initFBOWithSize:theSize];
	
	if( self )
	{
		cvFBOAttribs = (CVFBOAttributesRef)malloc( sizeof(CVFBOAttributes) );
		
		if( cvFBOAttribs != NULL )
		{
			cvFBOAttribs->image = NULL;

			[self newOpenGLQuadsWithSize:theSize];
		} // if
		else
		{
			NSLog( @">> ERROR: CoreVideo FBO - Allocating Memory For CoreVideo FBO Attributes Failed!" );
		} // else
	} // if
	
	return  self;
} // initCVFBOWithSize

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) cleanUpOpenGLQuads
{
	if( quads[0] )
	{
		[quads[0] release];
	} // if

	if( quads[1] )
	{
		[quads[1] release];
	} // if
} // cleanUpQuads

//---------------------------------------------------------------------------

- (void) cleanUpCVTexture
{
	if( cvFBOAttribs->image != NULL )
	{
		CVOpenGLTextureRelease( cvFBOAttribs->image );
		
		cvFBOAttribs->image = NULL;
	} // if
} // cleanUpCVTexture

//---------------------------------------------------------------------------

- (void) cleanUpCVFBO
{
	[self cleanUpOpenGLQuads];

	if( cvFBOAttribs != NULL )
	{
		[self cleanUpCVTexture];
		
		free( cvFBOAttribs );
	} // if
} // cleanUpOpenGLFBO

//---------------------------------------------------------------------------

- (void) dealloc 
{
	[self cleanUpCVFBO];
	
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Render to texture

//---------------------------------------------------------------------------

- (void) render
{
	// get the texture target
	
	GLenum target = CVOpenGLTextureGetTarget( cvFBOAttribs->image );
	
	// get the texture target name
	
	GLint name = CVOpenGLTextureGetName( cvFBOAttribs->image );
	
	// bind to the CoreVideo texture
	
	glBindTexture( target, name );

	// draw the quad
	
	NSUInteger quadIndex = CVOpenGLTextureIsFlipped( cvFBOAttribs->image );
	
	[quads[quadIndex] display];

	// Unbind the CoreVideo texture
	
	glBindTexture( target, 0 );
} // render

//---------------------------------------------------------------------------
//
// Render frame provided by Core Video to the framebuffer
//
//---------------------------------------------------------------------------

- (void) update:(CVOpenGLTextureRef)theCVOpenGLTexture
{
	// Set to the new texture reference
	
	CVOpenGLTextureRelease( cvFBOAttribs->image );
	CVOpenGLTextureRetain( theCVOpenGLTexture );
	
	cvFBOAttribs->image = theCVOpenGLTexture;
	
	// Update the framebuffer

	[self update];
} // update

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (void) setSize:(const NSSize *)theSize
{
	GLfloat width  = (GLuint)theSize->width;
	GLfloat height = (GLuint)theSize->height;
	
	if(		( width  != cvFBOAttribs->width  ) 
	   ||	( height != cvFBOAttribs->height ) )
	{
		[self cleanUpOpenGLQuads];
		[self newOpenGLQuadsWithSize:theSize];
		
		[super setSize:theSize];
	} // if
} // setSize

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
