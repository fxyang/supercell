//
//  Wave.h
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

#import "Creep.h"

@interface Wave : CCNode {
	float _spawnRate;
	int _redCreeps;
    int _greenCreeps;
	Creep * _creepType;
}

@property (nonatomic) float spawnRate;
@property (nonatomic) int redCreeps;
@property (nonatomic) int greenCreeps;
@property (nonatomic, retain) Creep *creepType;

- (id)initWithCreep:(Creep *)creep SpawnRate:(float)spawnrate RedCreeps:(int)redcreeps GreenCreeps:(int)greencreeps;

@end
