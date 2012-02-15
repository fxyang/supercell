//
//  riConstraintNode.h
//  supercell
//
//  Created by Feixue Yang on 12-02-03.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

/*
 Verlet Rope for cocos2d
 
 Visual representation of a rope with Verlet integration.
 The rope can't (quite obviously) collide with objects or itself.
 This was created to use in conjuction with Box2d's new b2RopeJoint joint, although it's not strictly necessary.
 Use a b2RopeJoint to physically constrain two bodies in a box2d world and use VRope to visually draw the rope in cocos2d. (or just draw the rope between two moving or static points)
 
 *** IMPORTANT: VRope does not create the b2RopeJoint. You need to handle that yourself, VRope is only responsible for rendering the rope
 *** By default, the rope is fixed at both ends. If you want a free hanging rope, modify VRope.h and VRope.mm to only take one body/point and change the update loops to include the last point. 
 
 HOW TO USE:
 Import VRope.h into your class
 
 CREATE:
 To create a verlet rope, you need to pass two b2Body pointers (start and end bodies of rope)
 and a CCSpriteBatchNode that contains a single sprite for the rope's segment. 
 The sprite should be small and tileable horizontally, as it gets repeated with GL_REPEAT for the necessary length of the rope segment.
 
 ex:
 CCSpriteBatchNode *ropeSegmentSprite = [CCSpriteBatchNode batchNodeWithFile:@"ropesegment.png" ]; //create a spritesheet 
 [self addChild:ropeSegmentSprite]; //add batchnode to cocos2d layer, vrope will be responsible for creating and managing children of the batchnode, you "should" only have one batchnode instance
 VRope *verletRope = [[VRope alloc] init:bodyA pointB:bodyB spriteSheet:ropeSegmentSprite];
 
 
 UPDATING:
 To update the verlet rope you need to pass the time step
 ex:
 [verletRope updateRope:dt];
 
 
 DRAWING:
 From your layer's draw loop, call the updateSprites method
 ex:
 [verletRope updateSprites];
 
 Or you can use the debugDraw method, which uses cocos2d's ccDrawLine method
 ex:
 [verletRope debugDraw];
 
 REMOVING:
 To remove a rope you need to call the removeSprites method and then release:
 [verletRope removeSprites]; //remove the sprites of this rope from the spritebatchnode
 [verletRope release];
 
 There are also a few helper methods to use the rope without box2d bodies but with CGPoints only.
 Simply remove the Box2D.h import and use the "WithPoints" methods.
 */

#ifndef riVerletRope_h
#define riVerletRope_h

#define kRopeStatusActive       1
#define kRopeStatusHide         2
#define kRopeStatusRemoving		3
#define kRopeStatusRemoved		4

#define kRopeSegmentLengthFactorDefault    250 
#define kRopeNumOfSegmentsFactorDefault    24 
#define kRopeNumOfIterationsFactor         16 
#define kRopeGravityFactor                 0.1
#define kRopeLengthDefault                 150


#import "SpaceManagerCocos2d.h"

@class GameLayer;

@interface riVerletPoint : NSObject {
	float x,y,oldx,oldy;
}

@property(nonatomic,assign) float x;
@property(nonatomic,assign) float y;

-(void)setPos:(float)argX y:(float)argY;
-(void)update;
-(void)applyGravity:(float)dt;

@end

@interface riVerletStick : NSObject {
	riVerletPoint *pointA;
	riVerletPoint *pointB;
	float hypotenuse;
}
-(id)initWith:(riVerletPoint*)argA pointb:(riVerletPoint*)argB;
-(void)contract;
-(riVerletPoint*)getPointA;
-(riVerletPoint*)getPointB;
@end


@interface riVerletRope : NSObject
{
    GameLayer * _gameLayer;
    SpaceManagerCocos2d * _spaceManager;
	cpConstraint * _ropeConstraint;
    CGPoint _pointA, _pointB;
    int _status;
    int _ropeSegmentFactor;
    
    int numPoints;
	NSMutableArray *vPoints;
	NSMutableArray *vSticks;
	NSMutableArray *ropeSprites;
	CCSpriteBatchNode* ropeSpriteSheet;
	float antiSagHack;
    float _ropeLength;
}

@property (readwrite, assign) GameLayer * gameLayer;
@property (readwrite, assign) cpConstraint * ropeConstraint;
@property (readwrite, assign) SpaceManagerCocos2d * spaceManager;
@property (readwrite,assign) CGPoint pointA,pointB;
@property (readwrite,assign) int status;
@property (readwrite,assign) int ropeSegmentFactor;
@property (readwrite,assign) float ropeLength;;



- (id) initWithConstraint:(cpConstraint*)c spriteSheet:(CCSpriteBatchNode*)spriteSheetArg isSolid:(BOOL)b spaceManager:smgr;
-(id)initWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB spriteSheet:(CCSpriteBatchNode*)spriteSheetArg isSolid:(BOOL)b spaceManager:smgr;
-(void)createRope:(CGPoint)pointA pointB:(CGPoint)pointB;
-(void)createSolidRope:(CGPoint)pointA pointB:(CGPoint)pointB;

-(void)update:(float)dt;
-(void)reset;
-(void)resetWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB;
-(void)updateWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB dt:(float)dt;
-(void)debugDraw;
-(void)updateSprites;
-(void)removeRopeWithCutAt:(CGPoint)p duration:(float)dt;
-(void)removeSprites;

@end

#endif

