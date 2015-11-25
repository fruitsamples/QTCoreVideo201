//---------------------------------------------------------------------------
//
//	File: CVOpenGLView.m
//
//  Abstract: Core video + OpenGL view toolkit
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

#import "CVOpenGLView.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct CVOpenGLAttributes
{
	CFAllocatorRef       allocator;				// CF allocator used throughout
	CGDirectDisplayID    displayId;				// Display used by CoreVideo
    CVDisplayLinkRef     displayLink;			// Display link maintained by CV
	CVOptionFlags        lockFlags;				// Flags used for locking the base address
	CVPixelBufferRef     pixelBuffer;			// The current frame from CV
	NSSize               pixelBufferSize;		// Frame width & height
	BOOL                 pixelBufferIsValid;	// Set to true if the QT movie was obtained
};

typedef struct CVOpenGLAttributes   CVOpenGLAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Render Callback

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// This is the CoreVideo DisplayLink callback notifying the application when 
// the display will need each frame and is called when the DisplayLink is 
// running -- in response, we call our getFrameForTime method.
//
//---------------------------------------------------------------------------

static CVReturn CoreVideoRenderCallback(CVDisplayLinkRef    displayLink, 
										const CVTimeStamp  *inNow, 
										const CVTimeStamp  *inOutputTime, 
										CVOptionFlags       flagsIn, 
										CVOptionFlags      *flagsOut, 
										void               *displayLinkContext )
{
	return( [(CVOpenGLView *)displayLinkContext getFrameForTime:inOutputTime 
													   flagsOut:flagsOut] );
} // CoreVideoRenderCallback

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation CVOpenGLView

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Application Startup

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if( self )
	{
		cvGLViewAttribs = (CVOpenGLAttributesRef)malloc( sizeof(CVOpenGLAttributes) );
		
		if( cvGLViewAttribs != NULL )
		{
			// Initialize core video attributes
			
			cvGLViewAttribs->allocator          = kCFAllocatorDefault;
			cvGLViewAttribs->displayId          = kCGDirectMainDisplay;
			cvGLViewAttribs->displayLink        = NULL;
			cvGLViewAttribs->pixelBuffer        = NULL;
			cvGLViewAttribs->pixelBufferIsValid = NO;
			cvGLViewAttribs->lockFlags          = 0;
			
			// Initialize default movie HD frame size
			
			cvGLViewAttribs->pixelBufferSize.width  = 1920.0f;
			cvGLViewAttribs->pixelBufferSize.height =  820.0f;

			// We need a lock around our draw function so two different
			// threads don't try and draw at the same time
			
			lock = [NSRecursiveLock new];
		} // if
		else
		{
			NSLog( @">> ERROR: CoreVideo OpenGL View - Allocating Memory For View Attributes Failed!" );
		} // else
	} // if
	
	return( self );
} // initWithFrame

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------
//
// Stop and release the movie
//
//---------------------------------------------------------------------------

- (void) deleteQTMovie
{
    if( movie ) 
	{
    	[movie setRate:0.0];
		
        SetMovieVisualContext( [movie quickTimeMovie], NULL );
		
        [movie release];
		
        movie = nil;
    } // if
} // deleteQTMovie

//---------------------------------------------------------------------------
//
// Release the pixel image context
//
//---------------------------------------------------------------------------

- (void) deleteQTVisualContext
{
	if( visualContext )
	{
		[visualContext release];
		
		visualContext = nil;
	} // if
} // deleteQTVisualContext

//---------------------------------------------------------------------------
//
// Release the recursive lock
//
//---------------------------------------------------------------------------

- (void) deleteRecursiveLock
{
    if( lock ) 
	{
    	[lock release];
		
        lock = nil;
    } // if 
} // deleteRecursiveLock

//---------------------------------------------------------------------------
//
// It is critical to dispose of the display link
//
//---------------------------------------------------------------------------

- (void) deleteCVDisplayLink
{
    if( cvGLViewAttribs->displayLink != NULL ) 
	{
    	CVDisplayLinkStop( cvGLViewAttribs->displayLink );
        CVDisplayLinkRelease( cvGLViewAttribs->displayLink );
		
        cvGLViewAttribs->displayLink = NULL;
    } // if
} // deleteCVDisplayLink

//---------------------------------------------------------------------------
//
// Don't leak pixel buffers
//
//---------------------------------------------------------------------------

