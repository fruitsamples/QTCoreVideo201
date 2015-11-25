//---------------------------------------------------------------------------
//
//	File: OpenGLView.m
//
//  Abstract: OpenGL view base class
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

#import <math.h>

//---------------------------------------------------------------------------

#import "OpenGLPixelFormat.h"
#import "OpenGLView.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constants

//---------------------------------------------------------------------------

static const unichar kESCKey = 27;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constants

//---------------------------------------------------------------------------

static const GLdouble kViewRotationDegreesPerSecond = 30.0;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLClippingPlanes
{
	GLdouble scale;		// Scale factor
	GLdouble aspect;	// Aspect ratio
	GLdouble left;		// Coordinate for the left vertical clipping plane
	GLdouble right;		// Coordinate for the right vertical clipping plane
	GLdouble bottom;	// Coordinate for the bottom horizontal clipping plane
	GLdouble top;		// Coordinate for the top horizontal clipping plane
	GLdouble zNear;		// Distance to the near depth clipping plane
	GLdouble zFar;		// Distance to the far depth clipping plane
};

typedef struct OpenGLClippingPlanes  OpenGLClippingPlanes;

//---------------------------------------------------------------------------

struct OpenGLViewport
{
	NSPoint  mousePoint;	// last place the mouse was
	GLfloat	 zoom;			// zooming within a viewport
	NSRect   bounds;		// view bounds
};

typedef struct OpenGLViewport  OpenGLViewport;

//---------------------------------------------------------------------------

struct OpenGLViewAttributes
{
	OpenGLViewport        viewport;		// viewport parameters
	OpenGLClippingPlanes  planes;		// clipping planes
};

typedef struct OpenGLViewAttributes  OpenGLViewAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLView

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------

- (void) initFullScreen
{
	fullScreenOptions = [[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]  
													 forKey:NSFullScreenModeSetting] retain];
	
	fullScreen = [[NSScreen mainScreen] retain];
} // initFullScreen

//---------------------------------------------------------------------------
//
// Turn on VBL syncing for swaps
//
//---------------------------------------------------------------------------

- (void) initSyncToVBL:(NSOpenGLContext *)theContext
{	
	GLint syncVBL = 1;
	
	[theContext setValues:&syncVBL 
			 forParameter:NSOpenGLCPSwapInterval];
} // initSyncToVBL

//---------------------------------------------------------------------------
//
// Initialize for 3D object animation
//
//---------------------------------------------------------------------------

- (void) initAnimation
{	
	animation = [[OpenGLAnimation alloc] initAnimationWithDegreesPerSecond:kViewRotationDegreesPerSecond];
} // initAnimation

//---------------------------------------------------------------------------
//
// Initialize OpenGL viewport parameters
//
//---------------------------------------------------------------------------

- (void) initViewport
{	
	glViewAttribs->viewport.mousePoint.x       = 0.0f;
	glViewAttribs->viewport.mousePoint.y       = 0.0f;
	glViewAttribs->viewport.zoom               = 1.0f;
	glViewAttribs->viewport.bounds.origin.x    = 0.0f;
	glViewAttribs->viewport.bounds.origin.y    = 0.0f;
	glViewAttribs->viewport.bounds.size.width  = 0.0f;
	glViewAttribs->viewport.bounds.size.height = 0.0f;
} // initViewport

//---------------------------------------------------------------------------
//
// Initialize OpenGL clipping planes' parameters
//
//---------------------------------------------------------------------------

- (void) initClippingPlanes
{	
	glViewAttribs->planes.scale  =  0.5;
	glViewAttribs->planes.aspect =  0.0;
	glViewAttribs->planes.left   =  0.0;
	glViewAttribs->planes.right  =  0.0;
	glViewAttribs->planes.bottom =  0.0;
	glViewAttribs->planes.top    =  0.0;
	glViewAttribs->planes.zNear  =  1.0;
	glViewAttribs->planes.zFar   = 10.0;
} // initClippingPlanes

//---------------------------------------------------------------------------
//
// Initialize OpenGL view attributes
//
//---------------------------------------------------------------------------

- (void) initOpenGLView
{
	glViewAttribs = (OpenGLViewAttributesRef)malloc( sizeof(OpenGLViewAttributes) );
	
	if( glViewAttribs != NULL )
	{
		[self initViewport];
		[self initClippingPlanes];
	} // if
	else
	{
		NSLog( @">> ERROR: OpenGL View - Allocating Memory For OpenGL View Attributes Failed!" );
	} // else
} // initOpenGLView

