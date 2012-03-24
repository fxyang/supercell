//
//  riJoystick.m
//  supercell
//
//  Created by Feixue Yang on 12-02-27.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "riJoystick.h"

// Give the joystick a little padding from the edge of the screen.
// NOTE: getting to close to the edge of the screen causes touches
// to be cancelled in the simulator.
#define JOYSTICK_OFFSET_X 5.0f
#define JOYSTICK_OFFSET_Y 5.0f

// The radius of the touchable region.
#define JOYSTICK_RADIUS 80.0f

// How far from the center should the thumb be allowed to move?
// Used only for visual feedback not for velocity calculations.
#define THUMB_RADIUS 24.0f

#define kEventHandled YES
#define kEventIgnored NO

#define kJoystickOpacity 192
#define kJoystickMovable NO


static const CGPoint kCenter = {
	JOYSTICK_RADIUS + JOYSTICK_OFFSET_X,
	JOYSTICK_RADIUS + JOYSTICK_OFFSET_Y
};

// In landscape mode the point's x and y values of touches are transposed.
static CGPoint convertCoordinate(CGPoint point) {
	return [[CCDirector sharedDirector] convertToGL:point];
}

// Determine if a point within the boundaries of the joystick.
static bool isPointInCircle(CGPoint point, CGPoint center, float radius) {
	float dx = (point.x - center.x);
	float dy = (point.y - center.y);
	return (radius >= sqrt( (dx * dx) + (dy * dy) ));
}

@interface riJoystick(hidden)
- (void)updateJoystickCenter:(CGPoint)cenPos thumb:(CGPoint)thPos;
- (void)updateVelocity:(CGPoint)point;
- (BOOL)handleLastTouch;
@end

@implementation riJoystick

@synthesize velocity;
@synthesize center;
@synthesize isMovable;


- (id)init {
	self = [super init];
	if (self != nil) {
		self.isTouchEnabled = YES;
		velocity = CGPointZero;
        center = kCenter;
        isMovable = kJoystickMovable;
        
		background = [CCSprite spriteWithFile:@"joystick_background.png"];
		[background setPosition:kCenter];
        [background setOpacity:kJoystickOpacity];
		[self addChild:background z:0];
        
		thumb = [CCSprite spriteWithFile:@"joystick_thumb.png"];
		[thumb setPosition:kCenter];
		[self addChild:thumb z:1];
        
	}
	return self;
}

- (void)updateVelocity:(CGPoint)point {
	// Calculate distance and angle from the center.
	float dx = point.x - center.x;
	float dy = point.y - center.y;
    
	float distance = sqrt(dx * dx + dy * dy);
	float angle = atan2(dy, dx); // in radians
    
	// NOTE: Velocity goes from -1.0 to 1.0.
	// BE CAREFUL: don't just cap each direction at 1.0 since that
	// doesn't preserve the proportions.
	if (distance > JOYSTICK_RADIUS) {
		dx = cos(angle) * JOYSTICK_RADIUS;
		dy = sin(angle) *  JOYSTICK_RADIUS;
	}
    
	velocity = CGPointMake(dx/JOYSTICK_RADIUS, dy/JOYSTICK_RADIUS);
    
	// Constrain the thumb so that it stays within the joystick
	// boundaries.  This is smaller than the joystick radius in
	// order to account for the size of the thumb.
	if (distance > THUMB_RADIUS) {
		point.x = center.x + cos(angle) * THUMB_RADIUS;
		point.y = center.y + sin(angle) * THUMB_RADIUS;
	}
    
	// Update the thumb's position
	[thumb setPosition:point];
}

- (void)resetJoystick {
	//[self updateVelocity:kCenter];
    [self updateJoystickCenter:kCenter thumb:kCenter];
    isPressed = NO;
}

- (void)updateJoystickCenter:(CGPoint)cenPos thumb:(CGPoint)thPos{
    background.position = cenPos;
    center = cenPos;
    thumb.position = thPos;
    [self updateVelocity:thPos];

}

- (BOOL) handleLastTouch {
	BOOL wasPressed = isPressed;
	if (wasPressed) {
		[self resetJoystick];
		isPressed = NO;
	}
	return (wasPressed ? kEventHandled : kEventIgnored);
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView: [touch view]];
	point = convertCoordinate(point);
    
	// Start only if the first touch is within the pad's boundaries.
	// Allow touches to be tracked outside of the pad as long as the
	// screen continues to be pressed.
    
    
    if(isPressed){
        if (isPointInCircle(point, center, JOYSTICK_RADIUS))
            [self updateVelocity:point];
        else if(isMovable){
            CGPoint cenPos = ccp(point.x - THUMB_RADIUS * velocity.x , point.y - THUMB_RADIUS * velocity.y);
            [self updateJoystickCenter:cenPos thumb:point];
        }else
            [self updateVelocity:point];

    }else{
        if (isPointInCircle(point, center, JOYSTICK_RADIUS)) {
            isPressed = YES;
            [self updateVelocity:point];
        }
    }

    
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (isPressed) {
		UITouch *touch = [touches anyObject];
		CGPoint point = [touch locationInView: [touch view]];
		point = convertCoordinate(point);
        
		[self updateVelocity:point];
	}
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

}

- (void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {

}

@end