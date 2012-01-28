//
//  Wave.m
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Wave.h"

@implementation Wave

@synthesize spawnRate = _spawnRate;
@synthesize redCreeps = _redCreeps;
@synthesize greenCreeps = _greenCreeps;
@synthesize creepType = _creepType;

-(id) init
{
	if( (self=[super init]) ) {
		
	}
	
	return self;
}

- (id) initWithCreep:(Creep *)creep SpawnRate:(float)spawnrate RedCreeps:(int)redcreeps GreenCreeps: (int)greencreeps
{
	NSAssert(creep!=nil, @"Invalid creep for wave.");
    
	if( (self = [self init]) )
	{
		_creepType = creep;
		_spawnRate = spawnrate;
		_redCreeps = redcreeps;
        _greenCreeps = greencreeps;
	}
	return self;
}


@end