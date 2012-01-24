//
//  BaseLayer.m
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseLayer.h"

@implementation BaseLayer
-(id) init{
	self = [super init];
	if(nil == self){
		return nil;
	}
    
	self.isTouchEnabled = YES;
    
	CCSprite *bg = [CCSprite spriteWithFile: @"Default.png"];
	bg.position = ccp(160,240);
	[self addChild: bg z:0];
    
	return self;
}
@end