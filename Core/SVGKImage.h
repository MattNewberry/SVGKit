/*
 SVGKImage
 
 The main class in SVGKit - this is the one you'll normally interact with
 
 c.f. SVGKit.h for more info on using SVGKit
 
 What is an SVGKImage?
 
 An SVGKImage is as close to "the SVG version of a UIImage" as we could possibly get. We cannot
 subclass UIImage because Apple has defined UIImage as immutable - and SVG images actually change
 (each time you zoom in, we want to re-render the SVG as a higher-resolution set of pixels)
 
 We use the exact same method names as UIImage, and try to be literally as identical as possible.
 
 Data:
  - UIImage: not supported yet: will be a cached UIImage that is re-generated on demand. Will enable us to implement an SVGKImageView
 that works as a drop-in replacement for UIImageView
 
  - DOMTree: the SVG DOM spec, the root element of a tree of SVGElement subclasses
  - CALayerTree: the root element of a tree of CALayer subclasses
 
  - size: as per the UIImage.size, returns a size in Apple Points (i.e. 320 == width of iPhone, irrespective of Retina)
  - scale: ??? unknown how we'll define this, but could be useful when doing auto-re-render-on-zoom
  - svgWidth: the internal SVGLength used to generate the correct .size
  - svgHeight: the internal SVGLength used to generate the correct .size
  - rootElement: the SVGSVGElement instance that is the root of the parse SVG tree. Use this to access the full SVG document
 
 */

#import "SKBasicDataTypes.h"
#import "SVGDocument.h"
#import "SVGElement.h"
#import "SVGSVGElement.h"
#import "SVGGroupElement.h"

#import "SVGKParser.h"
#import "SVGKSource.h"
#import "SVGKParseResult.h"

@class SVGDefsElement;

@interface SVGKImage : NSObject // doesn't extend UIImage because Apple made UIImage immutable
{
}

#if TARGET_OS_IPHONE
@property (nonatomic, readonly) UIImage* UIImage; /** generates an image on the fly */
#endif

@property (nonatomic, readonly) SVGLength svgWidth;
@property (nonatomic, readonly) SVGLength svgHeight;
@property (nonatomic, retain, readonly) SVGKSource* source;
@property (nonatomic, retain, readonly) SVGKParseResult* parseErrorsAndWarnings;

@property (nonatomic, retain, readonly) SVGDocument* DOMDocument;
@property (nonatomic, retain, readonly) SVGSVGElement* DOMTree; // needs renaming + (possibly) replacing by DOMDocument
@property (nonatomic, retain, readonly) CALayer* CALayerTree;


#pragma mark - methods to quick load an SVG as an image
+ (SVGKImage *)imageNamed:(NSString *)name;      // load from main bundle
+ (SVGKImage *)imageWithContentsOfFile:(NSString *)path;
#if TARGET_OS_IPHONE // doesn't exist on OS X's Image class
+ (SVGKImage *)imageWithData:(NSData *)data;
#endif

- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithData:(NSData *)data;

#pragma mark - UIImage methods cloned and re-implemented as SVG intelligent methods
@property(nonatomic,readonly) CGSize             size;             // reflects orientation setting. size is in pixels
@property(nonatomic,readonly) CGFloat            scale __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_4_0);

/**
 
 TODO: From UIImage. Not needed, I think?
 
 @property(nonatomic,readonly) CIImage           *CIImage __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0); // returns underlying CIImage or nil if CGImageRef based
*/

// the these draw the image 'right side up' in the usual coordinate system with 'point' being the top-left.

- (void)drawAtPoint:(CGPoint)point;                                                        // mode = kCGBlendModeNormal, alpha = 1.0

#pragma mark - unsupported / unimplemented UIImage methods (should add as a feature)
- (void)drawAtPoint:(CGPoint)point blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha;
- (void)drawInRect:(CGRect)rect;                                                           // mode = kCGBlendModeNormal, alpha = 1.0
- (void)drawInRect:(CGRect)rect blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha;

- (void)drawAsPatternInRect:(CGRect)rect; // draws the image as a CGPattern
// animated images. When set as UIImageView.image, animation will play in an infinite loop until removed. Drawing will render the first image
#if TARGET_OS_IPHONE




+ (UIImage *)animatedImageNamed:(NSString *)name duration:(NSTimeInterval)duration ;//__OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0); read sequnce of files with suffix starting at 0 or 1
+ (UIImage *)animatedResizableImageNamed:(NSString *)name capInsets:(UIEdgeInsets)capInsets duration:(NSTimeInterval)duration ;//__OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0); // squence of files
+ (UIImage *)animatedImageWithImages:(NSArray *)images duration:(NSTimeInterval)duration ;//__OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0);

#endif
/**
 
 TODO: From UIImage. Not needed, I think?

@property(nonatomic,readonly) NSArray       *images   __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0); // default is nil for non-animated images
@property(nonatomic,readonly) NSTimeInterval duration __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0); // total duration for all frames. default is 0 for non-animated images
 */
#pragma mark ---------end of unsupported items

+ (SVGKImage*)imageWithContentsOfURL:(NSURL *)url;

#pragma mark - core methods for interacting with an SVG image usefully (not from UIImage)

/*! This is used internally by the main UIImage cloned methods anyway, so we might as well expose it */
- (id)initWithSource:(SVGKSource *)source;


/*! Creates a new instance each time you call it. This should ONLY be used if you specifically need to duplicate
 the CALayer's (e.g. because you want to render a temporary clone of the CALayers somewhere else on screen,
 and you're going to modify them).
 
 For all other use-cases, you should probably use the .CALayerTree property, which is automatically cached between
 calls - but MUST NOT be altered!
 */
-(CALayer *)newCALayerTree;

/*! uses the current .CALayerTree property to find the layer, recursing down the tree (or creates a new
 CALayerTree on demand, and caches it)
 
 i.e. this takes advantage of the cached CALayerTree instance, and also correctly uses the SVG.viewBox info
 that was used when generating the original CALayerTree
 */
- (CALayer *)layerWithIdentifier:(NSString *)identifier;

/*! uses the current .CALayerTree property to find the layer, recursing down the tree (or creates a new
 CALayerTree on demand, and caches it)
 
 i.e. this takes advantage of the cached CALayerTree instance, and also correctly uses the SVG.viewBox info
 that was used when generating the original CALayerTree
 */
- (CALayer *)layerWithIdentifier:(NSString *)identifier layer:(CALayer *)layer;

/*! As for layerWithIdentifier: but works out the absolute position of the layer,
 effectively pulling it out of the layer-tree (the newly created layer has NO SUPERLAYER,
 because it no longer needs one)
 
 Useful for extracting individual features from an SVG
 */
-(CALayer*) newCopyPositionedAbsoluteLayerWithIdentifier:(NSString *)identifier;

/*! returns all the individual CALayer's in the full layer tree, indexed by the SVG identifier of the SVG node that created that layer */
- (NSDictionary*) dictionaryOfLayers;

@end