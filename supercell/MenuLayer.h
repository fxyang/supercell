//
//  MenuLayer.h
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseLayer.h"

#import "SceneManager.h"
#import "GameLayer.h"
#import "CreditsLayer.h"

#define kMenuTitleFontSize 60
#define kMenuItemFontSize 48

@interface MenuLayer : BaseLayer {
}

- (void)onNewGame:(id)sender;
- (void)onCredits:(id)sender;
@end
