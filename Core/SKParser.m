//
//  SVGParser.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGParser.h"
#import <libxml/parser.h>

#import "SVGParserSVG.h"

@interface SVGParserStackItem : NSObject
@property(nonatomic,retain) NSObject<SVGParserExtension>* parserForThisItem;
@property(nonatomic,retain) NSObject* item;

@end

@implementation SVGParserStackItem
@synthesize item;
@synthesize parserForThisItem;

- (void) dealloc 
{
    self.item = nil;
    self.parserForThisItem = nil;
    [super dealloc];
}

@end

@interface SVGParser()
@property(nonatomic,retain, readwrite) SVGSource* source;
@property(nonatomic,retain, readwrite) SVGParseResult* currentParseRun;
@end

@implementation SVGParser

@synthesize source;
@synthesize currentParseRun;


@synthesize parserExtensions;

static xmlSAXHandler SAXHandler;

static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX(void * ctx, const xmlChar * ch, int len);
static void errorEncounteredSAX(void * ctx, const char * msg, ...);

static NSString *NSStringFromLibxmlString (const xmlChar *string);
static NSMutableDictionary *NSDictionaryFromLibxmlAttributes (const xmlChar **attrs, int attr_ct);

+ (SVGParseResult*) parseSourceUsingDefaultSVGParser:(SVGSource*) source;
{
	SVGParser *parser = [[[SVGParser alloc] initWithSource:source] autorelease];
	
	SVGParserSVG *subParserSVG = [[[SVGParserSVG alloc] init] autorelease];
	
	[parser.parserExtensions addObject:subParserSVG];
	
	SVGParseResult* result = [parser parseSynchronously];
	
	return result;
}


#define READ_CHUNK_SZ 1024*10

