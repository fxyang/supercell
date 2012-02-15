//
//  riLevelLoader.m
//  supercell
//
//  Created by Feixue Yang on 12-02-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "riLevelLoader.h"
#import "riActor.h"

/// converts degrees to radians
#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0f * (float)M_PI)
/// converts radians to degrees
#define RADIANS_TO_DEGREES(__ANGLE__) ((__ANGLE__) / (float)M_PI * 180.0f)

#if TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64

#define riRectFromString(str) CGRectFromString(str)
#define riPointFromString(str) CGPointFromString(str)
#else
#define riRectFromString(str) NSRectToCGRect(NSRectFromString(str))
#define riPointFromString(str) NSPointToCGPoint(NSPointFromString(str))
#endif



@interface riLevelLoader (Private)

-(void) initObjects;

-(void) addBatchNodesToLayer:(CCLayer*)_gameLayer;

-(NSMutableArray*) cpBodyFromDictionary:(NSDictionary*)spritePhysic
                       spriteProperties:(NSDictionary*)spriteProp
                                   data:(CCSprite*)ccsprite 
                                  world:(cpSpace*)world;

-(NSValue*) jointFromDictionary:(NSDictionary*)dictionary 
                              world:(cpSpace*)world;

-(void)loadLevelHelperSceneFile:(NSString*)levelFile 
					inDirectory:(NSString*)subfolder
				   imgSubfolder:(NSString*)imgFolder;
@end

@implementation riLevelLoader

@synthesize spaceManager = _spaceManager;


-(void) initObjects
{
	batchNodes = [[NSMutableDictionary alloc] init];	
	ccSpritesInScene = [[NSMutableDictionary alloc] init];
	noPhysicSprites = [[NSMutableDictionary alloc] init];
	ccJointsInScene = [[NSMutableDictionary alloc] init];
	
	addSpritesToLayerWasUsed = NO;
	addObjectsToWordWasUsed = NO;
	
}

-(id) initWithContentOfFile:(NSString*)levelFile
{
	NSAssert(nil!=levelFile, @"Invalid file given to LevelHelperLoader");
	
	if(!(self = [super init]))
	{
		NSLog(@"LevelHelperLoader ****ERROR**** : [super init] failer ***");
		return self;
	}
	
	[self initObjects];
	[self loadLevelHelperSceneFile:levelFile inDirectory:@"" imgSubfolder:@""];
	
	
	return self;
}

-(id) initWithContentOfFile:(NSString*)levelFile 
			 levelSubfolder:(NSString*)levelFolder 
			imagesSubfolder:(NSString*)imgFolder
{
	NSAssert(nil!=levelFile, @"Invalid file given to LevelHelperLoader");
	
	if(!(self = [super init]))
	{
		NSLog(@"LevelHelperLoader ****ERROR**** : [super init] failer ***");
		return self;
	}
	
	[self initObjects];
	
	[self loadLevelHelperSceneFile:levelFile inDirectory:levelFolder imgSubfolder:imgFolder];
	
	return self;
	
}

+(id)LevelHelperLoaderWithContentOfFile:(NSString*)levelFile
{
	return [[[self alloc] initWithContentOfFile:levelFile] autorelease];
}

+(id) LevelHelperLoaderWithContentOfFile:(NSString*)levelFile 
						  levelSubfolder:(NSString*)levelFolder 
						 imagesSubfolder:(NSString*)imgFolder
{
	return [[[self alloc] initWithContentOfFile:levelFile 
								 levelSubfolder:levelFolder 
								imagesSubfolder:imgFolder] autorelease];
}

