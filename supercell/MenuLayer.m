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
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
	self = [super init];
    
	CCLabelTTF *title = [CCLabelTTF labelWithString:@"Menu System" fontName:@"Marker Felt" fontSize:kMenuTitleFontSize];
    
    float delayTime = 0.3f;
    
    [CCMenuItemFont setFontSize:kMenuItemFontSize];
	CCMenuItemFont *startNew = [CCMenuItemFont itemFromString:@"New Game" target:self selector: @selector(onNewGame:)];
    CCMenuItemFont *setup = [CCMenuItemFont itemFromString:@"Setting" target:self selector: @selector(onSetting:)];
	CCMenuItemFont *levels = [CCMenuItemFont itemFromString:@"Levels" target:self selector: @selector(onNewLevel:)];
	CCMenuItemFont *credits = [CCMenuItemFont itemFromString:@"Credits" target:self selector: @selector(onCredits:)];
	CCMenu *menu = [CCMenu menuWithItems:startNew,setup,levels,credits, nil];
    
    
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

    
    title.position = ccp(winSize.width/2, winSize.height/2 +100);
    CCAction *titleAction = [CCSequence actions:
                                 [CCDelayTime actionWithDuration: delayTime],
                                 [CCEaseBackOut actionWithAction:
                                  [CCMoveBy actionWithDuration: 1.0 position:ccp(0,100)]],nil];
    [self addChild: title];
    [title runAction: titleAction];
    
    
	menu.position = ccp(winSize.width/2, winSize.height/2 - 100);
	[menu alignItemsVerticallyWithPadding: 80.0f];
	[self addChild:menu z: 2];

    
	return self;
}

- (void)onNewGame:(id)sender{
	[SceneManager goPlay];
}

- (void)onSetting:(id)sender{
	[SceneManager goCredits];
}

- (void)onNewLevel:(id)sender{
	[SceneManager goCredits];
}

- (void)onCredits:(id)sender{
	[SceneManager goCredits];
}
@end