//---------------------------------------------------------------------------

- (id) initWithFrame:(NSRect)frameRect
{	
	NSOpenGLPixelFormat  *pixelFormat = [[OpenGLPixelFormat pixelFormatWithPListInAppBundle:@"PixelFormat"] pixelFormat];
	
	if( pixelFormat )
	{
		self = [super initWithFrame:frameRect 
						pixelFormat:pixelFormat];
		
		if( self )
		{
			NSOpenGLContext *context = [self openGLContext];
			
			if( context )
			{
				[self initFullScreen];
				[self initSyncToVBL:context];
				[self initAnimation];
				[self initOpenGLView];
			} // if
		} // if
	} // if
	
	return( self );
} // initWithFrame

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Prepare

//---------------------------------------------------------------------------

- (void) prepareOpenGL
{
	// shading mathod: GL_SMOOTH or GL_FLAT
    glShadeModel(GL_SMOOTH);
	
	// 4-byte pixel alignment
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
	
	//-----------------------------------------------------------------
	//
	// For some OpenGL implementations, texture coordinates generated 
	// during rasterization aren't perspective correct. However, you 
	// can usually make them perspective correct by calling the API
	// glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST).  Colors 
	// generated at the rasterization stage aren't perspective correct 
	// in almost every OpenGL implementation, / and can't be made so. 
	// For this reason, you're more likely to encounter this problem 
	// with colors than texture coordinates.
	//
	//-----------------------------------------------------------------
	
	glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);
	
	// Set up the projection
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	glFrustum(-0.3, 0.3, 0.0, 0.6, 1.0, 8.0);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glTranslatef(0.0f, 0.0f, -2.0f);
	
	// Turn on depth test
    glEnable(GL_DEPTH_TEST);
	
	// track material ambient and diffuse from surface color, 
	// call it before glEnable(GL_COLOR_MATERIAL)
	
    glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);
    glEnable(GL_COLOR_MATERIAL);
	
	// Clear to black nothing fancy.
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	
	// clear stencil buffer
    glClearStencil(0);
	
	// 0 is near, 1 is far
    glClearDepth(1.0f);

    glDepthFunc(GL_LEQUAL);
	
	// Setup blending function 
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
} // prepareOpenGL

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------
//
// It's important to clean up our rendering objects before we terminate -- 
// Cocoa will not specifically release everything on application termination, 
// so we explicitly call our clean up routine ourselves.
//
//---------------------------------------------------------------------------

- (void) cleanUp
{
	if( fullScreenOptions )
	{
		[fullScreenOptions release];
		
		fullScreenOptions = nil;
	} // if
	
	if( fullScreen )
	{
		[fullScreen release];
		
		fullScreen = nil;
	} // if
	
	if( animation )
	{
		[animation release];
		
		animation = nil;
	} // if

	if( glViewAttribs != NULL )
	{
		free( glViewAttribs );
		
		glViewAttribs = NULL;
	} // if
} // cleanUp

//---------------------------------------------------------------------------

