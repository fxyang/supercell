//
//  riLevelLoader.m
//  supercell
//
//  Created by Feixue Yang on 12-02-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "riLevelLoader.h"
#import "riActor.h"
#import "GameLayer.h"
#import "riCCAnimationCacheExtensions.h"


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

-(void) addBatchNodesToLayer:(GameLayer*)_gameLayer;
-(riActor *) addActorWithDictionary:(NSDictionary *) dictionary;

-(cpConstraint *) addJointWithDictionary:(NSDictionary *) dictionary;
-(riActor*) spriteWithDictionary:(NSDictionary*)spriteProp;

-(void) setSpritePropertiesWithDictionary:(NSDictionary*)spriteProp forActor:(riActor *)actor;
-(void) setActorPropertiesWithDictionary:(NSDictionary*)actorProp forActor:(riActor*)actor;
-(void) setShapePropertiesWithDictionary:(NSDictionary*)spritePhysic forShape:(cpShape*)shapeDef;

-(NSMutableArray*) shapesWithDictionary:(NSDictionary*)spritePhysic
                       spriteProperties:(NSDictionary*)spriteProp
                                   data:(riActor*)actor;

-(NSValue*) jointWithDictionary:(NSDictionary*)dictionary;

-(void)loadLevelFile:(NSString*)levelFile 
					inDirectory:(NSString*)subfolder
				   imgSubfolder:(NSString*)imgFolder;
@end

@implementation riLevelLoader

@synthesize space = _space;
@synthesize gameLayer = _gameLayer;
@synthesize spaceManager = _spaceManager;
//@synthesize tiledMap = _tiledMap;

#pragma mark Load Level -- FramesCache -- AnimationCache from plist files (Private)


/*LOAD LEVEL PLIST FILE TO Actors / Joints / BatchNodes / wb */

-(void)loadLevelFile:(NSString*)levelFile inDirectory:(NSString*)subfolder imgSubfolder:(NSString*)imgFolder
{
	NSString *path = [[NSBundle mainBundle] pathForResource:levelFile ofType:@"plist" inDirectory:subfolder]; 
	
	NSAssert(nil!=path, @"Invalid level file. Please add the riLevelLoader scene file to Resource folder. Please do not add extension in the given string.");
	
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	
	//LOAD WORLD BOUNDARIES
	if(nil != [dictionary objectForKey:@"WorldBoundaries"])
		wb = riRectFromString([dictionary objectForKey:@"WorldBoundaries"]);
	
	//LOAD SPRITES
    actorDictsArray = [[NSMutableArray alloc] initWithArray:[dictionary objectForKey:@"SPRITES_INFO"]];
	
    
    //LOAD TMXMAP
    NSArray* tmxInfoArray = [dictionary objectForKey:@"TiledMap"];
    DataModel* dataModel = [DataModel sharedDataModel];

    for(NSDictionary * tmxInfo in tmxInfoArray){
        
        NSString * mapFile = [tmxInfo objectForKey:@"MapFile"];
        NSNumber * z = [NSNumber numberWithInt:[[tmxInfo objectForKey:@"OrderZ"] intValue]];
        
        NSString * ratio = [tmxInfo objectForKey:@"Ratio"];
        ratio = ratio == nil ? @"{1,1}" : ratio;
        
        NSString * offset = [tmxInfo objectForKey:@"Offset"];
        offset = offset == nil ? @"{0,0}" : ratio;
        
        if(mapFile != nil && ![mapFile isEqualToString:@""] ){
            CCTMXTiledMap * tiledMap = [CCTMXTiledMap tiledMapWithTMXFile:mapFile];
            NSMutableDictionary * tiledMapInfo = [NSMutableDictionary dictionaryWithCapacity:5];
            [tiledMapInfo setObject:tiledMap forKey:@"TiledMap"];
            [tiledMapInfo setObject:ratio forKey:@"Ratio"];
            [tiledMapInfo setObject:offset forKey:@"Offset"];
            [tiledMapInfo setObject:z forKey:@"OrderZ"];
            int n = [dataModel.tiledMaps count];
            if(n==0)
                [dataModel.tiledMaps addObject:tiledMapInfo];
            else
                for(int i = 0;i<n;i++){
                    NSDictionary * tm = [dataModel.tiledMaps objectAtIndex:i];
                    if(i < n-1 && [z intValue] < [[tm objectForKey:@"OrderZ"] intValue]){
                        [dataModel.tiledMaps insertObject:tiledMapInfo atIndex:i];
                        break;
                    }
                    else if(i == n-1){
                        [dataModel.tiledMaps addObject:tiledMapInfo];
                        break;
                    }
                }
            
            CCTMXObjectGroup *waypointsGroup = [tiledMap objectGroupNamed:@"Waypoints"];
            riTiledMapWaypoint *wp = nil;
            NSMutableDictionary *wayDict;
            
            NSMutableArray * wpArray = waypointsGroup.objects;
            if (wpArray != nil){
                tiledMap.visible = NO;
                int n = [wpArray count];
                for(int i = 0;i < n; i++){
                    wayDict = [wpArray objectAtIndex:i];
                    wp = [riTiledMapWaypoint WaypointWithInfoDictionary:wayDict];
                    [dataModel.waypoints setObject:wp forKey:[wp waypointName]];
                }
                wp = nil;
            }
            
            
            CCTMXObjectGroup *controlPointsGroup = [tiledMap objectGroupNamed:@"ControlPoints"];
            riTiledMapWaypoint *cp = nil;
            NSMutableDictionary *controlDict;
            
            NSMutableArray * cpArray = controlPointsGroup.objects;
            if (cpArray != nil){
                int n = [cpArray count];
                for(int i = 0;i < n; i++){
                    controlDict = [cpArray objectAtIndex:i];
                    cp = [riTiledMapWaypoint WaypointWithInfoDictionary:controlDict];
                    [dataModel.controlPoints setObject:cp forKey:[cp waypointName]];
                }
                cp = nil;
            }
            
            
        }
    }
    
	//LOAD BATCH IMAGES
	NSArray* batchImages = [dictionary objectForKey:@"LoadedImages"];
	for(NSMutableDictionary* imageInfo in batchImages)
	{
		NSMutableDictionary* batchInfo = [[NSMutableDictionary alloc] init];
        CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:[imageInfo objectForKey:@"Image"]];
        CCSpriteBatchNode *batchNode = [CCSpriteBatchNode batchNodeWithTexture:texture capacity:BATCH_NODE_CAPACITY];
		[batchInfo setObject:batchNode forKey:@"CCBatchNode"];
		[batchInfo setObject:[imageInfo objectForKey:@"OrderZ"] forKey:@"OrderZ"];
		[batchNodes setObject:batchInfo forKey:[imageInfo objectForKey:@"Image"]];
		[batchInfo release];

         NSString * framePlist = [imageInfo objectForKey:@"Frame"];
         NSString * animationPlist = [imageInfo objectForKey:@"Animation"];
         
         if(framePlist != nil && ![framePlist isEqualToString:@""]){
             [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:framePlist];
         }
         if(animationPlist != nil && ![animationPlist isEqualToString:@""]){
             [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:animationPlist];
         }
	}
	
	//LOAD JOINTS
	jointDictsArray = [[NSMutableArray alloc] initWithArray:[dictionary objectForKey:@"JOINTS_INFO"]];
}