-(void) addActorsToWorld:(cpSpace*)_world gameLayer:(CCLayer*)_gameLayer
{
	
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You can't use method addObjectsToWorld because you already used addSpritesToLayer. Only one of the two can be used."); 
	NSAssert(addObjectsToWordWasUsed!=YES, @"You can't use method addObjectsToWorld again. You can only use it once. Create a new LevelHelperLoader object if you want to load the level again."); 
	
	addObjectsToWordWasUsed = YES;
	
	gameLayer = _gameLayer;
    world = _world;
	
    //ADD batchNodes To GameLyer
	[self addBatchNodesToLayer:gameLayer];
	
	for(NSDictionary* dictionary in spriteDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		NSDictionary* physicProp = [dictionary objectForKey:@"PhysicProperties"];
        int count = [[dictionary objectForKey:@"Count"] intValue];
        //NSLog(@"count=%d",count);
		
        /*
         
         int count = [dictionary objectForKey:@"Count"];
         cctime birthTime = [dictionary objectForKey:@"BirthTime"];
         if(birthType = FINITY_COUNT){
         
             if(count > 0 && birthTime <= _gameLayer.gameTime){
                 [dictionary removeObjectForKey...
                 [dictionary addObject: forKey:...
                 adding...
                 count--;
                 if(count == 0) 
                 remove....
             }else if(birthTime <= _gameLayer.gameTime){
                 birthTime = birthTime + RandomTime;
                 [dictionary removeObjectForKey...
                 [dictionary addObject: forKey:...
                 adding....
             }else
         
         
         }
         
         
         
         else


         
         */
        
        
		//find the coresponding batch node for this sprite
		NSDictionary* batchNodeDict = [batchNodes objectForKey:[spriteProp objectForKey:@"Image"]];
		CCSpriteBatchNode *batchNode = [batchNodeDict objectForKey:@"CCBatchNode"];
		
		if(nil != batchNode)
		{
            //Create Actor and ADD to batchNode
			riActor* actor = [self spriteWithBatchFromDictionary:spriteProp batchNode:batchNode];
            actor.body = nil;
            actor.shape = nil;
			
            //Create Actor's Body and Shape and Add to ccSpritesInScene
            //Add no physics actor to noPhysicsSprites
			NSString* uniqueName = [spriteProp objectForKey:@"UniqueName"];
			if([[physicProp objectForKey:@"Type"] intValue] != BODY_NOPHYSIC) 
			{
				NSMutableArray* shapes = [self cpBodyFromDictionary:physicProp
                                                   spriteProperties:spriteProp
                                                               data:actor 
                                                              world:world];
				[ccSpritesInScene setObject:shapes forKey:uniqueName];			
			}
			else 
				[noPhysicSprites setObject:actor forKey:uniqueName];
            
//Show Actor
			[batchNode addChild:actor z:[[spriteProp objectForKey:@"ZOrder"] intValue]];
//Show Body and Shape
            if(actor.body != nil && actor.shape != nil){
                [_spaceManager addBody:actor.body];
                [_spaceManager addShape:actor.shape];
            }
		}
	}
	
    
	for(NSDictionary* jointDict in jointDictsArray)
	{
        
		NSValue* joint = [self jointFromDictionary:jointDict world:world];
		if(nil != joint){
            cpConstraint * constraint = (cpConstraint *)[joint pointerValue];
            cpConstraintNode * constraintNode = [cpConstraintNode nodeWithConstraint:constraint];

            [ccJointsInScene setObject:joint 
								forKey:[jointDict objectForKey:@"UniqueName"]];	

//Show Joint
                cpSpaceAddConstraint( world , constraint);
                [gameLayer addChild:constraintNode z:11];            
		}
	}
	
    
}

        /* ONLY Add Sprites (NO Bodies AND Shapes AND Joints)to GameLayer*/

-(void) addSpritesToLayer:(CCLayer*)_gameLayer
{	
	NSAssert(addObjectsToWordWasUsed!=YES, @"You can't use method addSpritesToLayer because you already used addObjectToWorld. Only one of the two can be used."); 
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You can't use method addSpritesToLayer again. You can only use it once. Create a new LevelHelperLoader object if you want to load the level again."); 
	
	addSpritesToLayerWasUsed = YES;
	
	gameLayer = _gameLayer;
    world = 0;
	
	[self addBatchNodesToLayer:gameLayer];
	
	for(NSDictionary* dictionary in spriteDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		//find the coresponding batch node for this sprite
		NSDictionary* batchInfo = [batchNodes objectForKey:[spriteProp objectForKey:@"Image"]];
		CCSpriteBatchNode *batch = [batchInfo objectForKey:@"CCBatchNode"];
		
		if(nil != batch)
		{
			CCSprite* ccsprite = [self spriteWithBatchFromDictionary:spriteProp batchNode:batch];
			if(nil != ccsprite)
			{
				[batch addChild:ccsprite];
				[ccSpritesInScene setObject:ccsprite forKey:[spriteProp objectForKey:@"UniqueName"]];
			}
		}
	}
}

-(BOOL) hasWorldBoundaries
{
	if(wb.origin.x == 0.0f && 
	   wb.origin.x == 0.0f &&
	   wb.size.width == 0.0f &&
	   wb.size.height== 0.0f)
	{
		return NO;
	}
	
	return YES;
}

