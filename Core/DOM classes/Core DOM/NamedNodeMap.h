/*
 From SVG-DOM, via Core-DOM:
 
 http://www.w3.org/TR/DOM-Level-2-Core/core.html#ID-1780488922
 
 interface NamedNodeMap {
 Node               getNamedItem(in DOMString name);
 Node               setNamedItem(in Node arg)
 raises(DOMException);
 Node               removeNamedItem(in DOMString name)
 raises(DOMException);
 Node               item(in unsigned long index);
 readonly attribute unsigned long    length;
 // Introduced in DOM Level 2:
 Node               getNamedItemNS(in DOMString namespaceURI, 
 in DOMString localName);
 // Introduced in DOM Level 2:
 Node               setNamedItemNS(in Node arg)
 raises(DOMException);
 // Introduced in DOM Level 2:
 Node               removeNamedItemNS(in DOMString namespaceURI, 
 in DOMString localName)
 raises(DOMException);
 };

 */

#import <Foundation/Foundation.h>

@class Node;
#import "Node.h"

@interface NamedNodeMap : NSObject

-(Node*) getNamedItem(in DOMString name);
-(Node*) setNamedItem(in Node arg)
-(Node*) removeNamedItem(in DOMString name)
-(Node*) item(in unsigned long index);

@property(readonly) unsigned long length;

// Introduced in DOM Level 2:
-(Node*) getNamedItemNS:(NSString*) namespaceURI localName:(NSString*) localName;

// Introduced in DOM Level 2:
-(Node*) setNamedItemNS:(Node*) arg;

// Introduced in DOM Level 2:
-(Node*) removeNamedItemNS(NSString*) namespaceURI localName:(NSString*) localName;

@end