#pragma mark Init LevelLoad and Actors -- Add to GameLayer and cpSpace

-(void) initObjects
{
//    _tiledMap = nil;
	batchNodes = [[NSMutableDictionary alloc] init];
    actorsInStage = [[NSMutableArray alloc] init];
	shapesInStage = [[NSMutableDictionary alloc] init];
	actorsInStageNoPhysics = [[NSMutableDictionary alloc] init];
	jointsInStage = [[NSMutableDictionary alloc] init];

	
	addSpritesToLayerWasUsed = NO;
	addObjectsToWordWasUsed = NO;
    levelLoaded = NO;
	
}

-(id) initWithContentOfFile:(NSString*)levelFile
{
	NSAssert(nil!=levelFile, @"Invalid file given to riLevelLoader");
	
	if(!(self = [super init]))
	{
		NSLog(@"riLevelLoader ****ERROR**** : [super init] failer ***");
		return self;
	}
	
	[self initObjects];
	[self loadLevelFile:levelFile inDirectory:@"" imgSubfolder:@""];
	
	return self;
}

-(id) initWithContentOfFile:(NSString*)levelFile 
			 levelSubfolder:(NSString*)levelFolder 
			imagesSubfolder:(NSString*)imgFolder
{
	NSAssert(nil!=levelFile, @"Invalid file given to riLevelLoader");
	
	if(!(self = [super init]))
	{
		NSLog(@"riLevelLoader ****ERROR**** : [super init] failer ***");
		return self;
	}
	
	[self initObjects];
	
	[self loadLevelFile:levelFile inDirectory:levelFolder imgSubfolder:imgFolder];
	
	return self;
	
}

+(id)riLevelLoaderWithContentOfFile:(NSString*)levelFile
{
	return [[[self alloc] initWithContentOfFile:levelFile] autorelease];
}

+(id) riLevelLoaderWithContentOfFile:(NSString*)levelFile 
						  levelSubfolder:(NSString*)levelFolder 
						 imagesSubfolder:(NSString*)imgFolder
{
	return [[[self alloc] initWithContentOfFile:levelFile 
								 levelSubfolder:levelFolder 
								imagesSubfolder:imgFolder] autorelease];
}


-(void) step
{
	for(NSMutableDictionary* dictionary in actorDictsArray)
	{
        int countType = [[dictionary objectForKey:@"CountType"] intValue];
        
        NSArray * relActors = [dictionary objectForKey:@"RelatedActors"];
        BOOL relatedActorYes = YES;
        for(NSString* relActor in relActors){
            relatedActorYes = NO;
            for(riActor* eachActor in _gameLayer.actorsArray){
                if([relActor isEqualToString:eachActor.name]){
                    relatedActorYes = YES;
                    break;
                }
            }
            if(relatedActorYes)
                break;
        }

        if(relatedActorYes){
            if(countType == kCountSingle && !levelLoaded)
                [self addActorWithDictionary:dictionary];
            else
            {
                int count = [[dictionary objectForKey:@"Count"] intValue];
                ccTime birthTime = [[dictionary objectForKey:@"BirthTime"] floatValue];
                CGPoint birthIntervalRange = riPointFromString([dictionary objectForKey:@"BirthIntervalRange"]);
                float birthInterval = 0;
                
                //We use CGPoint represent a random time range
                if(birthIntervalRange.x != birthIntervalRange.y && birthIntervalRange.x > 0 && birthIntervalRange.y > 0)
                    birthInterval = (arc4random() % (int)(birthIntervalRange.y - birthIntervalRange.x)) + birthIntervalRange.x; 
                
                if(birthIntervalRange.x == birthIntervalRange.y && birthIntervalRange.x > 0 && birthIntervalRange.y > 0)
                    birthInterval = birthIntervalRange.x;
                
                if (birthTime <= _gameLayer.gameTime){
                    birthTime = birthTime + birthInterval;
                    [dictionary setValue:[NSNumber numberWithFloat:birthTime] forKey:@"BirthTime"];

                    if(countType == kCountInfinity){

                        [self addActorWithDictionary:dictionary];
                        
                    } else if (count >= 1){
                        count--;
                        [dictionary setValue:[NSNumber numberWithInt:count] forKey:@"Count"];
                        [self addActorWithDictionary:dictionary];
                    }
                }
            }
            
        }
    }
        
	for(NSMutableDictionary* dictionary in jointDictsArray)
	{
        int countType = [[dictionary objectForKey:@"CountType"] intValue];
        
        NSArray * relActors = [dictionary objectForKey:@"RelatedActors"];
        BOOL relatedActorYes = YES;
        for(NSString* relActor in relActors){
            relatedActorYes = NO;
            for(riActor* eachActor in _gameLayer.actorsArray){
                if([relActor isEqualToString:eachActor.name]){
                    relatedActorYes = YES;
                    break;
                }
            }
            if(relatedActorYes)
                break;
        }
        
        if(relatedActorYes){
            if(countType == kCountSingle && !levelLoaded)
                [self addJointWithDictionary:dictionary];
            else
            {
                int count = [[dictionary objectForKey:@"Count"] intValue];
                ccTime birthTime = [[dictionary objectForKey:@"BirthTime"] floatValue];
                CGPoint birthIntervalRange = riPointFromString([dictionary objectForKey:@"BirthIntervalRange"]);
                float birthInterval = 0;
                
                //We use CGPoint represent a random time range
                if(birthIntervalRange.x != birthIntervalRange.y && birthIntervalRange.x > 0 && birthIntervalRange.y > 0)
                    birthInterval = (arc4random() % (int)(birthIntervalRange.y - birthIntervalRange.x)) + birthIntervalRange.x; 
                
                if(birthIntervalRange.x == birthIntervalRange.y && birthIntervalRange.x > 0 && birthIntervalRange.y > 0)
                    birthInterval = birthIntervalRange.x;
                
                if (birthTime <= _gameLayer.gameTime){
                    birthTime = birthTime + birthInterval;
                    [dictionary setValue:[NSNumber numberWithFloat:birthTime] forKey:@"BirthTime"];
                    
                    if(countType == kCountInfinity){
                        
                        [self addJointWithDictionary:dictionary];
                        
                    } else if (count >= 1){
                        count--;
                        [dictionary setValue:[NSNumber numberWithInt:count] forKey:@"Count"];
                        [self addJointWithDictionary:dictionary];
                    }
                }
            }
            
        }
    }


}

