//
//  SVGShapeElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGShapeElement.h"

#import "CGPathAdditions.h"
#import "SVGDefsElement.h"
#import "SVGKPattern.h"
#import "CAShapeLayerWithHitTest.h"

#define ADAM_IS_FIXING_THE_TRANSFORM_AND_VIEW_BOX_CODE 1

@implementation SVGShapeElement

#define IDENTIFIER_LEN 256

@synthesize opacity = _opacity;

@synthesize fillType = _fillType;
@synthesize fillColor = _fillColor;
@synthesize fillPattern = _fillPattern;

@synthesize strokeWidth = _strokeWidth;
@synthesize strokeColor = _strokeColor;

@synthesize pathRelative = _pathRelative;

- (void)finalize {
	CGPathRelease(_pathRelative);
	[super finalize];
}

- (void)dealloc {
	CGPathRelease(_pathRelative);
    self.fillPattern = nil;
    
	[super dealloc];
}

- (void)loadDefaults {
	_opacity = 1.0f;
	
	_fillColor = SVGColorMake(0, 0, 0, 255);
	_fillType = SVGFillTypeSolid;
}

- (void)parseAttributes:(NSDictionary *)attributes {
	[super parseAttributes:attributes];
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"opacity"])) {
		_opacity = [value floatValue];
	}
	
	if ((value = [attributes objectForKey:@"fill"])) {
		const char *cvalue = [value UTF8String];
		
		if (!strncmp(cvalue, "none", 4)) {
			_fillType = SVGFillTypeNone;
		}
		else if (!strncmp(cvalue, "url", 3)) {
			NSLog(@"Gradients are no longer supported");
			_fillType = SVGFillTypeNone;
		}
		else {
			_fillColor = SVGColorFromString([value UTF8String]);
			_fillType = SVGFillTypeSolid;
		}
	}
	
	if ((value = [attributes objectForKey:@"stroke-width"])) {
		_strokeWidth = [value floatValue];
	}
	
	if ((value = [attributes objectForKey:@"stroke"])) {
		const char *cvalue = [value UTF8String];
		
		if (!strncmp(cvalue, "none", 4)) {
			_strokeWidth = 0.0f;
		}
		else {
			_strokeColor = SVGColorFromString(cvalue);
			
			if (!_strokeWidth)
				_strokeWidth = 1.0f;
		}
	}
	
	if ((value = [attributes objectForKey:@"stroke-opacity"])) {
		_strokeColor.a = (uint8_t) ([value floatValue] * 0xFF);
	}
	
	if ((value = [attributes objectForKey:@"fill-opacity"])) {
		_fillColor.a = (uint8_t) ([value floatValue] * 0xFF);
	}
}

- (void)setPathByCopyingPathFromLocalSpace:(CGPathRef)aPath {
	if (_pathRelative) {
		CGPathRelease(_pathRelative);
		_pathRelative = NULL;
	}
	
	if (aPath) {
		_pathRelative = CGPathCreateCopy(aPath);
	}
}

- (CALayer *) newLayerPreTransformed:(CGAffineTransform) preTransform {
	CAShapeLayer* _shapeLayer = [[CAShapeLayerWithHitTest layer] retain];
	_shapeLayer.name = self.identifier;
		[_shapeLayer setValue:self.identifier forKey:kSVGElementIdentifier];
	_shapeLayer.opacity = _opacity;
	
#if EXPERIMENTAL_SUPPORT_FOR_SVG_TRANSFORM_ATTRIBUTES
	CGAffineTransform svgEffectiveTransform = [self transformAbsolute];
#endif
	
#if OUTLINE_SHAPES
	
#if TARGET_OS_IPHONE
	_shapeLayer.borderColor = [UIColor redColor].CGColor;
#endif
	
	_shapeLayer.borderWidth = 1.0f;
#endif
	
	/**
	 We've parsed this shape using the size values specified RAW inside the SVG.
	 
	 Before we attempt to *render* it, we need to convert those values into
	 screen-space.
	 
	 Most SVG docs have screenspace == unit space - but some docs have an explicit "viewBox"
	 attribute on the SVG document. As per the SVG spec, this defines an alternative
	 conversion from unit space to screenspace
	 */
	CGAffineTransform transformFromSVGUnitsToScreenUnits;
	
	CGMutablePathRef pathToPlaceInLayer = CGPathCreateMutable();
	CGPathAddPath( pathToPlaceInLayer, &preTransform, _pathRelative);	
	
    CGRect rect = CGPathGetPathBoundingBox( pathToPlaceInLayer );
	
	CGPathRef finalPath = CGPathCreateByOffsettingPath( pathToPlaceInLayer, rect.origin.x, rect.origin.y );

	/** Can't use this - iOS 5 only! path = CGPathCreateCopyByTransformingPath(path, transformFromSVGUnitsToScreenUnits ); */
	
	_shapeLayer.path = finalPath;
	CGPathRelease(finalPath);
	CGPathRelease(pathToPlaceInLayer);

#if EXPERIMENTAL_SUPPORT_FOR_SVG_TRANSFORM_ATTRIBUTES
	/**
	 NB: this line, by changing the FRAME of the layer, has the side effect of also changing the CGPATH's position in absolute
	 space!
	 */
	_shapeLayer.frame = CGRectApplyAffineTransform( rect, svgEffectiveTransform );
#else
	_shapeLayer.frame = rect;
#endif
	
	if (_strokeWidth) {
		_shapeLayer.lineWidth = _strokeWidth;
		_shapeLayer.strokeColor = CGColorWithSVGColor(_strokeColor);
	}
	
	if (_fillType == SVGFillTypeNone) {
		_shapeLayer.fillColor = nil;
	}
	else if (_fillType == SVGFillTypeSolid) {
		_shapeLayer.fillColor = CGColorWithSVGColor(_fillColor);
	}
    
    if (nil != _fillPattern) {
        _shapeLayer.fillColor = [_fillPattern CGColor];
    }
	
	if ([_shapeLayer respondsToSelector:@selector(setShouldRasterize:)]) {
		[_shapeLayer performSelector:@selector(setShouldRasterize:)
					withObject:[NSNumber numberWithBool:YES]];
	}
	
	return _shapeLayer;
}

- (void)layoutLayer:(CALayer *)layer { }

@end
