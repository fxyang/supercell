//
//  DataModel.m
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataModel.h"
#import "riActor.h"
#import "SpaceManagerCocos2d.h"

@implementation DataModel

@synthesize _gameLayer;
@synthesize _gameHUDLayer;


@synthesize _equipments;
@synthesize waypoints = _waypoints;
@synthesize controlPoints = _controlPoints;

@synthesize tiledMaps = _tiledMaps;

@synthesize _gestureRecognizer;

static DataModel *_sharedContext = nil;

+(DataModel*)sharedDataModel 
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
        _equipments = [[NSMutableArray alloc] init];
        
        _waypoints = [[NSMutableDictionary alloc] init];
        _controlPoints = [[NSMutableDictionary alloc] init];

        _tiledMaps = [[NSMutableArray alloc] init];

	}
	return self;
}

- (void)dealloc {	
	self._gameLayer = nil;
	self._gameHUDLayer = nil;
	self._gestureRecognizer = nil;

	
    [_equipments release];
	_equipments = nil;

    
	self.waypoints = nil;
    self.controlPoints = nil;

    [_tiledMaps release];
    _tiledMaps = nil;
    
	[super dealloc];
}

@end