-(void) addEverythingToSpace:(cpSpace*)world_ gameLayer:(GameLayer*)gameLayer_
{
	
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You can't use method addObjectsToWorld because you already used addSpritesToLayer. Only one of the two can be used."); 
	NSAssert(addObjectsToWordWasUsed!=YES, @"You can't use method addObjectsToWorld again. You can only use it once. Create a new LevelHelperLoader object if you want to load the level again."); 
	
	addObjectsToWordWasUsed = YES;
	
    //ADD batchNodes To GameLyer
	[self addBatchNodesToLayer:_gameLayer];
	
	[self step];
    
    levelLoaded = YES;
    
}

        /* ONLY Add Sprites (NO Bodies AND Shapes AND Joints)to GameLayer*/

-(void) addSpritesToLayer:(GameLayer*)gameLayer_
{	
	NSAssert(addObjectsToWordWasUsed!=YES, @"You can't use method addSpritesToLayer because you already used addObjectToWorld. Only one of the two can be used."); 
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You can't use method addSpritesToLayer again. You can only use it once. Create a new LevelHelperLoader object if you want to load the level again."); 
	
	addSpritesToLayerWasUsed = YES;
    
	_gameLayer = gameLayer_;
    _space = nil;
	
	[self addBatchNodesToLayer:gameLayer_];
	
	for(NSDictionary* dictionary in actorDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		//find the coresponding batch node for this sprite
		NSDictionary* batchInfo = [batchNodes objectForKey:[spriteProp objectForKey:@"Image"]];
		CCSpriteBatchNode *batch = [batchInfo objectForKey:@"CCBatchNode"];
		
		if(nil != batch)
		{
			riActor* actor = [riActor spriteWithBatchNode:batch 
                                    rect:riRectFromString([spriteProp objectForKey:@"UV"])];
            [self setSpritePropertiesWithDictionary:spriteProp forActor:actor];
            
			if(nil != actor)
			{
				[batch addChild:actor];
				[shapesInStage setObject:actor forKey:[spriteProp objectForKey:@"Name"]];
			}
		}
	}
}

-(BOOL) hasSpaceBoundaries
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

