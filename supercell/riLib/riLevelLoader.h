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

typedef enum  
{
	DEFAULT_TAG 	= 0,
	BALL 			= 1,
	NUMBER_OF_TAGS 	= 2
} LevelHelper_TAG;


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
	
//    CCTMXTiledMap * _tiledMap;
    
	NSMutableArray* actorDictsArray;	//array of NSDictionary with keys GeneralProperties (NSDictionary) and PhysicProperties (NSDictionary)
	NSMutableArray* jointDictsArray;	//array of NSDictionary

    NSMutableArray* actorsInStage;
	NSMutableDictionary* shapesInStage;	//key - uniqueSpriteName	value - CCSprite* or NSValue with b2Body*
	NSMutableDictionary* actorsInStageNoPhysics;   //key - uniqueSpriteName    value - CCSprite*
	NSMutableDictionary* jointsInStage;   //key - uniqueJointName     value - NSValue withPointer of b2Joint*
	NSMutableDictionary* batchNodes;		//key - textureName			value - NSDictionary

    
	CGRect wb;
	BOOL addSpritesToLayerWasUsed;
	BOOL addObjectsToWordWasUsed;
    BOOL levelLoaded;
	
    SpaceManagerCocos2d * _spaceManager;
    cpSpace* _space; //hold pointer to properly release bodies and joints
	GameLayer* _gameLayer; //hold pointer to properly release the sprites
}

@property (nonatomic, assign) cpSpace * space;
@property (nonatomic, assign) GameLayer * gameLayer;
@property (nonatomic, assign) SpaceManagerCocos2d * spaceManager;


-(id) initWithContentOfFile:(NSString*)levelFile;

-(id) initWithContentOfFile:(NSString*)levelFile 
			 levelSubfolder:(NSString*)levelFolder 
			imagesSubfolder:(NSString*)imgFolder;


+(id) riLevelLoaderWithContentOfFile:(NSString*)levelFile;

//curently only level files can be in subfolders - just pass @"" in imageSubfolder
+(id) riLevelLoaderWithContentOfFile:(NSString*)levelFile 
						  levelSubfolder:(NSString*)levelFolder 
						 imagesSubfolder:(NSString*)imgFolder;

-(void) step;

-(void) addEverythingToSpace:(cpSpace*)world gameLayer:(GameLayer*)cocosLayer;

-(void) addSpritesToLayer:(GameLayer*)cocosLayer;

-(riActor *) addActorWithName:(NSString *)name;
-(void) increaseActorWithName:(NSString *)name count:(int)incremental delay:(float)delay;

-(BOOL) removeActor:(riActor*)actor cleanupShape:(BOOL)clean;
-(BOOL) removeShapeOfActor:(riActor*)actor;

-(BOOL) hasSpaceBoundaries;

-(void) createSpaceBoundaries:(cpSpace*)world;

-(unsigned int) numberOfBatchNodesUsed;

-(riActor*) spriteWithName:(NSString*)name; 

-(cpBody*) bodyWithName:(NSString*)name;

-(riActor*) actorWithDictionary:(NSDictionary *) dictionar;

-(riActor*) actorWithName:(NSString*)name;

-(riActor*) actorWithName:(NSString*)name 
                        gameLayer:(GameLayer*)cocosLayer; 

//discution
//this will return a NSMutableArray that holds NSValues - withPointers of cpShape
//in cpShape->data there is cpBody, in cpBody->data there is CCSprite
//this was done in order to be able to release a body from the cpSpace

-(NSMutableArray*) newBodyWithName:(NSString*)name 
                                   world:(cpSpace*)world 
                            gameLayer:(GameLayer*)cocosLayer;

-(NSMutableArray*) spritesWithTag:(LevelHelper_TAG)tag;

-(NSMutableArray*) bodiesWithTag:(LevelHelper_TAG)tag;

-(NSMutableArray*) newSpritesWithTag:(LevelHelper_TAG)tag
                        gameLayer:(GameLayer*)cocosLayer;

-(NSMutableArray*) newBodiesWithTag:(LevelHelper_TAG)tag 
							  world:(cpSpace*)world 
					   gameLayer:(GameLayer*)cocosLayer;

-(BOOL) removeSpriteWithName:(NSString*)name;

-(BOOL) removeSprite:(riActor*)ccsprite;

-(BOOL) removeAllSprites;

-(BOOL) removeBodyWithName:(NSString*)name;

-(BOOL) removeAllBodies;

-(cpConstraint*) jointWithName:(NSString*)name;

-(BOOL) removeJointWithName:(NSString*)name;

-(BOOL) removeJoint:(cpConstraint*) joint;

-(BOOL) removeAllJoints;

@end

#endif
 