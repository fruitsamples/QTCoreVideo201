//---------------------------------------------------------------------------
//
//	File: QTCVOpenGLView.m
//
//  Abstract: Main view class
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

#import "QTCVOpenGLView.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation QTCVOpenGLView

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Application Startup

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (void) awakeFromNib
{
	geometry = kGeometryQuad;
	teapot   = nil;
	quad     = nil;
	fbo      = nil;
} // awakeFromNib

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) deleteOpenGLQuad
{
	if( quad )
	{
		[quad release];
		
		quad = nil;
	} // if
} // deleteOpenGLQuad

//---------------------------------------------------------------------------

- (void) deleteOpenGLTeapot
{
	if( teapot )
	{
		[teapot release];
		
		teapot = nil;
	} // if
} // deleteOpenGLTeapot

//---------------------------------------------------------------------------

- (void) deleteOpenGLFBO
{
	if( fbo )
	{
		[fbo release];
		
		fbo = nil;
	} // if
} // deleteOpenGLFBO

//---------------------------------------------------------------------------

- (void) deleteOpenGLResources
{
	[self deleteOpenGLQuad];
	[self deleteOpenGLTeapot];
	[self deleteOpenGLFBO];
} // deleteOpenGLResources

//---------------------------------------------------------------------------

- (void) cleanUp
{
	[self deleteOpenGLResources];
	[super cleanUp];
} // cleanUp

//---------------------------------------------------------------------------

- (void) dealloc 
{
	[self cleanUp];
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Draw into a OpenGL view

//---------------------------------------------------------------------------

- (void) drawObject
{
	if( geometry == kGeometryTeapot ) 
	{
		[teapot display];
	} // if
	else
	{
		[quad display];
	} // else
} // drawObject

//---------------------------------------------------------------------------

- (void) drawScene
{
	if( [self pixelBufferIsValid] )
	{
		// Update the framebuffer
		
		[fbo update:[self pixelBuffer]];
		
		// Set our viewport with the correct presperctive
		// Constant rotation of the 3D objects

		[self updateViewport];
		
		// Get the texture from the framebuffer
		
		[fbo bind];
		
		// Draw the 3D objects
		
		[self drawObject];
	} // if
} // drawScene

//---------------------------------------------------------------------------

- (void) drawRect:(NSRect)rect
{  
	[self drawBegin];
	
	[self drawScene];
	
	[self drawEnd];
} // drawRect

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Initialize OpenGL resources for a movie

//---------------------------------------------------------------------------

- (void) prepareOpenGLQuadForMovie:(const NSSize *)theFrameSize
{
	// Delete the old quad object
	
	[self deleteOpenGLQuad];
	
	// Instantiate a new quad object
	
	quad = [[OpenGLVBOQuad alloc] initVBOQuadWithSize:theFrameSize 
												 type:OpenGLVBOQuadDefault];
} // prepareOpenGLQuadForMovie

//---------------------------------------------------------------------------

- (void) prepareOpenGLTeapotForMovie:(const NSSize *)theFrameSize
{
	// Delete the old teapot object
	
	[self deleteOpenGLTeapot];
	
	// Instantiate a new teapot object
	
	teapot = [[OpenGLTeapot alloc] initTeapotWithPListInAppBundle:@"Teapot"
															 size:theFrameSize];
} // prepareOpenGLTeapotForMovie

//---------------------------------------------------------------------------

- (void) prepareOpenGLFBOForMovie:(const NSSize *)theFrameSize
{
	// Delete the old pbo object
	
	[self deleteOpenGLFBO];
	
	// Instantiate a new pbo object
	
	fbo = [[CVFBO alloc] initCVFBOWithSize:theFrameSize];
} // prepareOpenGLFBOForMovie

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Acquire OpenGL Resources

//---------------------------------------------------------------------------
//
// Concrete implementation in order to acquire OpenGL resources.
//
//---------------------------------------------------------------------------

- (void) prepareCVOpenGL
{
	NSSize frameSize = [self pixelBufferSize];

	[self prepareOpenGLQuadForMovie:&frameSize];
	[self prepareOpenGLTeapotForMovie:&frameSize];
	[self prepareOpenGLFBOForMovie:&frameSize];
} // prepareCVOpenGL

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------
//
// Geometry for drawing
//
//---------------------------------------------------------------------------

- (void) setGeometry:(const GeometryType)theGeometry;
{
	geometry = theGeometry;
} // setGeometry

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
