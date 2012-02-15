//
//  DataModel.m
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataModel.h"

@implementation DataModel

@synthesize _gameLayer;
@synthesize _gameHUDLayer;

@synthesize _projectiles;
@synthesize _towers;
@synthesize _targets;
@synthesize _waypoints;

@synthesize _waves;

@synthesize _equipments;
@synthesize _actor;

@synthesize _gestureRecognizer;

static DataModel *_sharedContext = nil;

+(DataModel*)getModel 
{
	if (!_sharedContext) {
		_sharedContext = [[self alloc] init];
	}
	
	return _sharedContext;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    
}

-(id)initWithCoder:(NSCoder *)coder {
    
	return self;
}

- (id) init
{
	if ((self = [super init])) {
		_projectiles = [[NSMutableArray alloc] init];
		_towers = [[NSMutableArray alloc] init];
		_targets = [[NSMutableArray alloc] init];
		
		_waypoints = [[NSMutableArray alloc] init];
        _equipments = [[NSMutableArray alloc] init];

		_waves = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {	
	self._gameLayer = nil;
	self._gameHUDLayer = nil;
	self._gestureRecognizer = nil;
	
	[_projectiles release];
	_projectiles = nil;
	
	[_towers release];
	_towers = nil;
	
	[_targets release];
	_targets = nil;	
	
	[_waypoints release];
	_waypoints = nil;
	
    [_equipments release];
	_equipments = nil;
    
    [_actor release];
	_actor = nil;
    
	[_waves release];
	_waves = nil;	
	[super dealloc];
}

@end
