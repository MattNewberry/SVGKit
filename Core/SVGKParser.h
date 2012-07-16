/**
 SVGKParser.h
 
 The main parser for SVGKit. All the magic starts here
 
 PARSING
 ---
 Actual parsing of an SVG is split into three places:
 
 1. High level, XML parsing: this file (SVGKParser)
 2. Mid level, parsing the structure of a document, and special XML tags: any class that extends "SVGKParserExtension"
 3. Mid level, parsing SVG tags only: SVGKParserSVG (it's an extension that just does base SVG)
 4. Low level, parsing individual tags within a file, and precise co-ordinates: all the "SVG...Element" classes parse themselves
 
 IDEALLY, we'd like to change that to:
 
 1. High level, XML parsing: this file (SVGKParser)
 2. Mid level, parsing the structure of a document, and special XML tags: any class that extends "SVGKParserExtension"
 3. Mid level, parsing SVG tags only, but also handling all the different tags: SVGKParserSVG
 4. Lowest level, parsing co-ordinate lists, numbers, strings: yacc/lex parser (in an unnamed class that hasn't been written yet)
 */

#import <Foundation/Foundation.h>

#import "SVGKSource.h"
#import "SVGKParserExtension.h"
#import "SVGKParseResult.h"

#import "SVGKParserStackItem.h"
#import "SVGElement.h"



/*! RECOMMENDED: leave this set to 1 to get warnings about "legal, but poorly written" SVG */
#define PARSER_WARN_FOR_ANONYMOUS_SVG_G_TAGS 1

/*! Verbose parser logging - ONLY needed if you have an SVG file that's failing to load / crashing */
#define DEBUG_VERBOSE_LOG_EVERY_TAG 0

@interface SVGKParser : NSObject {
  @private
	BOOL _storingChars;
	NSMutableString *_storedChars;
	NSMutableArray *_elementStack;
}

@property(nonatomic,retain,readonly) SVGKSource* source;
@property(nonatomic,retain,readonly) SVGKParseResult* currentParseRun;


@property(nonatomic,retain) NSMutableArray* parserExtensions;

#pragma mark - NEW

+ (SVGKParseResult*) parseSourceUsingDefaultSVGKParser:(SVGKSource*) source;
- (SVGKParseResult*) parseSynchronously;


+(NSDictionary *) NSDictionaryFromCSSAttributes: (NSString *)css;



#pragma mark - OLD - POTENTIALLY DELETE THESE ONCE THEY'VE ALL BEEN CHECKED AND CONVERTED

- (id)initWithSource:(SVGKSource *)doc;

- (void) addParserExtension:(NSObject<SVGKParserExtension>*) extension;



@end