- (void) deleteCVTexture
{
	// If we have a previous frame release it
	
	if( cvGLViewAttribs->pixelBuffer != NULL ) 
	{
		CVOpenGLTextureRelease( cvGLViewAttribs->pixelBuffer );
		
		cvGLViewAttribs->pixelBuffer = NULL;
	} // if
} // deleteCVTexture

//---------------------------------------------------------------------------

- (void) deleteQTCVOpenGLAttributes
{
	if( cvGLViewAttribs != NULL )
	{
		[self deleteCVDisplayLink];
		[self deleteCVTexture];
		
		free( cvGLViewAttribs );
	} // if
} // deleteAttributes

//---------------------------------------------------------------------------
//
// It is very important that we clean up the rendering objects before the 
// view is disposed, remember that with the display link running you're 
// applications render callback may be called at any time including when 
// the application is quitting or the view is being disposed, additionally 
// you need to make sure you're not consuming OpenGL resources or leaking 
// textures -- this clean up routine makes sure to stop and release 
// everything.
//
//---------------------------------------------------------------------------

- (void) cleanUp
{
	[self deleteQTVisualContext];
	[self deleteQTMovie];
	[self deleteQTCVOpenGLAttributes];
	[self deleteRecursiveLock];
	
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

- (void) drawBegin
{
	// Prevent drawing from another thread if we're drawing already    
	
	[lock lock];
	
	// Make the GL context the current context
	
	[[self openGLContext] makeCurrentContext];
	
	// Clear the viewport
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
} // drawBegin

//---------------------------------------------------------------------------

- (void) drawEnd
{
	// Async flush buffer
	
	[[self openGLContext] flushBuffer];
	
	// Give time to the Visual Context so it can release internally held 
	// resources for later re-use this function should be called in every 
	// rendering pass, after old images have been released, new images 
	// have been used and all rendering has been flushed to the screen.
	
	[visualContext task];
	
	// Allowing drawing now
	
	[lock unlock];
} // drawEnd

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Display Link Obtaining Frames

//---------------------------------------------------------------------------
//
// getFrameForTime is called from the Display Link callback when it's time 
// for us to check to see if we have a frame available to render -- if we do, 
// draw -- if not, just task the Visual Context and split.
//
//---------------------------------------------------------------------------

- (CVReturn) getFrameForTime:(const CVTimeStamp *)timeStamp 
					flagsOut:(CVOptionFlags *)flagsOut
{
	if( !cvGLViewAttribs->pixelBufferIsValid )
	{
		return( kCVReturnAllocationFailed );
	} // if
	
	// There is no autorelease pool when this method is called because it will
	// be called from another thread it's important to create one or you will 
	// leak objects
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	if( pool )
	{
		// Check for a new frame
		
		if (	( [visualContext isValidVisualContext] ) 
			&&	( [visualContext isNewImageAvailable:timeStamp] ) ) 
		{
			CVOpenGLTextureRef pixelBuffer = [visualContext copyImageForTime:timeStamp];
			
			if( pixelBuffer != NULL )
			{
				[self deleteCVTexture];
				
				cvGLViewAttribs->pixelBuffer = pixelBuffer;
			} // if

			// The above call may produce a null frame so check for this first
			// if we have a frame, then draw it
			
			if( cvGLViewAttribs->pixelBuffer != NULL )
			{
				[self drawRect:NSZeroRect];
			} // if
			else
			{
				NSLog( @">> WARNING: CoreVideo OpenGL View - QT Visual Context Copy Image for Time Error!" );
			} // else
		} // if
		
		[pool release];
	} // if
	
	return( kCVReturnSuccess );
} // getFrameForTime

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Initialize movie frame size

//---------------------------------------------------------------------------

- (void) prepareQTMovieAttributes:(NSString *)theMoviePath
{
	// If we already have a QTMovie release it
	
	[self deleteQTMovie];
	
	// Instantiate a movie object
	
	NSError *qtMovieError = nil;
	
	movie = [[QTMovie alloc] initWithFile:theMoviePath 
									error:&qtMovieError];
	
	if( ( movie != nil ) && ( qtMovieError == nil ) )
	{
		// We've a valid movie
		
		cvGLViewAttribs->pixelBufferIsValid = YES;
		
		// Now get the movie size
		
		[[movie attributeForKey:QTMovieNaturalSizeAttribute] getValue:&cvGLViewAttribs->pixelBufferSize];
	} // if
	else 
	{
		NSLog( @">> ERROR: CoreVideo OpenGL View - %@", qtMovieError );
		
		[qtMovieError release];
	} // else
} // prepareQTMovieAttributes

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Initialize Core Video

//---------------------------------------------------------------------------

- (void) prepareCVDisplayLink
{
	[self deleteCVDisplayLink];
	
    // Create display link for the main display
	
    CVReturn result = CVDisplayLinkCreateWithCGDisplay(cvGLViewAttribs->displayId, 
													   &cvGLViewAttribs->displayLink);
	
    if( ( result == kCVReturnSuccess ) && ( cvGLViewAttribs->displayLink != NULL ) ) 
	{
		// Set the current display of a display link.

		CGLContextObj      cglContext     = (CGLContextObj)[[self openGLContext] CGLContextObj];
		CGLPixelFormatObj  cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj];

		CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(cvGLViewAttribs->displayLink, 
														  cglContext,  
														  cglPixelFormat);
        
        // Set the renderer output callback function
		
    	CVDisplayLinkSetOutputCallback(cvGLViewAttribs->displayLink, 
									   &CoreVideoRenderCallback, 
									   self);
        
        // Activates a display link
		
    	CVDisplayLinkStart( cvGLViewAttribs->displayLink );
    } // if
} // prepareCVDisplayLink

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Initialize QT Visual Context