-(void) createSpaceBoundaries:(cpSpace*)space
{
	NSAssert(wb.size.width != 0, @"You can't use method createwb because you have not defined any world boundaries inside LevelHelper."); 
    
    cpBody *staticBody = cpBodyNew(INFINITY, INFINITY);
    cpShape *shape;
    
    CGSize ss = [CCDirector sharedDirector].winSize;
    
    // bottom
    shape = cpSegmentShapeNew(staticBody, ccp(wb.origin.x, ss.height - (wb.origin.y + wb.size.height)), 
                              ccp(wb.origin.x+ wb.size.width, ss.height - (wb.origin.y + wb.size.height)), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f; shape->collision_type = 0;
    cpSpaceAddStaticShape(space, shape);
    
    // top
    shape = cpSegmentShapeNew(staticBody, ccp(wb.origin.x,ss.height - wb.origin.y), 
                              ccp((wb.origin.x + wb.size.width),ss.height - wb.origin.y), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f; shape->collision_type = 0;
    cpSpaceAddStaticShape(space, shape);
    
    // left
    shape = cpSegmentShapeNew(staticBody, ccp(wb.origin.x, ss.height - (wb.origin.y + wb.size.height)), 
                              ccp(wb.origin.x, ss.height - wb.origin.y), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f; shape->collision_type = 0;
    cpSpaceAddStaticShape(space, shape);
    
    // right
    shape = cpSegmentShapeNew(staticBody, ccp(wb.origin.x + wb.size.width,ss.height - (wb.origin.y + wb.size.height)), 
                              ccp(wb.origin.x + wb.size.width,ss.height - wb.origin.y), 0.0f);
    shape->e = 1.0f; shape->u = 1.0f; shape->collision_type = 0;
    cpSpaceAddStaticShape(space, shape);
    
}

-(void) increaseActorWithName:(NSString *)name count:(int)incremental delay:(float)delay{
    
    for(NSDictionary* dictionary in actorDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if([[spriteProp objectForKey:@"Name"] isEqualToString:name])
		{
			int count = [[dictionary objectForKey:@"Count"] intValue];
            count = count + incremental;
            [dictionary setValue:[NSNumber numberWithInt:count] forKey:@"Count"];
            float bt = [[dictionary objectForKey:@"BirthTime"] floatValue];
            
            //Reset BirthTime...
            if((_gameLayer.gameTime - bt) > delay)
                [dictionary setValue:[NSNumber numberWithFloat:_gameLayer.gameTime + delay] forKey:@"BirthTime"];
		}
	}
}

-(riActor *) addActorWithName:(NSString *)name{
	for(NSDictionary* dictionary in actorDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if([[spriteProp objectForKey:@"Name"] isEqualToString:name])
		{
			riActor* actor = [self addActorWithDictionary:dictionary];
			
			return actor;
		}
	}
	return nil;    
}

-(BOOL) removeActor:(riActor*)actor cleanupShape:(BOOL)clean{
    NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a body with method removeActor if you used the method addSpritesToLayer to load your level. Use method removeCCSprite or removeCCSpriteWithName."); 
	
	if(actor != nil)
	{
        if(clean && actor.shape != nil){
            [shapesInStage removeObjectForKey:[actor name]];
            [_spaceManager removeAndFreeShape:actor.shape];
            [_spaceManager rehashStaticShapes];
        }
        
        [actorsInStage removeObject:actor];
        [[_gameLayer actorsArray] removeObject:actor];


        CCSpriteBatchNode *batchNode = [actor batchNode];
		if(nil != batchNode)
            [batchNode removeChild:actor cleanup:YES];

        return YES;
	}
	return NO;
}

-(BOOL) removeShapeOfActor:(riActor*)actor{
    NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a body with method removeActor if you used the method addSpritesToLayer to load your level. Use method removeCCSprite or removeCCSpriteWithName."); 
	
	if(actor != nil)
	{
        [shapesInStage removeObjectForKey:[actor name]];
        [_spaceManager removeAndFreeShape:actor.shape];
        [_spaceManager rehashStaticShapes];
        
        return YES;
	}
	return NO;
}


#pragma mark Setup BatchNodes -- Init Actors from dictionary

-(void) addBatchNodesToLayer:(GameLayer*)gameLayer_
{
	NSArray *keys = [batchNodes allKeys];
	int tag = kBatchNodeTag;
	for(NSString* key in keys)
	{
		NSDictionary* info = [batchNodes objectForKey:key];
		
		CCSpriteBatchNode *v = [info objectForKey:@"CCBatchNode"];
		int z = [[info objectForKey:@"OrderZ"] intValue];
		[gameLayer_ addChild:v z:z tag:tag];
		tag++;
	}
}



-(riActor *) addActorWithDictionary:(NSDictionary *) dictionary {
    
    riActor * actor = [self actorWithDictionary:dictionary];
    
    if(actor != nil){
        NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
        
        //Show Actor In CCSpriteBatchNode
        NSDictionary* batchNodeDict = [batchNodes objectForKey:[spriteProp objectForKey:@"Image"]];
        CCSpriteBatchNode * batchNode = [batchNodeDict objectForKey:@"CCBatchNode"];
        [batchNode addChild:actor z:[[spriteProp objectForKey:@"OrderZ"] intValue]]; 
        
        //Add Actor To Managing Array
        [[_gameLayer actorsArray] addObject:actor];
        
        [actor perform];
        
        //Show Body and Shape In Space
        if(actor.body != nil && actor.shape != nil){ 
            [_spaceManager addBody:actor.body];
            [_spaceManager addShape:actor.shape];
        }
    }
    return actor;
}

-(cpConstraint *) addJointWithDictionary:(NSDictionary *) dictionary {
    NSValue* joint = [self jointWithDictionary:dictionary];
    if(nil != joint){
        cpConstraint * constraint = (cpConstraint *)[joint pointerValue];
        cpConstraintNode * constraintNode = [cpConstraintNode nodeWithConstraint:constraint];
        
        [jointsInStage setObject:joint forKey:[dictionary objectForKey:@"Name"]];
        
        //Show Joint and Joint Node In Space
        if(_space != nil && constraint != nil){
            cpSpaceAddConstraint( _space , constraint); 
            [_gameLayer addChild:constraintNode z:11]; 
        }
        return constraint;
    }
    return nil;
}


-(riActor *) actorWithDictionary:(NSDictionary *) dictionary {
    riActor * actor = nil;
    
    NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
    NSDictionary* physicProp = [dictionary objectForKey:@"PhysicProperties"];
    NSDictionary* actorProp = [dictionary objectForKey:@"ActorProperties"];
    
    actor = [self spriteWithDictionary:spriteProp];
    
    if(actor != nil){  
        //Create Actor and ADD to batchNode
        [self setActorPropertiesWithDictionary:actorProp forActor:actor];
        int countType = [[dictionary objectForKey:@"CountType"] intValue];
        [actor setCountType:countType];
        
        actor.body = nil;
        actor.shape = nil;
        
        //Create Actor's Body and Shape and Add to actorsInStage
        //Add no physics actor to actorsInStageNoPhysics
        NSString* name = [spriteProp objectForKey:@"Name"];
        int bodyType = [[physicProp objectForKey:@"BodyType"] intValue];
        if(bodyType != kBodyNoPhysic){
            NSMutableArray* shapes = [self shapesWithDictionary:physicProp spriteProperties:spriteProp data:actor];
            [shapesInStage setObject:shapes forKey:name];
			[actorsInStage addObject:actor];
        }else 
            [actorsInStageNoPhysics setObject:actor forKey:name];
        
    }
    return actor;
}

-(riActor*) actorWithName:(NSString*)name
{
	for(NSDictionary* dictionary in actorDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if([[spriteProp objectForKey:@"Name"] isEqualToString:name])
		{
			riActor* actor = [self actorWithDictionary:dictionary];
			
			return actor;
		}
	}
	return nil;
}

-(riActor*) actorWithName:(NSString*)name 
                gameLayer:(GameLayer*)gameLayer_
{
	for(NSDictionary* dictionary in actorDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if([[spriteProp objectForKey:@"Name"] isEqualToString:name])
		{
			riActor* actor = [self spriteWithDictionary:spriteProp];
            int countType = [[dictionary objectForKey:@"CountType"] intValue];
            [actor setCountType:countType];
            
			if(nil != actor)
				[_gameLayer addChild:actor];
			
			return actor;
		}
	}
	return nil;
}


-(riActor*) spriteWithDictionary:(NSDictionary*)spriteProp {
    
    riActor * actor;

    //find the coresponding batch node for this sprite
    NSDictionary* batchNodeDict = [batchNodes objectForKey:[spriteProp objectForKey:@"Image"]];
    CCSpriteBatchNode * batchNode = [batchNodeDict objectForKey:@"CCBatchNode"];
    
    if(nil != batchNode){        
        NSString* frame = [spriteProp objectForKey:@"Frame"];
        
        if(frame != nil && ![frame isEqualToString:@""])
            actor = [riActor spriteWithSpriteFrameName:frame];
        else
            actor = [riActor spriteWithBatchNode:batchNode rect:riRectFromString([spriteProp objectForKey:@"UV"])];
        
    }else
    	actor = [riActor spriteWithFile:[spriteProp objectForKey:@"Image"] 
                                   rect:riRectFromString([spriteProp objectForKey:@"UV"])];

    [self setSpritePropertiesWithDictionary:spriteProp forActor:actor];

	return actor;
}


//returns NSMutableArray with NSValue with cpShape pointers
-(NSMutableArray*) shapesWithDictionary:(NSDictionary*)spritePhysic
                       spriteProperties:(NSDictionary*)spriteProp
                                   data:(riActor*)actor 
{
	cpBody *body = nil;
    cpShape *shape = nil;
    
    NSMutableArray* arrayOfShapes = [[NSMutableArray alloc] init];
    
	BodyType bodyType = [[spritePhysic objectForKey:@"BodyType"] intValue];
    
    float mass = [[spritePhysic objectForKey:@"Mass"] floatValue];
	CGPoint position = ccp([actor position].x, [actor position].y);
    NSArray* fixtures = [spritePhysic objectForKey:@"ShapeFixtures"];
	CGPoint scale = riPointFromString([spriteProp objectForKey:@"Scale"]); 
	CGPoint size = riPointFromString([spriteProp objectForKey:@"Size"]);
    
    actor.bodyType = bodyType;
    
    if(bodyType == kBodyNoPhysic || bodyType == kBodyKinematic) 
		bodyType = kBodyStatic;
    
    
	if(fixtures == nil || [fixtures count] == 0 || [[fixtures objectAtIndex:0] count] == 0){
		
		if([[spritePhysic objectForKey:@"IsCircle"] boolValue]){
			float innerDiameter = 0;
			float outterDiameter = size.x/2*scale.x;
            
            if(bodyType == kBodyStatic)
                body = cpBodyNewStatic();
            else
                body = cpBodyNew(mass, cpMomentForCircle(mass, innerDiameter, outterDiameter, cpvzero));
            
            body->p = position;
            cpBodySetAngle(body, DEGREES_TO_RADIANS(-1*[[spriteProp objectForKey:@"Angle"] floatValue]));   
			float radius = size.x*scale.x/2;
            
			shape = cpCircleShapeNew(body, radius, cpvzero);
            actor.shape = shape;
		}
		else{	
            float width = size.x*scale.x;
			float height = size.y*scale.y;
            
            if(bodyType == kBodyStatic)
                body = cpBodyNewStatic();
            else
                body = cpBodyNew(mass, cpMomentForBox(mass, width, height));
            
            body->p = position;
            cpBodySetAngle(body, DEGREES_TO_RADIANS(-1*[[spriteProp objectForKey:@"Angle"] floatValue]));
            
            shape = cpBoxShapeNew(body, width, height);
            actor.shape = shape;
            
		}
		[self setShapePropertiesWithDictionary:spritePhysic forShape:shape];
        
        [arrayOfShapes addObject:[NSValue valueWithPointer:shape]];
        
    }
	else{
        float width = size.x*scale.x;
        float height = size.y*scale.y;
        
        
        if(bodyType == kBodyStatic)
            body = cpBodyNewStatic();
        else
            body = cpBodyNew(mass, cpMomentForBox(mass, width, height));
        
        body->p = position;
        cpBodySetAngle(body, DEGREES_TO_RADIANS(-1*[[spriteProp objectForKey:@"Angle"] floatValue]));
        
        //IMPORTANT:, because of using spaceManager to manage space. ONLY one fixture supported.
        NSLog(@"TOTAL %d fixtures using...",[fixtures count]);
        //        NSAssert([fixtures count] <= 1, @"More than one fixtures");
		for(NSArray* curFixture in fixtures) {
			int size = (int)[curFixture count];
            CGPoint verts[size];
			int i = 0;
            for(int p = [curFixture count] -1; p > -1 ; --p) {
                NSString* pointStr = [curFixture objectAtIndex:p];
				CGPoint point = riPointFromString(pointStr);
                verts[i] = ccp(point.x*(scale.x), 
                               point.y*(scale.y));
				++i;
			}
            
            shape = cpPolyShapeNew(body, size, verts, CGPointZero);
            [self setShapePropertiesWithDictionary:spritePhysic forShape:shape];
            
            [arrayOfShapes addObject:[NSValue valueWithPointer:shape]];
            
            actor.shape = shape;
            
		}
	}
    
	return [arrayOfShapes autorelease] ;
	
}

-(NSValue*) jointWithDictionary:(NSDictionary*)joint {
    
	if(nil == joint)
		return 0;
	
    cpBody* bodyA  = 0;
    NSMutableArray* bodyAArray = [shapesInStage objectForKey:[joint objectForKey:@"ObjectA"]];
    if([bodyAArray count] > 0)
    {
        cpShape* shape = (cpShape*)[[bodyAArray objectAtIndex:0] pointerValue];
        bodyA = (cpBody*)shape->body;
    }
    
    cpBody* bodyB  = 0;
    NSMutableArray* bodyBArray = [shapesInStage objectForKey:[joint objectForKey:@"ObjectB"]];
    if([bodyAArray count] > 0)
    {
        cpShape* shape = (cpShape*)[[bodyBArray objectAtIndex:0] pointerValue];
        bodyB = (cpBody*)shape->body;
    }
    
	
	CGPoint anchorA = riPointFromString([joint objectForKey:@"AnchorA"]);
	CGPoint anchorB = riPointFromString([joint objectForKey:@"AnchorB"]);
	
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
        
		switch ([[joint objectForKey:@"JointType"] intValue])
        {
			case kPinJoint:
                constraint = cpPinJointNew(bodyA, bodyB, posA, posB);
				break;
				
			case kSpringJoint:
            {
                float restLength = [[joint objectForKey:@"RestLength"] floatValue];
                restLength = restLength == 0 ? 50 : restLength;
                float stiffness = [[joint objectForKey:@"Stiffness"] floatValue];
                stiffness = stiffness == 0 ? 1.0 : stiffness;
                float damping = [[joint objectForKey:@"Damping"] floatValue];
                damping = damping == 0 ? 1.0 : damping;
                
                constraint = cpDampedSpringNew(bodyA, bodyB, posA, posB, restLength, stiffness, damping);
            }
				break;
				
			case kRotarySpringJoint:
            {
                float restAngle = [[joint objectForKey:@"RestAngle"] floatValue];
                restAngle = restAngle == 0 ? 50 : restAngle;
                float stiffness = [[joint objectForKey:@"Stiffness"] floatValue];
                stiffness = stiffness == 0 ? 1.0 : stiffness;
                float damping = [[joint objectForKey:@"Damping"] floatValue];
                damping = damping == 0 ? 1.0 : damping;

                constraint = cpDampedRotarySpringNew(bodyA, bodyB,restAngle, stiffness, damping);
            }
				break;
				
			case kSlideJoint:
            {
                float min = [[joint objectForKey:@"Min"] floatValue];
                min = min == 0 ? 10 : min;
                float max = [[joint objectForKey:@"Max"] floatValue];
                max = max == 0 ? 20 : max;
                
                constraint = cpSlideJointNew(bodyA, bodyB, posA, posB, min, max);
            }
				break;
				
			case kGrooveJoint:
            {
                NSString * strA = [joint objectForKey:@"GrooveA"];
                CGPoint grooveA = strA == nil ? posA :  riPointFromString(strA);
                NSString * strB = [joint objectForKey:@"GrooveB"];
                CGPoint grooveB = strB == nil ? posB :  riPointFromString(strB);
                
                constraint = cpGrooveJointNew(bodyA, bodyB, grooveA, grooveB, posB);
            }
				break;
				
			case kPivotJoint:
            {
                NSString * str = [joint objectForKey:@"Pivot"];
                CGPoint pivotPos = str == nil ? posA : riPointFromString(str);
                
                constraint = cpPivotJointNew(bodyA, bodyB, pivotPos);
            }
				break;
                
            case kMotorJoint:
            {
                if([[joint objectForKey:@"EnableMotor"] boolValue])
                {
                    float rate = [[joint objectForKey:@"Rate"] floatValue];
                    rate = rate == 0 ? 1 : rate;
                    
                    constraint = cpSimpleMotorNew(bodyA, bodyB, rate);
                }
            }
				break;	
                
            case kGearJoint:
            {
                float phase = [[joint objectForKey:@"Phase"] floatValue];
                phase = phase == 0 ? 1 : phase;
                float ratio = [[joint objectForKey:@"Ratio"] floatValue];
                ratio = ratio == 0 ? 1 : ratio;
                
                constraint = cpGearJointNew(bodyA, bodyB, phase, ratio);
            }
				break;
                
            case kRatchetJoint:
            {
                float phase = [[joint objectForKey:@"Phase"] floatValue];
                phase = phase == 0 ? 1 : phase;
                float ratchet = [[joint objectForKey:@"Ratchet"] floatValue];
                ratchet = ratchet == 0 ? 1 : ratchet;

                constraint = cpRatchetJointNew(bodyA, bodyB, phase, ratchet);
            }
				break;
                
            case kRotaryLimitJoint:
            {
                float min = [[joint objectForKey:@"Min"] floatValue];
                min = min == 0 ? 1 : min;
                float max = [[joint objectForKey:@"Max"] floatValue];
                max = max == 0 ? 1 : max;
                
                constraint = cpRotaryLimitJointNew(bodyA, bodyB, min, max);
            }
				break;
                
			default:
				NSLog(@"Unknown joint type in riLevelLoader file.");
				break;
        }
        
        if(constraint != nil)
            return [NSValue valueWithPointer:constraint];
        else
            return nil;
        
    }
	return nil;
}

-(void) setSpritePropertiesWithDictionary:(NSDictionary*)spriteProp forActor:(riActor*) actor
{
	//convert position from LH to Cocos2d coordinates
	CGPoint position;
    NSMutableArray * positions = [spriteProp objectForKey:@"Positions"];
    if(positions == nil){
        NSString * ps = [spriteProp objectForKey:@"Position"];
        if(ps != nil && ![ps isEqualToString:@""])
            position = riPointFromString(ps);
        else
            position = CGPointMake(0,0);
        positions = [NSMutableArray arrayWithCapacity:1];
        [positions addObject:[NSString stringWithFormat:@"{%d,%d}",position.x,position.y]];
    }
    else{
        int n = [positions count];
        if (n == 0) 
            position = CGPointMake(0,0);
        else{
            int m = (arc4random() % n);
            position = riPointFromString([positions objectAtIndex:m]);
        }
    }
    
    [actor setPositions:positions];
	[actor setPosition:position];
	[actor setRotation:[[spriteProp objectForKey:@"Angle"] floatValue]];
	[actor setOpacity:255*[[spriteProp objectForKey:@"Opacity"] floatValue]];
	CGRect color = riRectFromString([spriteProp objectForKey:@"Color"]);
	[actor setColor:ccc3(255*color.origin.x, 255*color.origin.y, 255*color.size.width)];
	CGPoint scale = riPointFromString([spriteProp objectForKey:@"Scale"]);
	[actor setScaleX:scale.x];
	[actor setScaleY:scale.y];
	[actor setTag:[[spriteProp objectForKey:@"Tag"] intValue]];
    [actor setName:[spriteProp objectForKey:@"Name"]];

    NSString* animationName = [spriteProp objectForKey:@"Animation"];
    if(animationName != nil && ![animationName isEqualToString:@""]){
        NSString * aname = [NSString stringWithFormat:@"%@_%@",actor.name,animationName];
        CCAnimation * curAnimation = [[CCAnimationCache sharedAnimationCache] animationByName:aname];
        if (curAnimation != nil) {
            int times = [[spriteProp objectForKey:@"AnimationTimes"] intValue];
            if(times <= 0)
                actor.curAnimate = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:curAnimation]];
            else{
                actor.curAnimate = [CCRepeat actionWithAction:[CCAnimate actionWithAnimation:curAnimation restoreOriginalFrame:NO] times:times];
            }
        }
    }
    
}

