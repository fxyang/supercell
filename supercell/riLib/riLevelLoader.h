//
//  riLevelLoader.h
//  supercell
//
//  Created by Feixue Yang on 12-02-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#ifndef riLevelLoader_h
#define riLevelLoader_h

#import "SpaceManagerCocos2d.h"

@class riActor;
@class GameLayer;

typedef enum { 
    kCountSingle = 0,
    kCountLimitFinity = 1,
    kCountFinity = 2,
	kCountInfinity = 3 
} CountType;

typedef enum
{
	kPinJoint = 0,
	kSpringJoint = 1,
	kRotarySpringJoint = 2,
    kSlideJoint = 3,
	kGrooveJoint = 4,
	kPivotJoint = 5,
    kMotorJoint = 6,
	kGearJoint = 7,
    kRatchetJoint = 8,
    kRotaryLimitJoint = 9
} JointType;

#define BATCH_NODE_CAPACITY 100 //you should change this value if you have more then 100 sprites in a texture image


@protocol riLevelLoaderCustomCCSprite
@optional
-(riActor*) spriteFromDictionary:(NSDictionary*)spriteProp;
-(riActor*) spriteWithBatchFromDictionary:(NSDictionary*)spriteProp batchNode:(CCSpriteBatchNode*)batch;
-(void) removeFromBatchNode:(CCSprite*)sprite;
@end

@interface riLevelLoader : NSObject<riLevelLoaderCustomCCSprite> {
	    
	NSMutableArray* actorDictsArray;
	NSMutableArray* jointDictsArray;

    NSMutableArray* actorsInStage;
	NSMutableDictionary* shapesInStage;	
	NSMutableArray* actorsInStageNoPhysics;   
	NSMutableDictionary* jointsInStage;   
	NSMutableDictionary* batchNodes;
    
	CGRect wb;
    BOOL levelLoaded;
	
    cpSpace* _space; 	
    GameLayer* _gameLayer; 
    SpaceManagerCocos2d * _spaceManager;
}

@property (nonatomic, assign) cpSpace * space;
@property (nonatomic, assign) GameLayer * gameLayer;
@property (nonatomic, assign) SpaceManagerCocos2d * spaceManager;


-(id) initWithContentOfFile:(NSString*)levelFile;
-(id) initWithContentOfFile:(NSString*)levelFile 
			 levelSubfolder:(NSString*)levelFolder 
			imagesSubfolder:(NSString*)imgFolder;
+(id) riLevelLoaderWithContentOfFile:(NSString*)levelFile;
-(BOOL) hasSpaceBoundaries;
-(void) createSpaceBoundaries:(cpSpace*)world;

//curently only level files can be in subfolders - just pass @"" in imageSubfolder
+(id) riLevelLoaderWithContentOfFile:(NSString*)levelFile 
						  levelSubfolder:(NSString*)levelFolder 
						 imagesSubfolder:(NSString*)imgFolder;

-(void) step;
-(void) addEverythingToSpaceAndGameLayer;
-(void) addSpritesToGameLayer;

-(riActor *) addActorWithName:(NSString *)name;

-(BOOL) removeSpriteOfActor:(riActor*)actor;
-(BOOL) removeShapeOfActor:(riActor*)actor;
-(BOOL) removeBodyWithActorSigniture:(NSString*)as;
-(BOOL) removeJointWithName:(NSString*)name;

-(BOOL) removeJoint:(cpConstraint*) joint;
-(void) increaseActorCountWithName:(NSString *)name count:(int)incremental delay:(float)delay;

-(NSArray*) actorsWithName:(NSString*)name; 
-(cpConstraint*) jointWithName:(NSString*)name;
-(unsigned int) numberOfBatchNodesUsed;

-(BOOL) removeAllSprites;
-(BOOL) removeAllBodies;
-(BOOL) removeAllJoints;

@end

#endif
 