-(void) createWorldBoundaries:(cpSpace*)space
{
	NSAssert(wb.size.width != 0, @"You can't use method createwb because you have not defined any world boundaries inside LevelHelper."); 
    
    cpBody *staticBody = cpBodyNew(INFINITY, INFINITY);
    cpShape *shape;
    
    CGSize ss = [CCDirector sharedDirector].winSize;
    
    // bottom
    shape = cpSegmentShapeNew(staticBody, ccp(wb.origin.x, ss.height - (wb.origin.y + wb.size.height)), 
                              ccp(wb.origin.x+ wb.size.width, ss.height - (wb.origin.y + wb.size.height)), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // top
    shape = cpSegmentShapeNew(staticBody, ccp(wb.origin.x,ss.height - wb.origin.y), 
                              ccp((wb.origin.x + wb.size.width),ss.height - wb.origin.y), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // left
    shape = cpSegmentShapeNew(staticBody, ccp(wb.origin.x, ss.height - (wb.origin.y + wb.size.height)), 
                              ccp(wb.origin.x, ss.height - wb.origin.y), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    // right
    shape = cpSegmentShapeNew(staticBody, ccp(wb.origin.x + wb.size.width,ss.height - (wb.origin.y + wb.size.height)), 
                              ccp(wb.origin.x + wb.size.width,ss.height - wb.origin.y), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f;
    cpSpaceAddStaticShape(space, shape);
    
    //	groundBox.SetAsEdge(b2Vec2(wb.origin.x/PTM_RATIO, (ss.height - (wb.origin.y + wb.size.height))/PTM_RATIO), 
    //						b2Vec2((wb.origin.x+ wb.size.width)/PTM_RATIO, (ss.height - (wb.origin.y + wb.size.height))/PTM_RATIO));
    //	groundBody->CreateFixture(&groundBox,0);
    //	
    //	// top
    //	groundBox.SetAsEdge(b2Vec2(wb.origin.x/PTM_RATIO, (ss.height - wb.origin.y)/PTM_RATIO), 
    //						b2Vec2((wb.origin.x + wb.size.width)/PTM_RATIO, (ss.height - wb.origin.y)/PTM_RATIO));
    //	groundBody->CreateFixture(&groundBox,0);
    //	
    //	// left
    //	groundBox.SetAsEdge(b2Vec2(wb.origin.x/PTM_RATIO, (ss.height - (wb.origin.y + wb.size.height))/PTM_RATIO), 
    //						b2Vec2(wb.origin.x/PTM_RATIO, (ss.height - wb.origin.y)/PTM_RATIO));
    //	groundBody->CreateFixture(&groundBox,0);
    //	
    //	// right
    //	groundBox.SetAsEdge(b2Vec2((wb.origin.x + wb.size.width)/PTM_RATIO, (ss.height - (wb.origin.y + wb.size.height))/PTM_RATIO),
    //						b2Vec2((wb.origin.x + wb.size.width)/PTM_RATIO, (ss.height - wb.origin.y)/PTM_RATIO));
    //	groundBody->CreateFixture(&groundBox,0);
    //	
    //	
}

-(unsigned int) numberOfBatchNodesUsed
{
	return (int)[batchNodes count] -1;
}

-(CCSprite*) spriteWithUniqueName:(NSString*)name
{
	if(addSpritesToLayerWasUsed)
	{
		return [ccSpritesInScene objectForKey:name];	
	}
	else if(addObjectsToWordWasUsed){
        NSMutableArray* shapes = [ccSpritesInScene objectForKey:name];
        
        if([shapes count] > 0)
        {
            cpShape* shape = (cpShape*)[[shapes objectAtIndex:0] pointerValue];
            
            cpBody* body = shape->body;
            
            return (CCSprite*)body->data;
        }
        
    }else
    {
        return (CCSprite*)[noPhysicSprites objectForKey:name];
        
    }
	
	return nil;
}

-(cpBody*) bodyWithUniqueName:(NSString*)name
{
	if(addObjectsToWordWasUsed)
	{
		NSMutableArray* shapes = [ccSpritesInScene objectForKey:name];
        
        if([shapes count] > 0)
        {
            cpShape* shape = (cpShape*)[[shapes objectAtIndex:0] pointerValue];
            
            return shape->body;
        }
	}
	
	return nil;
}

-(BOOL) removeSpriteWithUniqueName:(NSString*)name
{
	NSAssert(addObjectsToWordWasUsed!=YES, @"You cannot remove a sprite with method removeCCSpriteWithUniqueName if you used the method addObjectToWorld to load your level. Use method removeBody."); 
	
	CCSprite* ccsprite = nil;
	if(!addObjectsToWordWasUsed)
	{
		ccsprite = [ccSpritesInScene objectForKey:name];
	}
	else {
		ccsprite = [noPhysicSprites objectForKey:name];
	}
	if(nil == ccsprite)
	{
		return NO;
	}
	
	if([ccsprite usesBatchNode])
	{
		CCSpriteBatchNode *batchNode = [ccsprite batchNode];
		
		[batchNode removeChild:ccsprite cleanup:YES];
	}
	else {
		NSLog(@"This CCSprite was not created using a batch node so it's your responsibility to remove it.");
		return NO;
	}
	
	
	if(!addObjectsToWordWasUsed)
	{
		[ccSpritesInScene removeObjectForKey:name];
	}
	else {
		[noPhysicSprites removeObjectForKey:name];
	}
	
	
	return YES;
}

-(BOOL) removeSprite:(CCSprite*)ccsprite
{
	NSAssert(addObjectsToWordWasUsed!=YES, @"You cannot remove a sprite with method removeCCSprite if you used the method addObjectToWorld to load your level. Use method removeBody."); 
	
	if(nil == ccsprite)
		return NO;
	
	if([ccsprite usesBatchNode])
	{
		NSArray * keys= nil;
		if(!addObjectsToWordWasUsed)
			keys = [ccSpritesInScene allKeysForObject:ccsprite];
		else {
			keys = [noPhysicSprites allKeysForObject:ccsprite];
		}
		
		CCSpriteBatchNode *batchNode = [ccsprite batchNode];
		
		[batchNode removeChild:ccsprite cleanup:YES];
		
		for(NSString* key in keys)
		{
			if(!addObjectsToWordWasUsed)
				[ccSpritesInScene removeObjectForKey:key];
			else {
				[noPhysicSprites removeObjectForKey:key];
			}
			
		}
	}
	else 
	{
		NSLog(@"This CCSprite was not created using a batch node so it's your responsibility to remove it.");
		return NO;
	}
	
	return YES;
}

-(BOOL) removeAllSprites
{	
	//NSAssert(addObjectsToWordWasUsed!=YES, @"You cannot remove all sprites with method removeAllCCSprites if you used the method addObjectToWorld to load your level. Use method removeAllBodies."); 
	
	NSArray *keys = nil;
	if(!addObjectsToWordWasUsed)
		keys = [ccSpritesInScene allKeys];
	else {
		keys = [noPhysicSprites allKeys];
	}
	
	BOOL removedAll = YES;
	for(NSString* key in keys)
	{
		removedAll = removedAll == [self removeSpriteWithUniqueName:key];
	}
	
	return removedAll;	
}

-(void) removeFromBatchNode:(CCSprite*)sprite
{
	CCSpriteBatchNode *batchNode = [sprite batchNode];
	
	if(nil == batchNode)
		return;
	
	[batchNode removeChild:sprite cleanup:YES];
}

-(BOOL) removeBodyWithUniqueName:(NSString*)name
{
    NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a body with method removeBodyWithUniqueName if you used the method addSpritesToLayer to load your level. Use method removeCCSprite or removeCCSpriteWithUniqueName."); 
	
	NSMutableArray* data = [ccSpritesInScene objectForKey:name];
	
	if(0 != data)
	{
        cpBody* body = 0;
        for(NSValue* value in data)
        {
            
            cpShape* shape = (cpShape*)[value pointerValue];
            body = shape->body;
            
            cpSpaceRemoveShape(world, shape);
            cpShapeFree(shape);
        }
        
        CCSprite* ccsprite = (CCSprite*)body->data;
        
        CCSpriteBatchNode *batchNode = [ccsprite batchNode];
		
		if(nil != batchNode)
            [batchNode removeChild:ccsprite cleanup:YES];
		
        [ccSpritesInScene removeObjectForKey:name];
		
        cpSpaceRemoveBody(world, body);
        cpBodyFree(body);
        
        return YES;
	}
	
	return NO;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-(BOOL) removeBody:(cpBody*)body
//{
//    NSLog(@"remove body");
//	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a body with method removeBody if you used the method addSpritesToLayer to load your level. Use method removeCCSprite or removeCCSpriteWithUniqueName."); 
//	
//	if(0 == body)
//		return NO;
//	
//	CCSprite *ccsprite = (CCSprite*)body->data;
//	
//	if(nil == ccsprite)
//		return NO;
//	
//	if([ccsprite usesBatchNode])
//	{
//		NSArray * keys = [ccSpritesInScene allKeysForObject:[NSValue valueWithPointer:body]];
//		
//		CCSpriteBatchNode *batchNode = [ccsprite batchNode];
//		
//		if(nil == batchNode)
//			return NO;
//		
//		if(0 == world)
//			return NO;
//		
//		[batchNode removeChild:ccsprite cleanup:YES];
//		
//		for(NSString* key in keys)
//		{
//			[ccSpritesInScene removeObjectForKey:key];
//		}
//		
//        
////        cpSpaceRemoveBody(world, body);
//  //      cpSpaceRemoveShape(world, );
//        
//        cpBodyDestroy(body);
//     //   cpBodyFree(body);
//	}
//	else 
//	{
//		NSLog(@"This cpBody was not created using addObjectToWorld so it's your responsibility to remove it.");
//		return NO;
//	}
//	
//	return YES;
//}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL) removeAllBodies
{
    NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove all bodies with method removeAllBodies if you used the method addSpritesToLayer to load your level. Use method removeAllCCSprites."); 
	
	NSArray *keys = [ccSpritesInScene allKeys];
	
	BOOL removedAll = YES;
	for(NSString* key in keys)
	{
		removedAll = removedAll == [self removeBodyWithUniqueName:key];
	}
	return removedAll;		
}

-(cpConstraint*) jointWithUniqueName:(NSString*)name
{
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a joint with method removeJointWithUniqueName if you used the method addSpritesToLayer to load your level."); 
	
	
	return (cpConstraint*)[[ccJointsInScene objectForKey:name] pointerValue];
}

-(BOOL) removeJointWithUniqueName:(NSString*)name
{
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a joint with method removeJointWithUniqueName if you used the method addSpritesToLayer to load your level."); 
	
	
	cpConstraint* joint = (cpConstraint*)[[ccJointsInScene objectForKey:name] pointerValue];
	
	if(0 != joint)
	{
		return [self removeJoint:joint];
	}
	
	return NO;
}

-(BOOL) removeAllJoints
{
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove joints with method removeAllJoints if you used the method addSpritesToLayer to load your level."); 
    
	NSArray *keys = [ccJointsInScene allKeys];
	
	BOOL removedAll = YES;
	for(NSString* key in keys)
	{
		removedAll = removedAll == [self removeJointWithUniqueName:key];
	}
	return removedAll;	
}

-(BOOL) removeJoint:(cpConstraint*) joint
{
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a joint with method removeJoint if you used the method addSpritesToLayer to load your level."); 
	
	if(0 == joint)
		return NO;
    
	NSArray * keys = [ccJointsInScene allKeysForObject:[NSValue valueWithPointer:joint]];
	
	if(0 == world)
		return NO;
	
	for(NSString* key in keys)
	{
		[ccJointsInScene removeObjectForKey:key];
	}
    cpSpaceRemoveConstraint(world, joint);
    
	return YES;
}

-(CCSprite*) newSpriteWithUniqueName:(NSString*)uniqueName 
                        gameLayer:(CCLayer*)_gameLayer
{
	for(NSDictionary* dictionary in spriteDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if([[spriteProp objectForKey:@"UniqueName"] isEqualToString:uniqueName])
		{
			CCSprite* ccsprite = [self spriteFromDictionary:spriteProp];
			
			if(nil != ccsprite)
				[_gameLayer addChild:ccsprite];
			
			return ccsprite;
		}
	}
	return nil;
}

-(NSMutableArray*) newBodyWithUniqueName:(NSString*)uniqueName 
                                   world:(cpSpace*)_world
                            gameLayer:(CCLayer*)_gameLayer
{
	for(NSDictionary* dictionary in spriteDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if([[spriteProp objectForKey:@"UniqueName"] isEqualToString:uniqueName])
		{
			CCSprite* ccsprite = [self spriteFromDictionary:spriteProp];	
			
			if(nil == ccsprite)
				return 0;
			
			[_gameLayer addChild:ccsprite];
			
			NSDictionary* physicProp = [dictionary objectForKey:@"PhysicProperties"];
			
			return [self cpBodyFromDictionary:physicProp
							 spriteProperties:spriteProp
										 data:ccsprite 
										world:_world];
		}
	}
	
	return 0;
}

-(NSMutableArray*)spritesWithTag:(LevelHelper_TAG)tag
{
	NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
	
	NSArray *keys = [ccSpritesInScene allKeys];
	for(NSString* key in keys)
	{
		CCSprite* ccSprite = [self spriteWithUniqueName:key];
        
		if(nil != ccSprite && [ccSprite tag] == (int)tag)
		{
			[array addObject:ccSprite];
		}
	}
	
	return array;
}

-(NSMutableArray*) bodiesWithTag:(LevelHelper_TAG)tag
{
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot use method BodiesWithTag if you used the method addSpritesToLayer to load your level."); 
	
	NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
	
	NSArray *keys = [ccSpritesInScene allKeys];
	for(NSString* key in keys)
	{
        cpBody* body = [self bodyWithUniqueName:key];
		CCSprite* ccSprite = (CCSprite*)body->data;
		
		if(nil != ccSprite && [ccSprite tag] == (int)tag)
		{
			[array addObject:[NSValue valueWithPointer:body]];
		}
	}
	
	return array;
}

-(NSMutableArray*)newSpritesWithTag:(LevelHelper_TAG)tag
                       gameLayer:(CCLayer*)_gameLayer
{
	NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
	
	for(NSDictionary* dictionary in spriteDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if((LevelHelper_TAG)[[spriteProp objectForKey:@"Tag"] intValue] == tag)
		{
			CCSprite* ccsprite = [self spriteFromDictionary:spriteProp];
			
			if(nil != ccsprite)
			{
				[array addObject:ccsprite];
				[_gameLayer addChild:ccsprite];
			}
		}
	}
	
	return array;
}

-(NSMutableArray*) newBodiesWithTag:(LevelHelper_TAG)tag 
							  world:(cpSpace*)_world
					   gameLayer:(CCLayer*)_gameLayer
{
	NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
	
	for(NSDictionary* dictionary in spriteDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if((LevelHelper_TAG)[[spriteProp objectForKey:@"Tag"] intValue] == tag)
		{
			CCSprite* ccsprite = [self spriteFromDictionary:spriteProp];
			
			if(nil != ccsprite)
			{
				NSDictionary* physicProp = [dictionary objectForKey:@"PhysicProperties"];
				
				NSValue* v = [NSValue valueWithPointer:[self cpBodyFromDictionary:physicProp
																 spriteProperties:spriteProp
																			 data:ccsprite 
																			world:_world]];
				[array addObject:v];
				
				[_gameLayer addChild:ccsprite];
			}
		}
	}
	return array;
}

-(void) releaseAll
{
	[spriteDictsArray release];
	[jointDictsArray release];
	
	if(addObjectsToWordWasUsed){
		[self removeAllJoints];	
		[self removeAllBodies];
		[self removeAllSprites]; //for no physic sprites
	}
	else {
		[self removeAllSprites];
	}
	[ccSpritesInScene release];
	[ccJointsInScene release];
	[noPhysicSprites release];
	
	
	NSArray *keys = [batchNodes allKeys];
	for(NSString* key in keys)
	{
		NSDictionary* info = [batchNodes objectForKey:key];
		
		CCSpriteBatchNode *v = [info objectForKey:@"CCBatchNode"];
		[gameLayer removeChild:v cleanup:YES];
	}
	[batchNodes release];
}

-(oneway void) release
{
	[self releaseAll];
}
///////////////////////////PRIVATE METHODS//////////////////////////////////////////
-(void) addBatchNodesToLayer:(CCLayer*)_gameLayer
{
	NSArray *keys = [batchNodes allKeys];
	int tag = 0;
	for(NSString* key in keys)
	{
		NSDictionary* info = [batchNodes objectForKey:key];
		
		CCSpriteBatchNode *v = [info objectForKey:@"CCBatchNode"];
		int z = [[info objectForKey:@"OrderZ"] intValue];
		[_gameLayer addChild:v z:z tag:tag];
		tag++;
	}
}

-(riActor*) spriteFromDictionary:(NSDictionary*)spriteProp
{
	riActor *actor = [riActor spriteWithFile:[spriteProp objectForKey:@"Image"] 
											 rect:riRectFromString([spriteProp objectForKey:@"UV"])];
	
	[self setSpriteProperties:actor spriteProperties:spriteProp];
	
	return actor;
}

-(riActor*) spriteWithBatchFromDictionary:(NSDictionary*)spriteProp 
                                 batchNode:(CCSpriteBatchNode*)batch
{
	riActor *actor = [riActor spriteWithBatchNode:batch 
												  rect:riRectFromString([spriteProp objectForKey:@"UV"])];
	
	[self setSpriteProperties:actor spriteProperties:spriteProp];
	
	return actor;	
}

-(void) setSpriteProperties:(riActor*)actor
           spriteProperties:(NSDictionary*)spriteProp
{
	//convert position from LH to Cocos2d coordinates
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	CGPoint position = riPointFromString([spriteProp objectForKey:@"Position"]);
	position.y = winSize.height - position.y;
	
	[actor setPosition:position];
	[actor setRotation:[[spriteProp objectForKey:@"Angle"] floatValue]];
	[actor setOpacity:255*[[spriteProp objectForKey:@"Opacity"] floatValue]];
	CGRect color = riRectFromString([spriteProp objectForKey:@"Color"]);
	[actor setColor:ccc3(255*color.origin.x, 255*color.origin.y, 255*color.size.width)];
	CGPoint scale = riPointFromString([spriteProp objectForKey:@"Scale"]);
	[actor setScaleX:scale.x];
	[actor setScaleY:scale.y];
	[actor setTag:[[spriteProp objectForKey:@"Tag"] intValue]];
}

-(void) setShapePropertiesFromDictionary:(NSDictionary*)spritePhysic 
                                   shape:(cpShape*)shapeDef
{
	//shapeDef->density = [[spritePhysic objectForKey:@"Density"] floatValue];
	shapeDef->u = [[spritePhysic objectForKey:@"Friction"] floatValue];
	shapeDef->e = [[spritePhysic objectForKey:@"Restitution"] floatValue];
	shapeDef->sensor = [[spritePhysic objectForKey:@"IsSenzor"] boolValue];
	
    //	shapeDef->filter.categoryBits = [[spritePhysic objectForKey:@"Category"] intValue];
	shapeDef->layers = [[spritePhysic objectForKey:@"Mask"] intValue];
	shapeDef->group = [[spritePhysic objectForKey:@"Group"] intValue];	
}

//returns NSMutableArray with NSValue with cpShape pointers
-(NSMutableArray*) cpBodyFromDictionary:(NSDictionary*)spritePhysic
                       spriteProperties:(NSDictionary*)spriteProp
                                   data:(riActor*)actor 
                                  world:(cpSpace*)space
{
	cpBody *body = nil;
    cpShape *shape = nil;

    NSMutableArray* arrayOfShapes = [[NSMutableArray alloc] init];
    
	BodyType bodyType = [[spritePhysic objectForKey:@"Type"] intValue];

    float mass = [[spritePhysic objectForKey:@"Density"] floatValue];
	CGPoint position = ccp([actor position].x, [actor position].y);
    NSArray* fixtures = [spritePhysic objectForKey:@"ShapeFixtures"];
	CGPoint scale = riPointFromString([spriteProp objectForKey:@"Scale"]); 
	CGPoint size = riPointFromString([spriteProp objectForKey:@"Size"]);

    if(bodyType == BODY_NOPHYSIC) 
		bodyType = BODY_DYNAMIC;

    
	if(fixtures == nil || [fixtures count] == 0 || [[fixtures objectAtIndex:0] count] == 0)
	{
		
		if([[spritePhysic objectForKey:@"IsCircle"] boolValue])
		{
            //NSLog(@"Circle");
			float innerDiameter = 0;
			float outterDiameter = size.x/2*scale.x;
            
            if(bodyType == BODY_STATIC)
                body = cpBodyNewStatic();
            else
                body = cpBodyNew(mass, cpMomentForCircle(mass, innerDiameter, outterDiameter, cpvzero));

            body->p = position;
            cpBodySetAngle(body, DEGREES_TO_RADIANS(-1*[[spriteProp objectForKey:@"Angle"] floatValue]));   
			float radius = size.x*scale.x/2;
            
			shape = cpCircleShapeNew(body, radius, cpvzero);
            actor.shape = shape;
		}
		else
		{	
            float width = size.x*scale.x;
			float height = size.y*scale.y;
            
            //NSLog(@"Box");
            if(bodyType == BODY_STATIC)
                body = cpBodyNewStatic();
            else
                body = cpBodyNew(mass, cpMomentForBox(mass, width, height));
            
            body->p = position;
            cpBodySetAngle(body, DEGREES_TO_RADIANS(-1*[[spriteProp objectForKey:@"Angle"] floatValue]));
            
            shape = cpBoxShapeNew(body, width, height);
            actor.shape = shape;
            
		}
		[self setShapePropertiesFromDictionary:spritePhysic shape:shape];
        
        [arrayOfShapes addObject:[NSValue valueWithPointer:shape]];
        
    }
	else
	{
        float width = size.x*scale.x;
        float height = size.y*scale.y;
        body = cpBodyNew(mass, cpMomentForBox(mass, width, height));
        
        body->p = position;
        cpBodySetAngle(body, DEGREES_TO_RADIANS(-1*[[spriteProp objectForKey:@"Angle"] floatValue]));
        
        //IMPORTENT:, because of using spaceManager to manage space. ONLY one fixture supported.
        NSLog(@"TOTAL %d fixtures using...",[fixtures count]);
//        NSAssert([fixtures count] <= 1, @"More than one fixtures");
		for(NSArray* curFixture in fixtures)
		{
			int size = (int)[curFixture count];
            CGPoint *verts = malloc(size*sizeof(CGPoint));
			int i = 0;
            for(int p = [curFixture count] -1; p > -1 ; --p)
			{
                NSString* pointStr = [curFixture objectAtIndex:p];
				CGPoint point = riPointFromString(pointStr);
                verts[i] = ccp(point.x*(scale.x), 
                               point.y*(scale.y));
				++i;
			}
            
            shape = cpPolyShapeNew(body, size, verts, CGPointZero);
            [self setShapePropertiesFromDictionary:spritePhysic shape:shape];
            
            [arrayOfShapes addObject:[NSValue valueWithPointer:shape]];
            
            actor.shape = shape;
            
            free( verts);
		}
	}

	return arrayOfShapes;
	
}

-(NSValue*) jointFromDictionary:(NSDictionary*)joint world:(cpSpace*)_world
{
    
	if(nil == joint)
		return 0;
	
	if(_world == 0)
		return 0;
	
    cpBody* bodyA  = 0;
    NSMutableArray* bodyAArray = [ccSpritesInScene objectForKey:[joint objectForKey:@"ObjectA"]];
    if([bodyAArray count] > 0)
    {
        cpShape* shape = (cpShape*)[[bodyAArray objectAtIndex:0] pointerValue];
        bodyA = (cpBody*)shape->body;
    }
    
    cpBody* bodyB  = 0;
    NSMutableArray* bodyBArray = [ccSpritesInScene objectForKey:[joint objectForKey:@"ObjectB"]];
    if([bodyAArray count] > 0)
    {
        cpShape* shape = (cpShape*)[[bodyBArray objectAtIndex:0] pointerValue];
        bodyB = (cpBody*)shape->body;
    }
    
    //	cpBody* bodyA = (cpBody*)[[ccSpritesInScene objectForKey:[joint objectForKey:@"ObjectA"]] pointerValue];
    //	cpBody* bodyB = (cpBody*)[[ccSpritesInScene objectForKey:[joint objectForKey:@"ObjectB"]] pointerValue];
	
	CGPoint anchorA = riPointFromString([joint objectForKey:@"AnchorA"]);
	CGPoint anchorB = riPointFromString([joint objectForKey:@"AnchorB"]);
    //	BOOL collideConnected = [[joint objectForKey:@"CollideConnected"] BOOLValue];
	
	CGPoint posA, posB;
	
	if(![[joint objectForKey:@"CenterOfMass"] boolValue]){
		posA = ccp(anchorA.x, anchorA.y);
		posB = ccp(anchorB.x, anchorB.y);
	}
	else {		
		posA = ccp(0.0f, 0.0f);
		posB = ccp(0.0f, 0.0f);					
	}
	
	if(0 != bodyA && 0 != bodyB)
    {
        cpConstraint* constraint = nil;
        
		switch ([[joint objectForKey:@"Type"] intValue])
        {
			case LH_DISTANCE_JOINT:
                constraint = cpPinJointNew(bodyA, bodyB, posA, posB);
				break;
				
			case LH_REVOLUTE_JOINT:
            {
                if([[joint objectForKey:@"EnableMotor"] boolValue])
                {
                    NSLog(@"motor");
                    constraint = cpSimpleMotorNew(bodyA, bodyB, 1.0f);
                }
            }
				break;
				
			case LH_PRISMATIC_JOINT:
				break;
				
			case LH_PULLEY_JOINT:
				break;
				
			case LH_GEAR_JOINT:
				break;
				
			case LH_LINE_JOINT:
				break;
				
			case LH_WELD_JOINT:
				break;
				
			default:
				NSLog(@"Unknown joint type in LevelHelper file.");
				break;
        }

        if(constraint != nil)
            return [NSValue valueWithPointer:constraint];
        else
            return nil;

    }
	return nil;
}

                                    /*LOAD LEVEL PLIST FILE TO lhSprites / lhJoints / batchNodes / wb */

-(void)loadLevelHelperSceneFile:(NSString*)levelFile inDirectory:(NSString*)subfolder imgSubfolder:(NSString*)imgFolder
{
	NSString *path = [[NSBundle mainBundle] pathForResource:levelFile ofType:@"plist" inDirectory:subfolder]; 
	
	NSAssert(nil!=path, @"Invalid level file. Please add the LevelHelper scene file to Resource folder. Please do not add extension in the given string.");
	
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
	
	//LOAD WORLD BOUNDARIES
	if(nil != [dictionary objectForKey:@"WorldBoundaries"])
	{
		wb = riRectFromString([dictionary objectForKey:@"WorldBoundaries"]);
	}
	
	//LOAD SPRITES
    spriteDictsArray = [[NSArray alloc] initWithArray:[dictionary objectForKey:@"SPRITES_INFO"]];
	
	//LOAD BATCH IMAGES
	NSArray* batchImages = [dictionary objectForKey:@"LoadedImages"];
	for(NSDictionary* imageInfo in batchImages)
	{
		NSMutableDictionary* batchInfo = [[NSMutableDictionary alloc] init];
		
		CCSpriteBatchNode *batchNode = [CCSpriteBatchNode batchNodeWithFile:[imageInfo objectForKey:@"Image"]
															   capacity:BATCH_NODE_CAPACITY];	
        
		[batchInfo setObject:batchNode forKey:@"CCBatchNode"];
		[batchInfo setObject:[imageInfo objectForKey:@"OrderZ"] forKey:@"OrderZ"];
		
		
		[batchNodes setObject:batchInfo forKey:[imageInfo objectForKey:@"Image"]];
		[batchInfo release];
	}
	
	//LOAD JOINTS
	jointDictsArray = [[NSArray alloc] initWithArray:[dictionary objectForKey:@"JOINTS_INFO"]];
}

@end