- (id)initWithSource:(SVGSource *) s {
	self = [super init];
	if (self) {
		self.parserExtensions = [NSMutableArray array];
		
		self.source = s;
		
		_storedChars = [NSMutableString new];
		_elementStack = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc {
	self.currentParseRun = nil;
	self.source = nil;
	[_storedChars release];
	[_elementStack release];
	self.parserExtensions = nil;
	[super dealloc];
}

- (void) addSVGParserExtension:(NSObject<SVGParserExtension>*) extension
{
	if( self.parserExtensions == nil )
	{
		self.parserExtensions = [NSMutableArray array];
	}
	
	[self.parserExtensions addObject:extension];
}

- (SVGParseResult*) parseSynchronously
{
	self.currentParseRun = [[SVGParseResult new] autorelease];
	
	/*
	// 1. while (source has chunks of BYTES)
	// 2.   read a chunk from source, send to libxml
	// 3.   if libxml failed chunk, break
	// 4. return result
	*/
	
	NSError* error = nil;
	id handle = [source newHandle:&error];
	if( error != nil )
	{
		[currentParseRun addSourceError:error];
		return  currentParseRun;
	}
	char buff[READ_CHUNK_SZ];
	
	xmlParserCtxtPtr ctx = xmlCreatePushParserCtxt(&SAXHandler, self, NULL, 0, NULL);
	
	if( ctx ) // if libxml init succeeds...
	{
		// 1. while (source has chunks of BYTES)
		// 2.   read a chunk from source, send to libxml
		int bytesRead = [source handle:handle readNextChunk:(char *)&buff maxBytes:READ_CHUNK_SZ];
		while( bytesRead > 0 )
		{
			int libXmlParserParseError = xmlParseChunk(ctx, buff, bytesRead, 0);
			
			if( [currentParseRun.errorsFatal count] > 0 )
			{
			/** NB this old code is no longer needed - we're doing higher-quality error handling!
			if ( (libXmlParserParseError != 0)
			{*/
				// 3.   if libxml failed chunk, break
				NSLog(@"[%@] libXml reported internal parser error with magic libxml code = %i (look this up on http://xmlsoft.org/html/libxml-xmlerror.html#xmlParserErrors)", [self class], libXmlParserParseError );
				currentParseRun.libXMLFailed = YES;
				
				break;
			}
			
			bytesRead = [source handle:handle readNextChunk:(char *)&buff maxBytes:READ_CHUNK_SZ];
		}
	}
	
	[source closeHandle:handle]; // close the handle NO MATTER WHAT
	
	if (!currentParseRun.libXMLFailed)
		xmlParseChunk(ctx, NULL, 0, 1); // EOF
	
	xmlFreeParserCtxt(ctx);
	
	// 4. return result
	return currentParseRun;
}

/** ADAM: use this for a higher-performance, *non-blocking* parse
 (when someone upgrades this class and the interface to support non-blocking parse)
// Called when a chunk of data has been downloaded.
- (void)connection:(NSURLConnection *)connection 
	didReceiveData:(NSData *)data 
{
	// Process the downloaded chunk of data.
	xmlParseChunk(_xmlParserContext, (const char *)[data bytes], [data length], 0);//....Getting Exception at this line.
}
 */


- (void)handleStartElement:(NSString *)name xmlns:(NSString*) prefix attributes:(NSMutableDictionary *)attributes {
	
		for( NSObject<SVGParserExtension>* subParser in self.parserExtensions )
		{
			if( [[subParser supportedNamespaces] containsObject:prefix]
			&& [[subParser supportedTags] containsObject:name] )
			{
				NSObject* subParserResult = nil;
				
			if( nil != (subParserResult = [subParser handleStartElement:name document:source xmlns:prefix attributes:attributes]) )
			{
				NSLog(@"[%@] tag: <%@:%@> -- handled by subParser: %@", [self class], prefix, name, subParser );
				
				SVGParserStackItem* stackItem = [[[SVGParserStackItem alloc] init] autorelease];;
				stackItem.parserForThisItem = subParser;
				stackItem.item = subParserResult;
				
				[_elementStack addObject:stackItem];
				
				if ([subParser createdItemShouldStoreContent:stackItem.item]) {
					[_storedChars setString:@""];
					_storingChars = YES;
				}
				else {
					_storingChars = NO;
				}
				return;
			}
				
			}
		}
	
	NSLog(@"[%@] ERROR: could not find a parser for tag: <%@:%@>; adding empty placeholder", [self class], prefix, name );
	
	SVGParserStackItem* emptyItem = [[[SVGParserStackItem alloc] init] autorelease];
	[_elementStack addObject:emptyItem];
}


static void startElementSAX (void *ctx, const xmlChar *localname, const xmlChar *prefix,
							 const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces,
							 int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
	
	SVGParser *self = (SVGParser *) ctx;
	
	NSString *name = NSStringFromLibxmlString(localname);
	NSMutableDictionary *attrs = NSDictionaryFromLibxmlAttributes(attributes, nb_attributes);
	
	/**
	 Debugging:
	//NSString *url = NSStringFromLibxmlString(URI);
	NSString *prefix2 = nil;
	if( prefix != NULL )
		prefix2 = NSStringFromLibxmlString(prefix);
	 */
	
	NSString *objcURIString = nil;
	if( URI != NULL )
		objcURIString = NSStringFromLibxmlString(URI);
	
#if DEBUG_VERBOSE_LOG_EVERY_TAG
	NSLog(@"[%@] DEBUG_VERBOSE: <%@%@> (namespace URL:%@), attributes: %i", [self class], (prefix2==nil)?@"":[NSString stringWithFormat:@"%@:",prefix2], name, (URI==NULL)?@"n/a":objcURIString, nb_attributes );
#endif
	
#if DEBUG_VERBOSE_LOG_EVERY_TAG
	if( prefix2 == nil )
	{
		/* The XML library allows this, although it's very unhelpful when writing application code */
		
		/* Let's find out what namespaces DO exist... */
		
		/*
		 
		 TODO / DEVELOPER WARNING: the library says nb_namespaces is the number of elements in the array,
		 but it keeps returning nil pointer (not always, but often). WTF? Not sure what we're doing wrong
		 here, but commenting it out for now...
		 
		if( nb_namespaces > 0 )
		{
			for( int i=0; i<nb_namespaces; i++ )
			{
				NSLog(@"[%@] DEBUG: found namespace [%i] : %@", [self class], i, namespaces[i] );
			}
		}
		else
			NSLog(@"[%@] DEBUG: there are ZERO namespaces!", [self class] );
		 */
	}
#endif
	
	[self handleStartElement:name xmlns:objcURIString attributes:attrs];
}

- (void)handleEndElement:(NSString *)name {
	//DELETE DEBUG NSLog(@"ending element, name = %@", name);
	
	SVGParserStackItem* stackItem = [_elementStack lastObject];
	
	[_elementStack removeLastObject];
	
	if( stackItem.parserForThisItem == nil )
	{
		/*! this was an unmatched tag - we have no parser for it, so we're pruning it from the tree */
		NSLog(@"[%@] WARN: ended non-parsed tag (</%@>) - this will NOT be added to the output tree", [self class], name );
	}
	else
	{
		SVGParserStackItem* parentStackItem = [_elementStack lastObject];
		
		NSObject<SVGParserExtension>* parserHandlingTheParentItem = parentStackItem.parserForThisItem;

		BOOL closingRootTag = FALSE;
		if( parentStackItem.item == nil )
		{
			/**
			 Special case: we've hit the closing of the root tag.
			 
			 Because each parser-extension MIGHT need to do cleanup / post-processing on the end tag,
			 we need to ensure that whichever class parsed the root tag gets one final callback to tell it that the end
			 tag has been reached
			 */
			
			closingRootTag = TRUE;
			parserHandlingTheParentItem = stackItem.parserForThisItem;
		}
		
		NSLog(@"[%@] DEBUG-PARSER: ended tag (</%@>): telling parser (%@) to add that item to tree-parent = %@", [self class], name, parserHandlingTheParentItem, parentStackItem.item );
		[parserHandlingTheParentItem addChildObject:stackItem.item toObject:parentStackItem.item];// inDocument:_document];
		
		if ( [stackItem.parserForThisItem createdItemShouldStoreContent:stackItem.item]) {
			[stackItem.parserForThisItem parseContent:_storedChars forItem:stackItem.item];
			
			[_storedChars setString:@""];
			_storingChars = NO;
		}
		
		if( closingRootTag )
		{
			currentParseRun.rootOfSVGTree = (SVGElement*) stackItem.item;
		}
	}
}

static void	endElementSAX (void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {
	SVGParser *self = (SVGParser *) ctx;
	[self handleEndElement:NSStringFromLibxmlString(localname)];
}

- (void)handleFoundCharacters:(const xmlChar *)chars length:(int)len {
	if (_storingChars) {
		char value[len + 1];
		strncpy(value, (const char *) chars, len);
		value[len] = '\0';
		
		[_storedChars appendString:[NSString stringWithUTF8String:value]];
	}
}

static void	charactersFoundSAX (void *ctx, const xmlChar *chars, int len) {
	SVGParser *self = (SVGParser *) ctx;
	[self handleFoundCharacters:chars length:len];
}

static void errorEncounteredSAX (void *ctx, const char *msg, ...) {
	NSLog(@"Error encountered during parse: %s", msg);
	SVGParseResult* parseResult = ((SVGParser*) ctx).currentParseRun;
	[parseResult addSAXError:[NSError errorWithDomain:@"SVG-SAX" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																				  (NSString*) msg, NSLocalizedDescriptionKey,
																				nil]]];
}

static void	unparsedEntityDeclaration(void * ctx, 
									 const xmlChar * name, 
									 const xmlChar * publicId, 
									 const xmlChar * systemId, 
									 const xmlChar * notationName)
{
	NSLog(@"ERror: unparsed entity Decl");
}

static void structuredError		(void * userData, 
									 xmlErrorPtr error)
{
	/**
	 XML_ERR_WARNING = 1 : A simple warning
	 XML_ERR_ERROR = 2 : A recoverable error
	 XML_ERR_FATAL = 3 : A fatal error
	 */
	xmlErrorLevel errorLevel = error->level;
	
	NSMutableDictionary* details = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithCString:error->message encoding:NSUTF8StringEncoding], NSLocalizedDescriptionKey,
									[NSNumber numberWithInt:error->line], @"lineNumber",
									[NSNumber numberWithInt:error->int2], @"columnNumber",
									nil];
	
	if( error->str1 )
		[details setValue:[NSString stringWithCString:error->str1 encoding:NSUTF8StringEncoding] forKey:@"bonusInfo1"];
	if( error->str2 )
		[details setValue:[NSString stringWithCString:error->str2 encoding:NSUTF8StringEncoding] forKey:@"bonusInfo2"];
	if( error->str3 )
		[details setValue:[NSString stringWithCString:error->str3 encoding:NSUTF8StringEncoding] forKey:@"bonusInfo3"];
	
	NSError* objcError = [NSError errorWithDomain:[[NSNumber numberWithInt:error->domain] stringValue] code:error->code userInfo:details];
	
	SVGParseResult* parseResult = ((SVGParser*) userData).currentParseRun;
	switch( errorLevel )
	{
		case XML_ERR_WARNING:
		{
			[parseResult addParseWarning:objcError];
		}break;
			
		case XML_ERR_ERROR:
		{
			[parseResult addParseErrorRecoverable:objcError];
		}break;
			
		case XML_ERR_FATAL:
		{
			[parseResult addParseErrorFatal:objcError];
		}
        default:
            break;
	}
	
}