-(void) setActorPropertiesWithDictionary:(NSDictionary*)actorProp forActor:(riActor*)actor{
    
    if(actorProp != nil){
        
        float life = [[actorProp objectForKey:@"Life"] floatValue];
        life = life == 0 ? kActorLifeDefault : life;
        actor.life = life;
        
        float age = [[actorProp objectForKey:@"Age"] floatValue];
        age = age == 0 ? kActorAgeDefault : age;
        actor.age = age;
                
        NSString * s = [actorProp objectForKey:@"Speed"];
        int speed = 0;
        if(s != nil){
            CGPoint sp = riPointFromString(s);
            if(sp.x == sp.y) speed = (int)sp.x;
            else speed = arc4random()% (int)abs(sp.y - sp.x) + (int)abs(sp.x);
        }
        actor.speed = speed;

        float health = [[actorProp objectForKey:@"Health"] floatValue];
        health = health == 0 ? kActorHealthDefault : health;
        actor.health = health;
        
        float demage = [[actorProp objectForKey:@"Demage"] floatValue];
        demage = demage == 0 ? kActorDemageDefault : demage;
        actor.demage = demage;
        
        float power = [[actorProp objectForKey:@"Power"] floatValue];
        power = power == 0 ? kActorPowerDefault : power;
        actor.power = power;
        
        int score = [[actorProp objectForKey:@"Score"] intValue];
        score = score == 0 ? kActorScoreDefault : score;
        actor.score = score;
        
        float updateInterval = [[actorProp objectForKey:@"UpdateInterval"] floatValue];
        updateInterval = updateInterval == 0 ? kActorUpdateIntervalDefault : updateInterval;
        actor.updateInterval = updateInterval;
        
        float logicInterval = [[actorProp objectForKey:@"LogicInterval"] floatValue];
        logicInterval = logicInterval == 0 ? kActorLogicIntervalDefault : logicInterval;
        actor.logicInterval = logicInterval;
        
        NSArray * waypoints = [actorProp objectForKey:@"Waypoints"];
        if(waypoints != nil){
            [actor setWaypoints:waypoints];
            int n = [waypoints count];
            if (n > 0){
                int m = (arc4random() % n);
                NSString * w = [waypoints objectAtIndex:m];
                riTiledMapWaypoint* wp = [[DataModel sharedDataModel].waypoints objectForKey:w];
                actor.curWaypoint = wp;
                
                //If actor's position cpvzero, reset its position to waypoint's position.
                if(cpveql(cpvzero, actor.position))
                    actor.position = wp.position;
            }
        }

        NSString* actorType = [actorProp objectForKey:@"ActorType"];
        if(actorType != nil)
            actor.actorType = actorType;
    }
    
}

