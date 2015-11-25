//---------------------------------------------------------------------------
//
//	File: OpenGLPixelAttributes.m
//
//  Abstract: Utility class to parse property list file and obtain the
//            desired pixel format attributes.
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

#import "OpenGLPixelAttributes.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLPixelFormatAttribute
{
	NSOpenGLPixelFormatAttribute  *attribute;
	NSInteger                      count;
};

typedef struct OpenGLPixelFormatAttribute  OpenGLPixelFormatAttribute;

//---------------------------------------------------------------------------

struct OpenGLPixelFormatAttributes
{
	OpenGLPixelFormatAttribute  expected;
	OpenGLPixelFormatAttribute  fallback;
};

typedef struct OpenGLPixelFormatAttributes  OpenGLPixelFormatAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Strings

//---------------------------------------------------------------------------

static BOOL NSStringOrderedSame(NSString *string1, NSString *string2)
{
	NSComparisonResult result = [string1 compare:string2];
	
	return( result == NSOrderedSame );
} // NSStringOrderedSame

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Pixel Format

//---------------------------------------------------------------------------

static void OpenGLPixelFormatGetFlagAttributes(NSDictionary *pfFlagsDict, 
											   NSMutableArray *pfMArray)
{
	if( pfFlagsDict )
	{
		NSArray *keys = [NSArray arrayWithObjects:@"Accelerated",
						 #ifdef MAC_OS_X_VERSION_10_6
						 @"Accelerated Compute",
						 #endif
						 @"Allow Offline Renderers",
						 @"Aux Depth Stencil",
						 @"Backing Store",
						 @"Closest Color Buffer",
						 @"Color Float",
						 @"Compliant",
						 @"Double Buffer",
						 @"MP Safe",
						 @"Multisample",
						 @"MultiScreen",
						 @"No Recovery",
						 @"Robust",
						 @"Sample Alpha",
						 @"Stereo Buffering",
						 @"Supersample",
						 @"Window",
						 nil];
		
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSOpenGLPFAAccelerated],
							#ifdef MAC_OS_X_VERSION_10_6
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAAcceleratedCompute],
							#endif
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAAllowOfflineRenderers],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAAuxDepthStencil],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFABackingStore],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAClosestPolicy],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAColorFloat],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFACompliant],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFADoubleBuffer],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAMPSafe],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAMultisample],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAMultiScreen],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFANoRecovery],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFARobust],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFASampleAlpha],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAStereo],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFASupersample],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAWindow],
							nil];

		NSDictionary *pfFlagAttribs = [[NSDictionary alloc] initWithObjects:objects
																	forKeys:keys];
		
		if( pfFlagAttribs )
		{
			NSString *pfFlagsKey;
			NSNumber *pfFlag;
			
			for( pfFlagsKey in pfFlagsDict )
			{
				pfFlag = [pfFlagsDict objectForKey:pfFlagsKey];
				
				if( [pfFlag boolValue] )
				{					
					[pfMArray addObject:[pfFlagAttribs objectForKey:pfFlagsKey]];
				} // if
			} // for

			[pfFlagAttribs release];
		} // if
	} // if
} // OpenGLPixelFormatGetFlagAttributes

//---------------------------------------------------------------------------

static void OpenGLPixelFormatGetMixedAttributes(NSDictionary *pfDict, 
												NSSet *pfNumSet,
												NSArray *pfObjects,
												NSArray *pfKeys,
												NSMutableArray *pfMArray)
{
	if( pfDict )
	{
		NSString *pfVal;
		NSString *pfKey;
		NSNumber *pfNum;
		
		NSDictionary *pfAttribs = [[NSDictionary alloc] initWithObjects:pfObjects
																forKeys:pfKeys];
		
		if( pfAttribs )
		{
			for( pfKey in pfDict )
			{
				if( [pfNumSet containsObject:pfKey] )
				{
					pfNum = [pfDict objectForKey:pfKey];
					
					if( pfNum )
					{
						[pfMArray addObject:[pfAttribs objectForKey:pfKey]];
						[pfMArray addObject:pfNum];
					} // if
				} // if
				else
				{
					pfVal = [pfDict objectForKey:pfKey];
					
					if( pfVal )
					{
						[pfMArray addObject:[pfAttribs objectForKey:pfVal]];
					} // if
				} // else if
			} // for
			
			[pfAttribs release];
		} // if
	} // if
} // OpenGLPixelFormatGetMixedAttributes

//---------------------------------------------------------------------------

