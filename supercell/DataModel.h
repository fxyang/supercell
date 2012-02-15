//
//  DataModel.h
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpaceManagerCocos2d.h"
#import "riActor.h"

@interface DataModel : NSObject <NSCoding> {
	CCLayer *_gameLayer;
	CCLayer *_gameHUDLayer;	
	
	NSMutableArray *_projectiles;
	NSMutableArray *_towers;
	NSMutableArray *_targets;	
	NSMutableArray *_waypoints;	
	
	NSMutableArray *_waves;	
    NSMutableArray * _equipments;
	riActor *  _actor;
    
	UIPanGestureRecognizer *_gestureRecognizer;
}

@property (nonatomic, retain) CCLayer *_gameLayer;
@property (nonatomic, retain) CCLayer *_gameHUDLayer;

@property (nonatomic, retain) NSMutableArray * _projectiles;
@property (nonatomic, retain) NSMutableArray * _towers;
@property (nonatomic, retain) NSMutableArray * _targets;
@property (nonatomic, retain) NSMutableArray * _waypoints;

@property (nonatomic, retain) NSMutableArray * _waves;

@property (nonatomic, retain) NSMutableArray * _equipments;
@property (nonatomic, retain) riActor * _actor;


@property (nonatomic, retain) UIPanGestureRecognizer *_gestureRecognizer;

+ (DataModel*)getModel;

@end
