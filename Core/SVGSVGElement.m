#import "SVGSVGElement.h"

#import "CALayerWithChildHitTest.h"

@implementation SVGSVGElement

@synthesize documentWidth;
@synthesize documentHeight;
@synthesize viewBoxFrame = _viewBoxFrame;

@synthesize graphicsGroups, anonymousGraphicsGroups;

-(void)dealloc
{
	self.graphicsGroups = nil;
	self.anonymousGraphicsGroups = nil;
	[super dealloc];	
}

- (void)parseAttributes:(NSDictionary *)attributes {
	[super parseAttributes:attributes];
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"width"])) {
		documentWidth = SVGLengthFromNSString( value );
	}
	
	if ((value = [attributes objectForKey:@"height"])) {
		documentHeight = SVGLengthFromNSString( value );
	}
	
	if( (value = [attributes objectForKey:@"viewBox"])) {
		NSArray* boxElements = [(NSString*) value componentsSeparatedByString:@" "];
		
		_viewBoxFrame = CGRectMake([[boxElements objectAtIndex:0] floatValue], [[boxElements objectAtIndex:1] floatValue], [[boxElements objectAtIndex:2] floatValue], [[boxElements objectAtIndex:3] floatValue]);
		NSLog(@"[%@] DEBUG INFO: set document viewBox = %@", [self class], NSStringFromCGRect(self.viewBoxFrame));
	}
}

- (SVGElement *)findFirstElementOfClass:(Class)class {
	for (SVGElement *element in self.children) {
		if ([element isKindOfClass:class])
			return element;
	}
	
	return nil;
}

- (CALayer *)newLayer
{
	
	CALayer* _layer = [CALayerWithChildHitTest layer];
	
	_layer.name = self.identifier;
	[_layer setValue:self.identifier forKey:kSVGElementIdentifier];
	
	if ([_layer respondsToSelector:@selector(setShouldRasterize:)]) {
		[_layer performSelector:@selector(setShouldRasterize:)
					 withObject:[NSNumber numberWithBool:YES]];
	}
	
	return _layer;
}

- (void)layoutLayer:(CALayer *)layer {
	NSArray *sublayers = [layer sublayers];
	CGRect mainRect = CGRectZero;
	
	for (NSUInteger n = 0; n < [sublayers count]; n++) {
		CALayer *currentLayer = [sublayers objectAtIndex:n];
		
		if (n == 0) {
			mainRect = currentLayer.frame;
		}
		else {
			mainRect = CGRectUnion(mainRect, currentLayer.frame);
		}
	}
	
	mainRect = CGRectIntegral(mainRect); // round values to integers
	
	layer.frame = mainRect;
	
	for (CALayer *currentLayer in sublayers) {
		CGRect frame = currentLayer.frame;
		frame.origin.x -= mainRect.origin.x;
		frame.origin.y -= mainRect.origin.y;
		
		currentLayer.frame = CGRectIntegral(frame);
	}
}


@end