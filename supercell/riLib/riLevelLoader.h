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
	BODY_STATIC = 0, 
	BODY_KINEMATIC = 1,
    BODY_DYNAMIC = 2,
    BODY_NOPHYSIC = 3
} BodyType;

typedef enum { 
    SINGLE_PATTERN = 0,
	INFINITY_PATTERN = 1, 
	INFINITY_RANDOM = 2,
    FINITY_PATTERN = 3,
    FINITY_RANDOM = 4
} CountType;

enum LH_JOINT_TYPE
{
	LH_DISTANCE_JOINT = 0,
	LH_REVOLUTE_JOINT,
	LH_PRISMATIC_JOINT,
	LH_PULLEY_JOINT,
	LH_GEAR_JOINT,
	LH_LINE_JOINT,
	LH_WELD_JOINT
};

#define BATCH_NODE_CAPACITY 100 //you should change this value if you have more then 100 sprites in a texture image


@protocol riLevelLoaderCustomCCSprite
@optional
-(riActor*) spriteFromDictionary:(NSDictionary*)spriteProp;
-(riActor*) spriteWithBatchFromDictionary:(NSDictionary*)spriteProp batchNode:(CCSpriteBatchNode*)batch;
-(void) removeFromBatchNode:(CCSprite*)sprite;
@end

@interface riLevelLoader : NSObject<riLevelLoaderCustomCCSprite> {
	
	NSMutableArray* spriteDictsArray;	//array of NSDictionary with keys GeneralProperties (NSDictionary) and PhysicProperties (NSDictionary)
	NSMutableArray* jointDictsArray;	//array of NSDictionary
    NSMutableArray * backstageDictsArray;

    
	NSMutableDictionary* actorsInStage;	//key - uniqueSpriteName	value - CCSprite* or NSValue with b2Body*
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

@property (readwrite, assign) SpaceManagerCocos2d * spaceManager;

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

-(void) addActorsToWorld:(cpSpace*)world gameLayer:(GameLayer*)cocosLayer;

-(void) addSpritesToLayer:(GameLayer*)cocosLayer;

-(BOOL) hasWorldBoundaries;

-(void) createWorldBoundaries:(cpSpace*)world;

-(unsigned int) numberOfBatchNodesUsed;

-(riActor*) spriteWithUniqueName:(NSString*)name; 

-(cpBody*) bodyWithUniqueName:(NSString*)name;

-(riActor*) newSpriteWithUniqueName:(NSString*)name 
                        gameLayer:(GameLayer*)cocosLayer; 

//discution
//this will return a NSMutableArray that holds NSValues - withPointers of cpShape
//in cpShape->data there is cpBody, in cpBody->data there is CCSprite
//this was done in order to be able to release a body from the cpSpace

-(NSMutableArray*) newBodyWithUniqueName:(NSString*)name 
                                   world:(cpSpace*)world 
                            gameLayer:(GameLayer*)cocosLayer;

-(NSMutableArray*) spritesWithTag:(LevelHelper_TAG)tag;

-(NSMutableArray*) bodiesWithTag:(LevelHelper_TAG)tag;

-(NSMutableArray*) newSpritesWithTag:(LevelHelper_TAG)tag
                        gameLayer:(GameLayer*)cocosLayer;

-(NSMutableArray*) newBodiesWithTag:(LevelHelper_TAG)tag 
							  world:(cpSpace*)world 
					   gameLayer:(GameLayer*)cocosLayer;

-(BOOL) removeSpriteWithUniqueName:(NSString*)name;

-(BOOL) removeSprite:(riActor*)ccsprite;

-(BOOL) removeAllSprites;

-(BOOL) removeBodyWithUniqueName:(NSString*)name;

-(BOOL) removeAllBodies;

-(cpConstraint*) jointWithUniqueName:(NSString*)name;

-(BOOL) removeJointWithUniqueName:(NSString*)name;

-(BOOL) removeJoint:(cpConstraint*) joint;

-(BOOL) removeAllJoints;

-(void) setSpriteProperties:(riActor*)actor 
           spriteProperties:(NSDictionary*)spriteProp;

-(void) setActorProperties:(riActor*)actor
           actorProperties:(NSDictionary*)actorProp;

@end

#endif
