//---------------------------------------------------------------------------
//
//	File: OpenGLAnimation.h
//
//  Abstract: OpenGL class for managing a 3D objects animation
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

#import "OpenGLAnimation.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLAnimationAttributes
{
	GLfloat   rotation;		// degree of rotation used for animation
	GLfloat   pitch;		// Pitch angle for animation
	GLdouble  deltaTime;	// used to compute change in time
	GLdouble  rotDPS;		// View rotation degrees-per-second
};

typedef struct OpenGLAnimationAttributes  OpenGLAnimationAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLAnimation

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializer

//---------------------------------------------------------------------------

- (id) initAnimationWithDegreesPerSecond:(const GLdouble)theDegreesPerSecond
{
	self = [super init];
	
	if( self )
	{
		glAnimAttribs = (OpenGLAnimationAttributesRef)malloc( sizeof(OpenGLAnimationAttributes) );
		
		if( glAnimAttribs != NULL )
		{
			glAnimAttribs->deltaTime = -1.0;
			glAnimAttribs->rotation  =  0.0f;
			glAnimAttribs->pitch     =  0.0f;
			
			glAnimAttribs->rotDPS = theDegreesPerSecond;
		} // if
		else
		{
			NSLog( @">> ERROR: OpenGL View Animation- Allocating Memory For OpenGL View Animation Attributes Failed!" );
		} // else
	} // if
	
	return( self );
} // initAnimationWithDegressPerSecond

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
	if( glAnimAttribs != NULL )
	{
		free( glAnimAttribs );
		
		glAnimAttribs = NULL;
	} // if
	
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Updating

//------------------------------------------------------------------------

- (void) updatePitch
{
	if( glAnimAttribs->pitch < -45.0f )
	{
		glAnimAttribs->pitch = -45.0f;
	} // if
	else if( glAnimAttribs->pitch > 90.0f )
	{
		glAnimAttribs->pitch = 90.0f;
	} // else if
	
	glRotatef( glAnimAttribs->pitch, 1.0f, 0.0f, 0.0f );
} // updatePitch

//---------------------------------------------------------------------------

- (GLdouble) updateTime
{
	GLdouble  timeDelta = 0.0;
	GLdouble  timeNow   = (GLdouble)[NSDate timeIntervalSinceReferenceDate];
	
	if( glAnimAttribs->deltaTime < 0 )
	{
		timeDelta = 0;
	} // if
	else
	{
		timeDelta = timeNow - glAnimAttribs->deltaTime;
	} // else
	
	glAnimAttribs->deltaTime = timeNow;

	return( timeDelta );
} // updateTime

//------------------------------------------------------------------------

- (void) updateRotation
{
	GLdouble timeDelta = [self updateTime];
	
	glAnimAttribs->rotation += glAnimAttribs->rotDPS * timeDelta;
	
	if( glAnimAttribs->rotation >= 360.0f )
	{
		glAnimAttribs->rotation -= 360.0f;
	} // if
	
	glRotatef( glAnimAttribs->rotation, 0.0f, 1.0f, 0.0f );
	
	// Increment the rotation angle
	
	glAnimAttribs->rotation += 0.2f;
} // updateRotation

//------------------------------------------------------------------------

- (void) setRotation:(const NSPoint *)theEndPoint
			   start:(const NSPoint *)theStartPoint
{
	glAnimAttribs->rotation -= theEndPoint->x - theStartPoint->x;
} // setRotation

//------------------------------------------------------------------------

- (void) setPitch:(const NSPoint *)theEndPoint
			start:(const NSPoint *)theStartPoint
{
	glAnimAttribs->pitch += theEndPoint->y - theStartPoint->y;
} // setPitch

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
