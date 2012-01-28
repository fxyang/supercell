//
//  GameHUD.h
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"


@interface GameHUD : CCLayer {
	CCSprite * background;
	
	CCSprite * selSpriteRange;
    CCSprite * selSprite;
    NSMutableArray * movableSprites;
    int resources;
    CCLabelTTF *resourceLabel;
    CCLabelTTF *waveCountLabel;
    
    float baseHpPercentage;
    CCProgressTimer *healthBar;
    
}

@property (nonatomic, assign) int resources;
@property (nonatomic, assign) float baseHpPercentage;




+ (GameHUD *)sharedHUD;
-(void) updateBaseHp:(int)amount;
-(void) updateResources:(int)amount;
-(void) updateResourcesNom;
-(void) updateWaveCount;


@end
