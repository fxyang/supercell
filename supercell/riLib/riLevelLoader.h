//
//  riLevelLoader.h
//  supercell
//
//  Created by Feixue Yang on 12-02-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#ifndef riLevelLoader_h
#define riLevelLoader_h

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "chipmunk.h"
#import "SpaceManagerCocos2d.h"

@class riActor;

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
	
	NSArray* spriteDictsArray;	//array of NSDictionary with keys GeneralProperties (NSDictionary) and PhysicProperties (NSDictionary)
	NSArray* jointDictsArray;	//array of NSDictionary
    
	NSMutableDictionary* ccSpritesInScene;	//key - uniqueSpriteName	value - CCSprite* or NSValue with b2Body*
	NSMutableDictionary* noPhysicSprites;   //key - uniqueSpriteName    value - CCSprite*
	NSMutableDictionary* ccJointsInScene;   //key - uniqueJointName     value - NSValue withPointer of b2Joint*
	NSMutableDictionary* batchNodes;		//key - textureName			value - NSDictionary

	CGRect wb;
	BOOL addSpritesToLayerWasUsed;
	BOOL addObjectsToWordWasUsed;
	
    SpaceManagerCocos2d * _spaceManager;
    cpSpace* world; //hold pointer to properly release bodies and joints
	CCLayer* gameLayer; //hold pointer to properly release the sprites
}

@property (readwrite, assign) SpaceManagerCocos2d * spaceManager;

-(id) initWithContentOfFile:(NSString*)levelFile;

-(id) initWithContentOfFile:(NSString*)levelFile 
			 levelSubfolder:(NSString*)levelFolder 
			imagesSubfolder:(NSString*)imgFolder;


+(id) LevelHelperLoaderWithContentOfFile:(NSString*)levelFile;

//curently only level files can be in subfolders - just pass @"" in imageSubfolder
+(id) LevelHelperLoaderWithContentOfFile:(NSString*)levelFile 
						  levelSubfolder:(NSString*)levelFolder 
						 imagesSubfolder:(NSString*)imgFolder;


-(void) addActorsToWorld:(cpSpace*)world gameLayer:(CCLayer*)cocosLayer;

-(void) addSpritesToLayer:(CCLayer*)cocosLayer;

-(BOOL) hasWorldBoundaries;

-(void) createWorldBoundaries:(cpSpace*)world;

-(unsigned int) numberOfBatchNodesUsed;

-(CCSprite*) spriteWithUniqueName:(NSString*)name; 

-(cpBody*) bodyWithUniqueName:(NSString*)name;

-(CCSprite*) newSpriteWithUniqueName:(NSString*)name 
                        gameLayer:(CCLayer*)cocosLayer; 

//discution
//this will return a NSMutableArray that holds NSValues - withPointers of cpShape
//in cpShape->data there is cpBody, in cpBody->data there is CCSprite
//this was done in order to be able to release a body from the cpSpace

-(NSMutableArray*) newBodyWithUniqueName:(NSString*)name 
                                   world:(cpSpace*)world 
                            gameLayer:(CCLayer*)cocosLayer;

-(NSMutableArray*) spritesWithTag:(LevelHelper_TAG)tag;

-(NSMutableArray*) bodiesWithTag:(LevelHelper_TAG)tag;

-(NSMutableArray*) newSpritesWithTag:(LevelHelper_TAG)tag
                        gameLayer:(CCLayer*)cocosLayer;

-(NSMutableArray*) newBodiesWithTag:(LevelHelper_TAG)tag 
							  world:(cpSpace*)world 
					   gameLayer:(CCLayer*)cocosLayer;

-(BOOL) removeSpriteWithUniqueName:(NSString*)name;

-(BOOL) removeSprite:(CCSprite*)ccsprite;

-(BOOL) removeAllSprites;

-(BOOL) removeBodyWithUniqueName:(NSString*)name;

-(BOOL) removeAllBodies;

-(cpConstraint*) jointWithUniqueName:(NSString*)name;

-(BOOL) removeJointWithUniqueName:(NSString*)name;

-(BOOL) removeJoint:(cpConstraint*) joint;

-(BOOL) removeAllJoints;

-(void) setSpriteProperties:(riActor*)actor 
           spriteProperties:(NSDictionary*)spriteProp;

@end

#endif