//---------------------------------------------------------------------------

- (void) prepareQTVisualContext
{
	// Delete the old qt visual context
	
	[self deleteQTVisualContext];
	
	// Instantiate a new qt visual context object
	
	visualContext = [[QTVisualContext alloc] initQTVisualContextWithSize:cvGLViewAttribs->pixelBufferSize
																	type:kQTOpenGLTextureContext
																 context:[self openGLContext]
															 pixelFormat:[self pixelFormat]];
} // prepareQTVisualContext

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Open a movie with new resources

//---------------------------------------------------------------------------
//
// Upon subclassing implement, to initialize OpenGL resources for a movie
//
//---------------------------------------------------------------------------

- (void) prepareCVOpenGL
{
	return;
} // prepareCVOpenGL

//---------------------------------------------------------------------------

- (void) prepareResourcesForMovie:(NSString *)theMoviePath
{
	// New QT & CV resources for a movie
	
	[self prepareQTMovieAttributes:theMoviePath];
	
	if( cvGLViewAttribs->pixelBufferIsValid )
	{
		[self prepareCVDisplayLink];
		[self prepareQTVisualContext];
		
		// New OpenGL resources for a movie
		
		[self prepareCVOpenGL];
	} // if
} // prepareResourcesForMovie

//---------------------------------------------------------------------------
//
// Open a Movie File and instantiate a QTMovie object
//
//---------------------------------------------------------------------------

- (void) openMovie:(NSString *)theMoviePath
{
	// New movie resources
	
	[self prepareResourcesForMovie:theMoviePath];
	
	if( cvGLViewAttribs->pixelBufferIsValid )
	{
		// Set Movie to loop
		
		[movie setAttribute:[NSNumber numberWithBool:YES] 
					 forKey:QTMovieLoopsAttribute];
		
		// Targets a Movie to render into a visual context
		
		[visualContext setMovie:movie];
		
		// Play the Movie
		
		[movie setRate:1.0];
		
		// Set the window title from the Movie if it has a name associated with it
		
		[[self window] setTitle:[movie attributeForKey:QTMovieDisplayNameAttribute]];
	} // if
} // openMovie

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (NSSize) pixelBufferSize
{
	return( cvGLViewAttribs->pixelBufferSize );
} // pixelBufferSize

//---------------------------------------------------------------------------

- (BOOL) pixelBufferIsValid
{
	return( cvGLViewAttribs->pixelBuffer != NULL );
} // pixelBufferIsValid

//---------------------------------------------------------------------------

- (CVPixelBufferRef) pixelBuffer
{
	return( cvGLViewAttribs->pixelBuffer );
} // pixelBuffer

//---------------------------------------------------------------------------

- (CVDisplayLinkRef) displayLink
{
	return( cvGLViewAttribs->displayLink );
} // displayLink

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
