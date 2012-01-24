//
//  PlayLayer.m
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PlayLayer.h"

@implementation PlayLayer
-(id) init{
	self = [super init];
	if (!self) {
		return nil;
	}
    
	CCMenuItemFont *back = [CCMenuItemFont itemFromString:@"back" target:self selector: @selector(back:)];
	CCMenu *menu = [CCMenu menuWithItems: back, nil];
    
	menu.position = ccp(160, 150);
	[self addChild: menu];
    
	return self;
}

-(void) back: (id) sender{
	[SceneManager goMenu];
}

@end