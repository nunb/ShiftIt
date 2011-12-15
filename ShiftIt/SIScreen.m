//
//  Created by krikava on 01/12/11.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "SIScreen.h"
#import "SIDefines.h"
#import "SIAdjacentRect.h"
#import "FMT/FMT.h"

const FMTDirection kDefaultDirections[] = {kRightDirection, kBottomDirection, kLeftDirection, kTopDirection};


@interface NSScreen (Extras)

+ (NSScreen *)primaryScreen;
- (BOOL)isPrimary;
- (BOOL)isBelowPrimary;
- (NSRect)screenFrame;
- (NSRect)screenVisibleFrame;

@end

@implementation NSScreen (Extras)

+ (NSScreen *)primaryScreen {
	return [[NSScreen screens] objectAtIndex:0];
}

- (BOOL)isPrimary {
	return self == [NSScreen primaryScreen];
}

- (BOOL)isBelowPrimary {
	BOOL isBellow = NO;
	for (NSScreen *s in [NSScreen screens]) {
		NSRect r = [s frame];
		COCOA_TO_SCREEN_COORDINATES(r);
		if (r.origin.y > 0) {
			isBellow = YES;
			break;
		}
	}
	return isBellow;
}

- (NSRect)screenFrame {
    NSRect r = [self frame];
    COCOA_TO_SCREEN_COORDINATES(r);
    return  r;
}

- (NSRect)screenVisibleFrame {
    NSRect r = [self visibleFrame];
    COCOA_TO_SCREEN_COORDINATES(r);
    return  r;
}

@end

@interface SIScreen ()
@property(readonly) NSScreen *screen;

+ (SIScreen *)screenRelativeTo_:(SIScreen *)screen withOffset:(NSInteger)offset;
@end

@implementation SIScreen {
@private
    NSScreen *screen_;
}

@synthesize screen = screen_;
@dynamic size;
@dynamic primary;
@dynamic rect;
@dynamic visibleRect;

- (id) initWithNSScreen:(NSScreen *)screen {
	FMTAssertNotNil(screen);

	if (![super init]) {
		return nil;
	}

    screen_ = [screen retain];

	return self;
}

- (BOOL) primary {
    return [screen_ isPrimary];
}

- (NSRect) rect {
	// screen coordinates of the best fit window
	NSRect r = [screen_ screenFrame];

    return r;
}

- (NSRect) visibleRect {
	// visible screen coordinates of the best fit window
	// the visible screen denotes some inner rect of the screen frame
	// which is visible - not occupied by menu bar or dock
	NSRect r = [screen_ screenVisibleFrame];

    return r;
}

- (NSSize) size {
	return [self visibleRect].size;
}

- (NSString *) description {
    NSDictionary *info = [screen_ deviceDescription];

    return FMTStr(@"id=%@, primary=%d, rect=(%@) visibleRect=(%@)", [info objectForKey: @"NSScreenNumber"], [self primary], RECT_STR([self rect]), RECT_STR([self visibleRect]));
}

- (BOOL)isEqual:(id)object {
    if (object == self)
           return YES;
       if (!object || ![object isKindOfClass:[self class]])
           return NO;
       return [self isEqualToScreen:(SIScreen *)object];
}

- (BOOL)isEqualToScreen:(SIScreen *)screen {
    return [screen_ isEqual:[screen screen]];
}

- (NSUInteger)hash {
    return [screen_ hash];
}

+ (NSArray *) screens {
    return [[NSScreen screens] transform:^id(id item) {
        return [SIScreen screenFromNSScreen:item]; 
    }];
}

+ (SIScreen *) primaryScreen {
    return [SIScreen screenFromNSScreen:[NSScreen primaryScreen]];
}

+ (SIScreen *) screenFromNSScreen:(NSScreen *)screen {
    return [[[SIScreen alloc] initWithNSScreen:screen] autorelease];
}

/**
 * Chooses the best screen for the given window rect (screen coord).
 *
 * For each screen it computes the intersecting rectangle and its size.
 * The biggest is the screen where is the most of the window hence the best fit.
 */
+ (SIScreen *) screenForWindowGeometry:(NSRect)geometry {
	NSScreen *fitScreen = [NSScreen mainScreen];
	double maxSize = 0;

	for (NSScreen *screen in [NSScreen screens]) {
		NSRect screenRect = [screen frame];
		// need to convert coordinates
		COCOA_TO_SCREEN_COORDINATES(screenRect);

		NSRect intersectRect = NSIntersectionRect(screenRect, geometry);

		if (intersectRect.size.width > 0 ) {
			double size = intersectRect.size.width * intersectRect.size.height;
			if (size > maxSize) {
				fitScreen = screen;
				maxSize = size;
			}
		}
	}

	return [SIScreen screenFromNSScreen:fitScreen];
}

- (SIScreen *)previousScreen {
    return [SIScreen screenRelativeTo_:self withOffset:-1];
}

- (SIScreen *)nextScreen {
    return [SIScreen screenRelativeTo_:self withOffset:1];
}

+ (SIScreen *)screenRelativeTo_:(SIScreen *)screen withOffset:(NSInteger)offset {
    NSArray *screens = [SIScreen screens];
    if ([screens count] < 2) {
        return screen;
    }

    NSArray *rects = [screens transform:^id(id item) {
       return [SIRectWithValue rect:[item rect] withValue:item];
    }];

    SIAdjacentRect *adjr = [SIAdjacentRect adjacentRect:rects];
    NSArray *path = [adjr buildDirectionalPath:kDefaultDirections fromValue:[SIScreen primaryScreen]];
    NSUInteger idx = [path findIndex:^BOOL(id item) {
       return [screen isEqualToScreen:item];
    }];

    idx += offset;
    idx %= [path count];

    return [path objectAtIndex:idx];
}

- (void)dealloc {
    [screen_ release];

    [super dealloc];
}

@end