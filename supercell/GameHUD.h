//
//  GameHUD.h
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "DataModel.h"

enum {
    JOYSTICK_TAG = 100
};
enum {
    JOYSTICK_Z = 100
};
#define kDefaultCredit 200

@class riJoystick;

@interface GameHUD : CCLayer {
	CCSprite * background;
	
	CCSprite * selSpriteRange;
    CCSprite * selSprite;
    NSMutableArray * movableSprites;
    int money;
    CCLabelTTF *moneyLabel;
    
    float baseHpPercentage;
    CCProgressTimer *healthBar;
    
    riJoystick * joystick;
    int piggyBank;
    
}

@property (nonatomic, assign) int money;
@property (nonatomic, assign) float baseHpPercentage;
@property (nonatomic, readonly) riJoystick * joystick;




+ (GameHUD *)sharedHUD;
-(void) updateBaseHp:(int)amount;
-(void) updateMoney:(int)amount;
-(void) updateMoney;


@end
