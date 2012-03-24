//
//  Player.m
//  supercell
//
//  Created by Feixue Yang on 12-03-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Player.h"

@implementation Player

-(Player *)init{
    if ((self = [super init])) {
        _weapons = [[NSMutableArray alloc] initWithCapacity:20];
        _money = 0;
        _sunshine = 0;

    }
    return self;
}

-(void) dellac{
    
    [_weapons release];
    _weapons = nil;

    [super dealloc];
}

@end