-(void) setShapePropertiesWithDictionary:(NSDictionary*)spritePhysic forShape:(cpShape*)shapeDef
{
    if(spritePhysic != nil){
        //shapeDef->density = [[spritePhysic objectForKey:@"Density"] floatValue];
        shapeDef->u = [[spritePhysic objectForKey:@"Friction"] floatValue];
        shapeDef->e = [[spritePhysic objectForKey:@"Restitution"] floatValue];
        shapeDef->sensor = [[spritePhysic objectForKey:@"IsSenzor"] boolValue];
        
        //	shapeDef->filter.categoryBits = [[spritePhysic objectForKey:@"Category"] intValue];
        shapeDef->layers = [[spritePhysic objectForKey:@"Mask"] intValue];
        shapeDef->group = [[spritePhysic objectForKey:@"Group"] intValue];
        shapeDef->collision_type = [[spritePhysic objectForKey:@"CollisionType"] intValue];	

    }
    
}



#pragma mark Get -- New  -- Remove 


-(unsigned int) numberOfBatchNodesUsed
{
	return (int)[batchNodes count] -1;
}

-(CCSprite*) spriteWithName:(NSString*)name
{
	if(addSpritesToLayerWasUsed)
	{
		return [shapesInStage objectForKey:name];	
	}
	else if(addObjectsToWordWasUsed){
        NSMutableArray* shapes = [shapesInStage objectForKey:name];
        
        if([shapes count] > 0)
        {
            cpShape* shape = (cpShape*)[[shapes objectAtIndex:0] pointerValue];
            
            cpBody* body = shape->body;
            
            return (CCSprite*)body->data;
        }
        
    }else
    {
        return (CCSprite*)[actorsInStageNoPhysics objectForKey:name];
        
    }
	
	return nil;
}

