//
//  DataModel.h
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface DataModel : NSObject <NSCoding> {
	CCLayer *_gameLayer;
	CCLayer *_gameHUDLayer;	
	
	NSMutableArray *_projectiles;
	NSMutableArray *_towers;
	NSMutableArray *_targets;	
	NSMutableArray *_waypoints;	
	
	NSMutableArray *_waves;	
	
	UIPanGestureRecognizer *_gestureRecognizer;
}

@property (nonatomic, retain) CCLayer *_gameLayer;
@property (nonatomic, retain) CCLayer *_gameHUDLayer;

@property (nonatomic, retain) NSMutableArray * _projectiles;
@property (nonatomic, retain) NSMutableArray * _towers;
@property (nonatomic, retain) NSMutableArray * _targets;
@property (nonatomic, retain) NSMutableArray * _waypoints;

@property (nonatomic, retain) NSMutableArray * _waves;

@property (nonatomic, retain) UIPanGestureRecognizer *_gestureRecognizer;;
+ (DataModel*)getModel;

@end