- (void) dealloc 
{
	[self cleanUp];
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Basic Setup

//---------------------------------------------------------------------------

- (void) setPrespective
{
	glViewAttribs->viewport.bounds =  [self bounds];
	glViewAttribs->planes.aspect   =  glViewAttribs->viewport.bounds.size.width / glViewAttribs->viewport.bounds.size.height;
	glViewAttribs->planes.right    =  glViewAttribs->planes.aspect * glViewAttribs->planes.scale * glViewAttribs->viewport.zoom;
	glViewAttribs->planes.left     = -glViewAttribs->planes.right;
	glViewAttribs->planes.top      =  glViewAttribs->planes.scale * glViewAttribs->viewport.zoom;
	glViewAttribs->planes.bottom   = -glViewAttribs->planes.top;
	
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();
	
	glFrustum(glViewAttribs->planes.left, 
			  glViewAttribs->planes.right, 
			  glViewAttribs->planes.bottom, 
			  glViewAttribs->planes.top, 
			  glViewAttribs->planes.zNear, 
			  glViewAttribs->planes.zFar );
	
	glMatrixMode( GL_MODELVIEW );
	glLoadIdentity();
} // setPrespective

//---------------------------------------------------------------------------

- (void) setViewport
{
	GLint    x      = (GLint)lrintf(glViewAttribs->viewport.bounds.origin.x);
	GLint    y      = (GLint)lrintf(glViewAttribs->viewport.bounds.origin.y);
	GLsizei  width  = (GLsizei)lrintf(glViewAttribs->viewport.bounds.size.width);
	GLsizei  height = (GLsizei)lrintf(glViewAttribs->viewport.bounds.size.height);
	
	glViewport( x, y, width, height );
	
	glTranslatef( 0.0f, 0.0f, -3.0f );
} // setViewport

//---------------------------------------------------------------------------

- (void) setScale:(const GLdouble)theScale
{
	glViewAttribs->planes.scale = theScale;
} // setScale

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Viewport Utility

//---------------------------------------------------------------------------
//
// Set perspective and viewport, update pitch and rotation
//
//---------------------------------------------------------------------------

- (void) updateViewport
{
	// Set our viewport with correct presperctive
	
	[self setPrespective];
	[self setViewport];
	
	// Constant rotation of the 3D objects
	
	[animation updatePitch];
	[animation updateRotation];
} // updateViewport

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Full Screen Mode

//---------------------------------------------------------------------------

- (void) fullScreenEnable
{
	[self enterFullScreenMode:fullScreen  
				  withOptions:fullScreenOptions];
} // fullScreenEnable

//---------------------------------------------------------------------------

- (void) fullScreenDisable
{
	[self exitFullScreenModeWithOptions:fullScreenOptions];
} // fullScreenDisable

//---------------------------------------------------------------------------

- (void) setFullScreenMode
{
	if( ![self isInFullScreenMode] )
	{
		[self fullScreenEnable];
	} // if
} // setFullScreenMode

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Key Events

//---------------------------------------------------------------------------

- (void) keyDown:(NSEvent *)theEvent
{
	NSString  *characters = [theEvent charactersIgnoringModifiers];
    unichar    keyPressed = [characters characterAtIndex:0];
	
    if( keyPressed == kESCKey )
	{
		if( [self isInFullScreenMode] )
		{
			[self fullScreenDisable];
		} // if
		else
		{
			[self fullScreenEnable];
		} // if
    } // if
} // keyDown

//------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Mouse Events

//------------------------------------------------------------------------

- (void)mouseDown:(NSEvent *)theEvent
{
	glViewAttribs->viewport.mousePoint = [self convertPoint:[theEvent locationInWindow] 
													fromView:nil];
} // mouseDown

//------------------------------------------------------------------------

- (void)rightMouseDown:(NSEvent *)theEvent
{
	glViewAttribs->viewport.mousePoint = [self convertPoint:[theEvent locationInWindow] 
													fromView:nil];
} // rightMouseDown

//------------------------------------------------------------------------

- (void)mouseDragged:(NSEvent *)theEvent
{
	if( [theEvent modifierFlags] & NSRightMouseDown )
	{
		[self rightMouseDragged:theEvent];
	} // if
	else
	{
		NSPoint mouse = [self convertPoint:[theEvent locationInWindow] 
								  fromView:nil];
		
		[animation setPitch:&glViewAttribs->viewport.mousePoint
					  start:&mouse];
		
		[animation setRotation:&glViewAttribs->viewport.mousePoint
						 start:&mouse];
		
		glViewAttribs->viewport.mousePoint = mouse;
		
		[self setNeedsDisplay:YES];
	} // else
} // mouseDragged

//------------------------------------------------------------------------

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	NSPoint mouse = [self convertPoint:[theEvent locationInWindow] 
							  fromView:nil];
	
	glViewAttribs->viewport.zoom += 0.01f * ( glViewAttribs->viewport.mousePoint.y - mouse.y );
	
	if( glViewAttribs->viewport.zoom < 0.05f )
	{
		glViewAttribs->viewport.zoom = 0.05f;
	} // if
	else if( glViewAttribs->viewport.zoom > 2.0f )
	{
		glViewAttribs->viewport.zoom = 2.0f;
	} // else if
	
	glViewAttribs->viewport.mousePoint = mouse;

	[self setPrespective];
	
	[self setNeedsDisplay:YES];
} // rightMouseDragged

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
