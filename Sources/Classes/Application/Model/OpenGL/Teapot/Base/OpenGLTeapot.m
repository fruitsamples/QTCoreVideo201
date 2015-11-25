//---------------------------------------------------------------------------
//
//	File: OpenGLTeapot.h
//
//  Abstract: Class that implements a method for generating an IBO teapot
//            with enabled sphere map texture coordinate generation.
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

#import "OpenGLTeapot.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLTeapotAttributes
{
	CGSize   size;
	GLfloat  scale[3];
	GLfloat  translate[3];
};

typedef struct OpenGLTeapotAttributes   OpenGLTeapotAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLTeapot

//---------------------------------------------------------------------------

- (id) initIBORendererWithPListAtPath:(NSString *)thePListPath 
								 type:(const GLenum)theType
{
	[self doesNotRecognizeSelector:_cmd];
	
	return( nil );
} // initIBORendererWithPListAtPath

//---------------------------------------------------------------------------

- (id) initIBORenderertWithPListInAppBundle:(NSString *)thePListName
									   type:(const GLenum)theType
{
	[self doesNotRecognizeSelector:_cmd];
	
	return( nil );
} // initIBORenderertWithPListInAppBundle

//---------------------------------------------------------------------------

- (void) initTeapotTexWithSize:(const NSSize *)theSize
{
	if( ( theSize->width <= 0.0f ) || ( theSize->height <= 0.0f ) )
	{
		teapotAttribs->size.width  = 1920.0f;	// Default texture width for a HD movie
		teapotAttribs->size.height =  820.0f;	// Default texture height for a HD movie
	} // if
	else
	{
		teapotAttribs->size.width  = theSize->width;
		teapotAttribs->size.height = theSize->height;
	} // else
} // initTeapotTexWithSize

//---------------------------------------------------------------------------

- (void) initTeapotTexGenSphereMap
{
	glTexGeni( GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP );
	glTexGeni( GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP );
} // initTeapotTexGenSphereMap

//---------------------------------------------------------------------------

- (void) initTeapotScale
{
	teapotAttribs->scale[0] = 0.5f;
	teapotAttribs->scale[1] = 0.5f;
	teapotAttribs->scale[2] = 0.5f;
} // initTeapotScale

//---------------------------------------------------------------------------

- (void) initTeapotTranslation
{
	teapotAttribs->translate[0] =  0.0f;
	teapotAttribs->translate[1] = -0.75f;
	teapotAttribs->translate[2] =  0.0f;
} // initTeapotTranslation

//---------------------------------------------------------------------------

- (void) newTeapotWithSize:(const NSSize *)theSize
{
	teapotAttribs = (OpenGLTeapotAttributesRef)malloc(sizeof(OpenGLTeapotAttributes));
	
	if( teapotAttribs != NULL )
	{
		[self initTeapotScale];
		[self initTeapotTranslation];
		[self initTeapotTexWithSize:theSize];
		[self initTeapotTexGenSphereMap];
	} // if
} // newTeapotWithSize

//---------------------------------------------------------------------------

- (id) initTeapotdWithPListAtPath:(NSString *)thePListPath
							 size:(const NSSize *)theSize
{
	self = [super initIBORendererWithPListAtPath:thePListPath
											type:GL_FLOAT];

	if( self )
	{
		[self newTeapotWithSize:theSize];
	} // if
	
	return( self );
} // initTeapotdWithPListAtPath

//---------------------------------------------------------------------------

- (id) initTeapotWithPListInAppBundle:(NSString *)thePListName
								 size:(const NSSize *)theSize
{
	self = [super initIBORenderertWithPListInAppBundle:thePListName 
												  type:GL_FLOAT];

	if( self )
	{
		[self newTeapotWithSize:theSize];
	} // if
	
	return( self );
} // initTeapotWithPListInAppBundle

//---------------------------------------------------------------------------

- (void) dealloc
{
	if( teapotAttribs != NULL )
	{
		free(teapotAttribs);
		
		teapotAttribs = NULL;
	} // if
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

- (void) setScale:(const GLfloat *)theScale
{
	teapotAttribs->scale[0] = theScale[0];
	teapotAttribs->scale[1] = theScale[1];
	teapotAttribs->scale[2] = theScale[2];
} // setScale

//------------------------------------------------------------------------

- (void) setTranslation:(const GLfloat *)theTranslation
{
	teapotAttribs->translate[0] = theTranslation[0];
	teapotAttribs->translate[1] = theTranslation[1];
	teapotAttribs->translate[2] = theTranslation[2];
} // setTranslation

//---------------------------------------------------------------------------
//
// Enable sphere map automatic texture coordinate generation.
//
//---------------------------------------------------------------------------

- (void) enableSphereMap
{
	glEnable( GL_TEXTURE_GEN_S );
	glEnable( GL_TEXTURE_GEN_T );
} // enableSphereMap

//---------------------------------------------------------------------------
//
// Disable shere map automatic texture coordinate generation.
//
//---------------------------------------------------------------------------

- (void) disableSphereMap
{
	glDisable( GL_TEXTURE_GEN_T );
	glDisable( GL_TEXTURE_GEN_S );
} // enableSphereMap

//---------------------------------------------------------------------------

- (void) display
{
	// Enable sphere map texture coordinate generation
	
	[self enableSphereMap];
	
	// Since we will be using GL_TEXTURE_RECTANGLE_EXT textures which 
	// uses pixel coordinates rather than normalized coordinates, we 
	// need to scale the texturing matrix
	
	glMatrixMode( GL_TEXTURE );
	
	// To rotate without skewing or translation, we must be in 0-centered 
	// normalized texture coordinates 
	
	glScalef(teapotAttribs->size.width, 
			 teapotAttribs->size.height, 
			 1.0f);
	
	glMatrixMode( GL_MODELVIEW );
	
	// Translate the teapot to the new coordinates
	
	glTranslatef(teapotAttribs->translate[0], 
				 teapotAttribs->translate[1], 
				 teapotAttribs->translate[2]);
	
	// Scale the teapot object
	
	glScalef(teapotAttribs->scale[0], 
			 teapotAttribs->scale[1], 
			 teapotAttribs->scale[2]);
	
	// Draw the IBO teapot
	
	[self render];
	
	// Disable sphere map texture coordinate generation
	
	[self disableSphereMap];
} // display

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------


