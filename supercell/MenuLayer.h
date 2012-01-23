//
//  MenuLayer.h
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

#import "SceneManager.h"

@interface MenuLayer : CCLayer {
}

- (void)onNewGame:(id)sender;
- (void)onCredits:(id)sender;
@end