static xmlSAXHandler SAXHandler = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,                       /* attributeDecl */
    NULL,                       /* elementDecl */
    unparsedEntityDeclaration,  /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    NULL,                       /* startDocument */
    NULL,                       /* endDocument */
    NULL,                       /* startElement*/
    NULL,                       /* endElement */
    NULL,                       /* reference */
    charactersFoundSAX,         /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncounteredSAX,        /* error */
    NULL,                       /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    NULL,                       /* cdataBlock */
    NULL,                       /* externalSubset */
    XML_SAX2_MAGIC,
    NULL,
    startElementSAX,            /* startElementNs */
    endElementSAX,              /* endElementNs */
    structuredError,                       /* serror */
};

#pragma mark -
#pragma mark Utility

static NSString *NSStringFromLibxmlString (const xmlChar *string) {
	return [NSString stringWithUTF8String:(const char *) string];
}

static NSMutableDictionary *NSDictionaryFromLibxmlAttributes (const xmlChar **attrs, int attr_ct) {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	for (int i = 0; i < attr_ct * 5; i += 5) {
		const char *begin = (const char *) attrs[i + 3];
		const char *end = (const char *) attrs[i + 4];
		int vlen = strlen(begin) - strlen(end);
		
		char val[vlen + 1];
		strncpy(val, begin, vlen);
		val[vlen] = '\0';
		
		[dict setObject:[NSString stringWithUTF8String:val]
				 forKey:NSStringFromLibxmlString(attrs[i])];
	}
	
	return [dict autorelease];
}

#define MAX_ACCUM 256
#define MAX_NAME 256

+(NSDictionary *) NSDictionaryFromCSSAttributes: (NSString *)css {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	const char *cstr = [css UTF8String];
	size_t len = strlen(cstr);
	
	char name[MAX_NAME];
	bzero(name, MAX_NAME);
	
	char accum[MAX_ACCUM];
	bzero(accum, MAX_ACCUM);
	
	size_t accumIdx = 0;
	
	for (size_t n = 0; n <= len; n++) {
		char c = cstr[n];
		
		if (c == '\n' || c == '\t' || c == ' ') {
			continue;
		}
		
		if (c == ':') {
			strcpy(name, accum);
			name[accumIdx] = '\0';
			
			bzero(accum, MAX_ACCUM);
			accumIdx = 0;
			
			continue;
		}
		else if (c == ';' || c == '\0') {
			accum[accumIdx] = '\0';
			
			[dict setObject:[NSString stringWithUTF8String:accum]
					 forKey:[NSString stringWithUTF8String:name]];
			
			bzero(name, MAX_NAME);
			
			bzero(accum, MAX_ACCUM);
			accumIdx = 0;
			
			continue;
		}
		
		accum[accumIdx++] = c;
	}
	
	return [dict autorelease];
}

@end