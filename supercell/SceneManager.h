//
//  SceneManager.h
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

#import "MenuLayer.h"
#import "GameLayer.h"
#import "CreditsLayer.h"

#import "GameHUD.h"

@interface SceneManager : NSObject {
}

+(void) goMenu;
+(void) goPlay;
+(void) goCredits;

@end