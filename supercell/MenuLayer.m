//
//  MenuLayer.m
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "MenuLayer.h"

@implementation MenuLayer

-(id) init{
	self = [super init];
    
	CCLabelTTF *titleLeft = [CCLabelTTF labelWithString:@"Menu " fontName:@"Marker Felt" fontSize:48];
	CCLabelTTF *titleRight = [CCLabelTTF labelWithString:@" System" fontName:@"Marker Felt" fontSize:48];
	CCLabelTTF *titleQuotes = [CCLabelTTF labelWithString:@"\"                        \"" fontName:@"Marker Felt" fontSize:48];
	CCLabelTTF *titleCenterTop = [CCLabelTTF labelWithString:@"How to build a..." fontName:@"Marker Felt" fontSize:26];
	CCLabelTTF *titleCenterBottom = [CCLabelTTF labelWithString:@"Part 1" fontName:@"Marker Felt" fontSize:48];
    
    float delayTime = 0.3f;
    
	CCMenuItemFont *startNew = [CCMenuItemFont itemFromString:@"New Game" target:self selector: @selector(onNewGame:)];
	CCMenuItemFont *credits = [CCMenuItemFont itemFromString:@"Credits" target:self selector: @selector(onCredits:)];
	CCMenu *menu = [CCMenu menuWithItems:startNew, credits, nil];
    
    
    for (CCMenuItemFont *each in [menu children]) {
        each.scaleX = 0.0f;
        each.scaleY = 0.0f;
        CCAction *action = [CCSequence actions:
                            [CCDelayTime actionWithDuration: delayTime],
                            [CCScaleTo actionWithDuration:0.5F scale:1.0],
                            nil];
        delayTime += 0.2f;
        [each runAction: action];
    }
    
	titleCenterTop.position = ccp(160, 380);
	[self addChild: titleCenterTop];
    
	titleCenterBottom.position = ccp(160, 300);
	[self addChild: titleCenterBottom];
    
	titleQuotes.position = ccp(160, 345);
	[self addChild: titleQuotes];
    
    titleLeft.position = ccp(80, -80);
    CCAction *titleLeftAction = [CCSequence actions:
                                 [CCDelayTime actionWithDuration: delayTime],
                                 [CCEaseBackOut actionWithAction:
                                  [CCMoveTo actionWithDuration: 1.0 position:ccp(80,345)]],nil];
    [self addChild: titleLeft];
    [titleLeft runAction: titleLeftAction];
    
    titleRight.position = ccp(220, 520);
    CCAction *titleRightAction = [CCSequence actions:
                                  [CCDelayTime actionWithDuration: delayTime],
                                  [CCEaseBackOut actionWithAction:
                                   [CCMoveTo actionWithDuration: 1.0 position:ccp(220,345)]],nil];
    [self addChild: titleRight];
    [titleRight runAction: titleRightAction];
    
	menu.position = ccp(160, 200);
	[menu alignItemsVerticallyWithPadding: 40.0f];
	[self addChild:menu z: 2];

    
	return self;
}

- (void)onNewGame:(id)sender{
	[SceneManager goPlay];
}

- (void)onCredits:(id)sender{
	[SceneManager goCredits];
}
@end
