//
//  riJoystick.h
//  supercell
//
//  Created by Feixue Yang on 12-02-27.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"


@interface riJoystick : CCLayer {
	CCSprite *thumb;
    CCSprite *background;

	BOOL isPressed;
    
	CGPoint velocity;
    CGPoint center;
    
    BOOL isMovable;
}

@property (nonatomic, readonly) CGPoint velocity;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) BOOL isMovable;


- (void)resetJoystick;


@end