static void OpenGLPixelFormatGetBufferAttributes(NSDictionary *pfBufferDict, 
												 NSMutableArray *pfMArray)
{
	if( pfBufferDict )
	{
		NSSet *pfBufferNumSet = [NSSet setWithObjects:@"Aux Buffers",
								 @"Sample Buffers",
								 @"Samples Per Buffer",
								 nil];
		
		NSArray *pfBufferKeys = [NSArray arrayWithObjects:@"Aux Buffers",
								 @"Sample Buffers",
								 @"Samples Per Buffer",
								 #ifdef MAC_OS_X_VERSION_10_6
								 @"Offline",
								 #endif
								 @"Online",
								 @"Minimum",
								 @"Maximum",
								 nil];
		
		NSArray *pfBufferObjects = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSOpenGLPFAAuxBuffers],
									[NSNumber numberWithUnsignedInt:NSOpenGLPFASampleBuffers],
									[NSNumber numberWithUnsignedInt:NSOpenGLPFASamples],
									#ifdef MAC_OS_X_VERSION_10_6
									[NSNumber numberWithUnsignedInt:NSOpenGLPFARemotePixelBuffer],
									#endif
									[NSNumber numberWithUnsignedInt:NSOpenGLPFAPixelBuffer],
									[NSNumber numberWithUnsignedInt:NSOpenGLPFAMinimumPolicy],
									[NSNumber numberWithUnsignedInt:NSOpenGLPFAMaximumPolicy],
									nil];
		
		OpenGLPixelFormatGetMixedAttributes(pfBufferDict, 
											pfBufferNumSet,
											pfBufferObjects,
											pfBufferKeys,
											pfMArray);
	} // if
} // OpenGLPixelFormatGetBufferAttributes

//---------------------------------------------------------------------------

static void OpenGLPixelFormatGetDisplayAttributes(NSDictionary *pfDisplayDict, 
												  NSMutableArray *pfMArray)
{
	if( pfDisplayDict )
	{
		NSSet *pfDisplayNumSet = [NSSet setWithObjects:@"Renderer ID",
								  @"Screen Mask",
								  @"Virtual Screens",
								  nil];
		
		NSArray *pfDisplayKeys = [NSArray arrayWithObjects:@"All Renderers",
								  @"Off Screen",
								  @"Full Screen",
								  @"Single Renderer",
								  @"Renderer ID",
								  @"Screen Mask",
								  @"Virtual Screens",
								  nil];
		
		NSArray *pfDisplayObjects = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSOpenGLPFAAllRenderers],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFAOffScreen],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFAFullScreen],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFASingleRenderer],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFARendererID],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFAScreenMask],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFAVirtualScreenCount],
									 nil];
		
		OpenGLPixelFormatGetMixedAttributes(pfDisplayDict, 
											pfDisplayNumSet,
											pfDisplayObjects,
											pfDisplayKeys,
											pfMArray);
	} // if
} // OpenGLPixelFormatGetDisplayAttributes

//---------------------------------------------------------------------------

static void OpenGLPixelFormatGetSizeAttributes(NSDictionary *pfSizeDict, 
											   NSMutableArray *pfMArray)
{
	if( pfSizeDict )
	{
		NSSet *pfSizeNumSet = [NSSet setWithObjects:@"Accum",
							   @"Alpha",
							   @"Color",
							   @"Depth",
							   @"Stencil",
							   nil];
		
		NSArray *pfSizeKeys = [NSArray arrayWithObjects:@"Accum",
							   @"Alpha",
							   @"Color",
							   @"Depth",
							   @"Stencil",
							   nil];
		
		NSArray *pfSizeObjects = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSOpenGLPFAAccumSize],
								  [NSNumber numberWithUnsignedInt:NSOpenGLPFAAlphaSize],
								  [NSNumber numberWithUnsignedInt:NSOpenGLPFAColorSize],
								  [NSNumber numberWithUnsignedInt:NSOpenGLPFADepthSize],
								  [NSNumber numberWithUnsignedInt:NSOpenGLPFAStencilSize],
								  nil];
		
		OpenGLPixelFormatGetMixedAttributes(pfSizeDict, 
											pfSizeNumSet,
											pfSizeObjects,
											pfSizeKeys,
											pfMArray);
	} // if
} // OpenGLPixelFormatGetSizeAttributes

//---------------------------------------------------------------------------

static void OpenGLPixelFormatCreateArray(NSDictionary *pfd,
										 NSString *pfKey,
										 NSMutableArray *pfMArray)
{
	if( pfd )
	{	
		NSString      *pfaKey;
		NSDictionary  *pfad;
		
		for( pfaKey in pfd )
		{
			pfad = [pfd objectForKey:pfaKey];

			if( NSStringOrderedSame(pfaKey,@"Buffers") )
			{
				OpenGLPixelFormatGetBufferAttributes( pfad, pfMArray );
			} // if
			else if( NSStringOrderedSame(pfaKey,@"Display") )
			{
				OpenGLPixelFormatGetDisplayAttributes( pfad, pfMArray );
			} // else if
			else if( NSStringOrderedSame(pfaKey,@"Flags") )
			{
				OpenGLPixelFormatGetFlagAttributes( pfad, pfMArray );
			} // else if
			else if( NSStringOrderedSame(pfaKey,@"Size") )
			{
				OpenGLPixelFormatGetSizeAttributes( pfad, pfMArray );
			} // else if
		} // for
		
		if( pfMArray )
		{
			[pfMArray addObject:[NSNumber numberWithBool:NO]];
		} // if
	} // if
} // OpenGLPixelFormatCreateArray

