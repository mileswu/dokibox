//
//  LibraryViewAddButton.h
//  dokibox
//
//  Created by Miles Wu on 28/09/2013.
//
//

#import <Cocoa/Cocoa.h>

@interface LibraryViewAddButton : NSView {
    BOOL _hover;
    BOOL _held;
}

@property(weak) id target;
@property(assign) SEL action;

@end