-(cpBody*) bodyWithName:(NSString*)name
{
	if(addObjectsToWordWasUsed)
	{
		NSMutableArray* shapes = [shapesInStage objectForKey:name];
        
        if([shapes count] > 0)
        {
            cpShape* shape = (cpShape*)[[shapes objectAtIndex:0] pointerValue];
            
            return shape->body;
        }
	}
	
	return nil;
}

-(BOOL) removeSpriteWithName:(NSString*)name
{
	NSAssert(addObjectsToWordWasUsed!=YES, @"You cannot remove a sprite with method removeCCSpriteWithName if you used the method addObjectToWorld to load your level. Use method removeBody."); 
	
	CCSprite* ccsprite = nil;
	if(!addObjectsToWordWasUsed)
	{
		ccsprite = [shapesInStage objectForKey:name];
	}
	else {
		ccsprite = [actorsInStageNoPhysics objectForKey:name];
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
		[shapesInStage removeObjectForKey:name];
	}
	else {
		[actorsInStageNoPhysics removeObjectForKey:name];
	}
	
	
	return YES;
}

-(BOOL) removeSprite:(riActor*)actor
{
	NSAssert(addObjectsToWordWasUsed!=YES, @"You cannot remove a sprite with method removeCCSprite if you used the method addObjectToWorld to load your level. Use method removeBody."); 
	
	if(nil == actor)
		return NO;
	
	if([actor usesBatchNode])
	{
		NSArray * keys= nil;
		if(!addObjectsToWordWasUsed)
			keys = [shapesInStage allKeysForObject:actor];
		else {
			keys = [actorsInStageNoPhysics allKeysForObject:actor];
		}
		
		CCSpriteBatchNode *batchNode = [actor batchNode];
		
		[batchNode removeChild:actor cleanup:YES];
		
		for(NSString* key in keys)
		{
			if(!addObjectsToWordWasUsed)
				[shapesInStage removeObjectForKey:key];
			else {
				[actorsInStageNoPhysics removeObjectForKey:key];
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
		keys = [shapesInStage allKeys];
	else {
		keys = [actorsInStageNoPhysics allKeys];
	}
	
	BOOL removedAll = YES;
	for(NSString* key in keys)
	{
		removedAll = removedAll == [self removeSpriteWithName:key];
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

-(BOOL) removeBodyWithName:(NSString*)name
{
    NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a body with method removeBodyWithName if you used the method addSpritesToLayer to load your level. Use method removeCCSprite or removeCCSpriteWithName."); 
	
	NSMutableArray* data = [shapesInStage objectForKey:name];
	
	if(0 != data)
	{
        cpBody* body = 0;
        for(NSValue* value in data)
        {
            
            cpShape* shape = (cpShape*)[value pointerValue];
            body = shape->body;
            
            cpSpaceRemoveShape(_space, shape);
            cpShapeFree(shape);
        }
        
//        CCSprite* ccsprite = (CCSprite*)body->data;
//        
//        CCSpriteBatchNode *batchNode = [ccsprite batchNode];
//		
//		if(nil != batchNode)
//            [batchNode removeChild:ccsprite cleanup:YES];
		
        [shapesInStage removeObjectForKey:name];
		
        if(body != nil && cpSpaceContainsBody(_space, body)){
            cpSpaceRemoveBody(_space, body);
            cpBodyFree(body);
        }

        
        return YES;
	}
	
	return NO;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-(BOOL) removeBody:(cpBody*)body
//{
//    NSLog(@"remove body");
//	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a body with method removeBody if you used the method addSpritesToLayer to load your level. Use method removeCCSprite or removeCCSpriteWithName."); 
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
	
	NSArray *keys = [shapesInStage allKeys];
	
	BOOL removedAll = YES;
	for(NSString* key in keys)
	{
		removedAll = removedAll == [self removeBodyWithName:key];
	}
	return removedAll;		
}

-(cpConstraint*) jointWithName:(NSString*)name
{
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a joint with method removeJointWithName if you used the method addSpritesToLayer to load your level."); 
	
	
	return (cpConstraint*)[[jointsInStage objectForKey:name] pointerValue];
}

-(BOOL) removeJointWithName:(NSString*)name
{
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a joint with method removeJointWithName if you used the method addSpritesToLayer to load your level."); 
	
	
	cpConstraint* joint = (cpConstraint*)[[jointsInStage objectForKey:name] pointerValue];
	
	if(0 != joint)
	{
		return [self removeJoint:joint];
	}
	
	return NO;
}

-(BOOL) removeAllJoints
{
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove joints with method removeAllJoints if you used the method addSpritesToLayer to load your level."); 
    
	NSArray *keys = [jointsInStage allKeys];
	
	BOOL removedAll = YES;
	for(NSString* key in keys)
	{
		removedAll = removedAll == [self removeJointWithName:key];
	}
	return removedAll;	
}

-(BOOL) removeJoint:(cpConstraint*) joint
{
	NSAssert(addSpritesToLayerWasUsed!=YES, @"You cannot remove a joint with method removeJoint if you used the method addSpritesToLayer to load your level."); 
	
	if(0 == joint)
		return NO;
    
	NSArray * keys = [jointsInStage allKeysForObject:[NSValue valueWithPointer:joint]];
	
	if(0 == _space)
		return NO;
	
	for(NSString* key in keys)
	{
		[jointsInStage removeObjectForKey:key];
	}
    cpSpaceRemoveConstraint(_space, joint);
    
	return YES;
}

-(NSMutableArray*) newBodyWithName:(NSString*)name 
                                   world:(cpSpace*)world_
                            gameLayer:(GameLayer*)gameLayer_
{
	for(NSDictionary* dictionary in actorDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if([[spriteProp objectForKey:@"Name"] isEqualToString:name])
		{
			riActor * ccsprite = [self spriteWithDictionary:spriteProp];	
			
			if(nil == ccsprite)
				return 0;
			
			[_gameLayer addChild:ccsprite];
			
			NSDictionary* physicProp = [dictionary objectForKey:@"PhysicProperties"];
			
			return [self shapesWithDictionary:physicProp
							 spriteProperties:spriteProp
										 data:ccsprite];
		}
	}
	
	return 0;
}

-(NSMutableArray*)spritesWithTag:(LevelHelper_TAG)tag
{
	NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
	
	NSArray *keys = [shapesInStage allKeys];
	for(NSString* key in keys)
	{
		CCSprite* ccSprite = [self spriteWithName:key];
        
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
	
	NSArray *keys = [shapesInStage allKeys];
	for(NSString* key in keys)
	{
        cpBody* body = [self bodyWithName:key];
		CCSprite* ccSprite = (CCSprite*)body->data;
		
		if(nil != ccSprite && [ccSprite tag] == (int)tag)
		{
			[array addObject:[NSValue valueWithPointer:body]];
		}
	}
	
	return array;
}

-(NSMutableArray*)newSpritesWithTag:(LevelHelper_TAG)tag
                       gameLayer:(GameLayer*)gameLayer_
{
	NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
	
	for(NSDictionary* dictionary in actorDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if((LevelHelper_TAG)[[spriteProp objectForKey:@"Tag"] intValue] == tag)
		{
			CCSprite* ccsprite = [self spriteWithDictionary:spriteProp];
			
			if(nil != ccsprite)
			{
				[array addObject:ccsprite];
				[gameLayer_ addChild:ccsprite];
			}
		}
	}
	
	return array;
}

-(NSMutableArray*) newBodiesWithTag:(LevelHelper_TAG)tag 
							  world:(cpSpace*)world_
					   gameLayer:(GameLayer*)gameLayer_
{
	NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
	
	for(NSDictionary* dictionary in actorDictsArray)
	{
		NSDictionary* spriteProp = [dictionary objectForKey:@"GeneralProperties"];
		
		if((LevelHelper_TAG)[[spriteProp objectForKey:@"Tag"] intValue] == tag)
		{
			riActor* ccsprite = [self spriteWithDictionary:spriteProp];
			
			if(nil != ccsprite)
			{
				NSDictionary* physicProp = [dictionary objectForKey:@"PhysicProperties"];
				
				NSValue* v = [NSValue valueWithPointer:[self shapesWithDictionary:physicProp
																 spriteProperties:spriteProp
																			 data:ccsprite]];
				[array addObject:v];
				
				[gameLayer_ addChild:ccsprite];
			}
		}
	}
	return array;
}

-(void) releaseAll
{
	[actorDictsArray release];
	[jointDictsArray release];
    
	if(addObjectsToWordWasUsed){
		[self removeAllJoints];	
		[self removeAllBodies];
		[self removeAllSprites]; //for no physic sprites
	}
	else {
		[self removeAllSprites];
	}
    [actorsInStage release];
	[shapesInStage release];
	[jointsInStage release];
	[actorsInStageNoPhysics release];
	
	
	NSArray *keys = [batchNodes allKeys];
	for(NSString* key in keys)
	{
		NSDictionary* info = [batchNodes objectForKey:key];
		
		CCSpriteBatchNode *v = [info objectForKey:@"CCBatchNode"];
		[_gameLayer removeChild:v cleanup:YES];
	}
	[batchNodes release];
    
}

-(oneway void) release
{
	[self releaseAll];
}


@end