//---------------------------------------------------------------------------

static NSOpenGLPixelFormatAttribute *OpenGLPixelFormatCreateAttributes( NSMutableArray *pfMArray )
{
	NSOpenGLPixelFormatAttribute *pfAttribs = NULL;
	
	NSInteger pfAttribsCount = [pfMArray count];
	
	if( pfAttribsCount )
	{
		pfAttribs = (NSOpenGLPixelFormatAttribute *)malloc( pfAttribsCount * sizeof(NSOpenGLPixelFormatAttribute) );
		
		if( pfAttribs != NULL )
		{
			NSInteger i = 0;
			
			NSNumber *pfAttribsNum;
			
			for( pfAttribsNum in pfMArray )
			{
				pfAttribs[i] = [pfAttribsNum unsignedIntValue];
				
				i++;
			} // for
		} // if
	} // if
	
	return( pfAttribs );
} // OpenGLPixelFormatCreateAttributes

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLPixelAttributes

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------

- (id) initPListWithFileAtPath:(NSString *)thePListPath
{
	[self doesNotRecognizeSelector:_cmd];
	
	return( nil );
} // initPListWithFileAtPath

//---------------------------------------------------------------------------

- (id) initPListWithFileInAppBundle:(NSString *)thePListName
{
	[self doesNotRecognizeSelector:_cmd];
	
	return( nil );
} // initPListWithFileInAppBundle

//---------------------------------------------------------------------------

- (void) newPixelAttributesWithPListAtPath
{
	pfAttribsRef = (OpenGLPixelFormatAttributesRef)malloc(sizeof(OpenGLPixelFormatAttributes));
	
	if( pfAttribsRef != NULL )
	{
		pfAttribsRef->expected.attribute = NULL;
		pfAttribsRef->expected.count     = 0;
		pfAttribsRef->fallback.attribute = NULL;
		pfAttribsRef->fallback.count     = 0;
		
		NSDictionary *pList = [[self dictionary] objectForKey:@"Pixel Format"];
		
		if( pList )
		{
			NSString       *pListKey;
			NSDictionary   *pfDict;
			NSMutableArray *pfMArray;
			
			for( pListKey in pList )
			{
				pfDict = [pList objectForKey:pListKey];
				
				if( pfDict )
				{
					pfMArray = [NSMutableArray new];
					
					if( pfMArray )
					{
						OpenGLPixelFormatCreateArray(pfDict, pListKey, pfMArray);
						
						if( NSStringOrderedSame(pListKey,@"Expected") )
						{
							pfAttribsRef->expected.attribute = OpenGLPixelFormatCreateAttributes(pfMArray);
							pfAttribsRef->expected.count     = [pfMArray count];
						} // if
						else if( NSStringOrderedSame(pListKey,@"Fallback") )
						{
							pfAttribsRef->fallback.attribute = OpenGLPixelFormatCreateAttributes(pfMArray);
							pfAttribsRef->fallback.count     = [pfMArray count];
						} // else if
						
						[pfMArray release];
					} // if
				} // if
			} // for
		} // if
	} // if
} // newPixelAttributesWithPListAtPath

//---------------------------------------------------------------------------

- (id) initPixelAttributesWithPListAtPath:(NSString *)thePListPath
{
	self = [super initPListWithFileAtPath:thePListPath];
	
	if( self )
	{
		[self newPixelAttributesWithPListAtPath];
	} // if
	
	return( self );
} // initPixelAttributesWithPListAtPath

//---------------------------------------------------------------------------

- (id) initPixelAttributesWithPListInAppBundle:(NSString *)thePListName
{
	self = [super initPListWithFileInAppBundle:thePListName];
	
	if( self )
	{
		[self newPixelAttributesWithPListAtPath];
	} // if
	
	return( self );
} // initPixelAttributesWithPListInAppBundle

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc
{
	if( pfAttribsRef != NULL )
	{
		if( pfAttribsRef->expected.attribute != NULL )
		{
			free(pfAttribsRef->expected.attribute);
		} // if
		
		if( pfAttribsRef->fallback.attribute != NULL )
		{
			free(pfAttribsRef->fallback.attribute);
		} // if
		
		free(pfAttribsRef);
		
		pfAttribsRef = NULL;
	} // if
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (NSInteger) count:(const BOOL)theExpectedPFA
{
	NSInteger pfac = 0;
	
	if( theExpectedPFA )
	{
		pfac = pfAttribsRef->expected.count;
	} // if
	else 
	{
		pfac = pfAttribsRef->fallback.count;
	} // else
	
	return( pfac );
} // count

//---------------------------------------------------------------------------

- (NSOpenGLPixelFormatAttribute *) attributes:(const BOOL)theExpectedPFA
{
	NSOpenGLPixelFormatAttribute *pfa = NULL;
	
	if( theExpectedPFA )
	{
		pfa = pfAttribsRef->expected.attribute;
	} // if
	else 
	{
		pfa = pfAttribsRef->fallback.attribute;
	} // else

	return( pfa );
} // attributes

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------


