//
//  DataModel.h
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class riActor;
@class CCLayer;
@class CCTMXTiledMap;

@interface DataModel : NSObject <NSCoding> {
	CCLayer *_gameLayer;
	CCLayer *_gameHUDLayer;	
	
    NSMutableArray * _equipments;

    NSMutableDictionary * _controlPoints;

    NSMutableDictionary * _waypoints;
    NSMutableArray * _tiledMaps;
    
	UIPanGestureRecognizer *_gestureRecognizer;
}

@property (assign) CCLayer *_gameLayer;
@property (assign) CCLayer *_gameHUDLayer;


@property (nonatomic, retain) NSMutableArray * _equipments;
@property (nonatomic, retain) NSMutableDictionary * waypoints;
@property (nonatomic, retain) NSMutableDictionary * controlPoints;

@property (nonatomic, retain) NSMutableArray * tiledMaps;



@property (nonatomic, retain) UIPanGestureRecognizer *_gestureRecognizer;

+ (DataModel*)sharedDataModel;

@end
