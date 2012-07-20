/*
//  Node.h
*
 http://www.w3.org/TR/DOM-Level-2-Core/core.html#ID-1950641247
 
 interface Node {
 
 // NodeType
 const unsigned short      ELEMENT_NODE                   = 1;
 const unsigned short      ATTRIBUTE_NODE                 = 2;
 const unsigned short      TEXT_NODE                      = 3;
 const unsigned short      CDATA_SECTION_NODE             = 4;
 const unsigned short      ENTITY_REFERENCE_NODE          = 5;
 const unsigned short      ENTITY_NODE                    = 6;
 const unsigned short      PROCESSING_INSTRUCTION_NODE    = 7;
 const unsigned short      COMMENT_NODE                   = 8;
 const unsigned short      DOCUMENT_NODE                  = 9;
 const unsigned short      DOCUMENT_TYPE_NODE             = 10;
 const unsigned short      DOCUMENT_FRAGMENT_NODE         = 11;
 const unsigned short      NOTATION_NODE                  = 12;
 
 readonly attribute DOMString        nodeName;
 attribute DOMString        nodeValue;
 // raises(DOMException) on setting
 // raises(DOMException) on retrieval
 
 readonly attribute unsigned short   nodeType;
 readonly attribute Node             parentNode;
 readonly attribute NodeList         childNodes;
 readonly attribute Node             firstChild;
 readonly attribute Node             lastChild;
 readonly attribute Node             previousSibling;
 readonly attribute Node             nextSibling;
 readonly attribute NamedNodeMap     attributes;
 // Modified in DOM Level 2:
 readonly attribute Document         ownerDocument;
 Node               insertBefore(in Node newChild, 
 in Node refChild)
 raises(DOMException);
 Node               replaceChild(in Node newChild, 
 in Node oldChild)
 raises(DOMException);
 Node               removeChild(in Node oldChild)
 raises(DOMException);
 Node               appendChild(in Node newChild)
 raises(DOMException);
 boolean            hasChildNodes();
 Node               cloneNode(in boolean deep);
 // Modified in DOM Level 2:
 void               normalize();
 // Introduced in DOM Level 2:
 boolean            isSupported(in DOMString feature, 
 in DOMString version);
 // Introduced in DOM Level 2:
 readonly attribute DOMString        namespaceURI;
 // Introduced in DOM Level 2:
 attribute DOMString        prefix;
 // raises(DOMException) on setting
 
 // Introduced in DOM Level 2:
 readonly attribute DOMString        localName;
 // Introduced in DOM Level 2:
 boolean            hasAttributes();
 };

*/

#import <Foundation/Foundation.h>

@class Document;
/** objc won't allow this: #import "Document.h"*/
@class NodeList;
/** objc won't allow this: #import "NodeList.h"*/
@class NamedNodeMap;
/** objc won't allow this: #import "NamedNodeMap.h"*/

typedef enum SKNodeType
{
	SKNodeType_ELEMENT_NODE                   = 1,
	SKNodeType_ATTRIBUTE_NODE                 = 2,
	SKNodeType_TEXT_NODE                      = 3,
	SKNodeType_CDATA_SECTION_NODE             = 4,
	SKNodeType_ENTITY_REFERENCE_NODE          = 5,
	SKNodeType_ENTITY_NODE                    = 6,
	SKNodeType_PROCESSING_INSTRUCTION_NODE    = 7,
	SKNodeType_COMMENT_NODE                   = 8,
	SKNodeType_DOCUMENT_NODE                  = 9,
	SKNodeType_DOCUMENT_TYPE_NODE             = 10,
	SKNodeType_DOCUMENT_FRAGMENT_NODE         = 11,
	SKNodeType_NOTATION_NODE                  = 12
} SKNodeType;

@interface Node : NSObject

@property(nonatomic,retain,readonly) NSString* nodeName;
@property(nonatomic,retain,readonly) NSString* nodeValue;
	
@property(nonatomic,readonly) SKNodeType nodeType;
@property(nonatomic,retain,readonly) Node* parentNode;
@property(nonatomic,retain,readonly) NodeList* childNodes;
@property(nonatomic,retain,readonly) Node* firstChild;
@property(nonatomic,retain,readonly) Node* lastChild;
@property(nonatomic,retain,readonly) Node* previousSibling;
@property(nonatomic,retain,readonly) Node* nextSibling;
@property(nonatomic,retain,readonly) NamedNodeMap* attributes;

// Modified in DOM Level 2:
@property(nonatomic,retain,readonly) Document* ownerDocument;

-(Node*) insertBefore:(Node*) newChild refChild:(Node*) refChild;

-(Node*) replaceChild:(Node*) newChild oldChild:(Node*) oldChild;
-(Node*) removeChild:(Node*) oldChild;
-(Node*) appendChild:(Node*) newChild;

@property(nonatomic) BOOL hasChildNodes;

-(Node*) cloneNode:(BOOL) deep;

// Modified in DOM Level 2:
-(void) normalize;

// Introduced in DOM Level 2:
-(BOOL) isSupportedFeature:(NSString*) feature version:(NSString*) version;

// Introduced in DOM Level 2:
@property(nonatomic,retain,readonly) NSString* namespaceURI;

// Introduced in DOM Level 2:
@property(nonatomic,retain,readonly) NSString* prefix;

// Introduced in DOM Level 2:
@property(nonatomic,retain,readonly) NSString* localName;

// Introduced in DOM Level 2:
@property(nonatomic) BOOL hasAttributes;

#pragma mark - Objective-C init methods (not in SVG Spec - you're supposed to use SVGDocument's createXXX methods instead)
/** Generic init method - used by all the other methods (designated initializer, effectively) */
- (id)initType:(SKNodeType) nt;

- (id)initAttr:(NSString*) n value:(NSString*) v;
- (id)initCDATASection:(NSString*) n value:(NSString*) v;
- (id)initComment:(NSString*) n value:(NSString*) v;
- (id)initDocument:(NSString*) n;
- (id)initDocumentFragment:(NSString*) n;
- (id)initDocumentType:(NSString*) n;
/*! DOM level 1 (leaves various things set to nil) */
- (id)initElement:(NSString*) n;
/*! DOM level 2 (ALWAYS use this if possible: otherwise lots of things left at nil) */
- (id)initElement:(NSString*) n inNameSpaceURI:(NSString*) nsURI;
- (id)initEntity:(NSString*) n;
- (id)initEntityReference:(NSString*) n;
- (id)initNotation:(NSString*) n;
- (id)initProcessingInstruction:(NSString*) n value:(NSString*) v;
- (id)initText:(NSString*) n value:(NSString*) v;

@end
