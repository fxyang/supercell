//
//  PlayLayer.m
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"
#import "cpConstraintNode.h"

#define kBallCollisionType		1
#define kCircleCollisionType	2
#define kRectCollisionType		3
#define kFragShapeCollisionType	4


@implementation GameLayer

@synthesize tileMap = _tileMap;
@synthesize background = _background;

@synthesize currentLevel = _currentLevel;

-(id) init{
	self = [super init];
	if (!self) {
		return nil;
	}
    
    self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
    self.background = [_tileMap layerNamed:@"Background"];
    self.background.anchorPoint = ccp(0, 0);
    [self addChild:_tileMap z:0];
    
    [self addWaypoint];
    [self addWaves];
    
    // Call game logic about every second
    [self schedule:@selector(update:)];
    [self schedule:@selector(gameLogic:) interval:0.2];		
    
    
    self.currentLevel = 0;
    
    //self.position = ccp(-228, -122);
    self.position = ccp(0, 0);

    
    gameHUD = [GameHUD sharedHUD];
    [gameHUD schedule:@selector(updateResourcesNom) interval: 2.0];
    
	CCMenuItemFont *back = [CCMenuItemFont itemFromString:@"back" target:self selector: @selector(back:)];
	CCMenu *menu = [CCMenu menuWithItems: back, nil];
    
	menu.position = ccp(160, 150);
	[gameHUD addChild: menu];
    
    
    //allocate our space manager
    self.isTouchEnabled = YES;
	smgr = [[SpaceManagerCocos2d alloc] init];
    
    //add four walls to our screen
	[smgr addWindowContainmentWithFriction:1.0 elasticity:1.0 inset:cpvzero];
	
	//Constant dt is recommended for chipmunk
	smgr.constantDt = 1.0/55.0;
    
    smgr.damping = 0.8;
    
    
    //start the manager!
	[smgr start]; 	
    
    
    
    //active shape, ball shape
    cpShape *pigShape = [smgr addCircleAt:cpv(384,650) mass:10 radius:32];
    NSLog(@"shape m = %f",pigShape->body->m);
    
    pigShape->collision_type = kBallCollisionType;
    pigSprite = [cpCCSprite spriteWithFile:@"pig_head_64_96.png"];
    pigSprite.shape = pigShape;
    pigSprite.autoFreeShapeAndBody = YES;
    pigSprite.ignoreRotation = YES;
    pigSprite.spaceManager = smgr;
    [self addChild:pigSprite z:11];
    
    cpShape *pivotShape = [smgr addCircleAt:cpv(400,800) mass:STATIC_MASS radius:3];
    pivotShape->e = 0.1f;
    pivotShape->u = 1.0f;
    pivotShape->collision_type = kBallCollisionType;
    
    cpCCSprite * pivotSprite = [cpCCSprite spriteWithFile:@"ball_rope_10_10.png"];
    pivotSprite.shape = pivotShape;
    pivotSprite.autoFreeShapeAndBody = YES;
    pivotSprite.spaceManager = smgr;
    [self addChild:pivotSprite z:10];
    
   // cpSpaceAddStaticShape(smgr.space, shape);

    cpBody * ropeNodeA = pivotShape->body;
    float spaceBetweenEachNode = 7.0;
    for (int i = 0; i < 30; i++) {
        
        cpShape *ropeNodeBShape = [smgr addCircleAt:cpv(ropeNodeA->p.x-spaceBetweenEachNode,ropeNodeA->p.y-spaceBetweenEachNode) mass:5 radius:3];
        ropeNodeBShape->e = 0.1f;
        ropeNodeBShape->u = 1.0f;
        ropeNodeBShape->collision_type = kBallCollisionType;
        

        [smgr addSlideToBody:ropeNodeA fromBody:ropeNodeBShape->body toBodyAnchor:cpv(0.0,0.0) fromBodyAnchor:cpv(0.0,0.0) minLength:0.0 maxLength:spaceBetweenEachNode];

        
        cpCCSprite * sp = [cpCCSprite spriteWithFile:@"ball_rope_10_10.png"];
        sp.shape = ropeNodeBShape;
        sp.autoFreeShapeAndBody = YES;
        //sp.ignoreRotation = YES;
        sp.spaceManager = smgr;
        [self addChild:sp z:10];
        
        ropeNodeA = ropeNodeBShape->body;
    }
    
    [smgr addSlideToBody:ropeNodeA fromBody:pigShape->body toBodyAnchor:cpv(0.0,0.0) fromBodyAnchor:cpv(0.0,0.0) minLength:0.0 maxLength:20];
    
	return self;
}

-(void)addWaves {
	DataModel *m = [DataModel getModel];
	
	Wave *wave = nil;
	wave = [[Wave alloc] initWithCreep:[FastRedCreep creep] SpawnRate:3.0 RedCreeps:10 GreenCreeps:0];
	[m._waves addObject:wave];
	wave = nil;
	wave = [[Wave alloc] initWithCreep:[FastRedCreep creep] SpawnRate:2.0 RedCreeps:5 GreenCreeps:15];
	[m._waves addObject:wave];
	wave = nil;	
    wave = [[Wave alloc] initWithCreep:[FastRedCreep creep] SpawnRate:3.0 RedCreeps:15 GreenCreeps:15];
	[m._waves addObject:wave];
	wave = nil;
	wave = [[Wave alloc] initWithCreep:[FastRedCreep creep] SpawnRate:4.0 RedCreeps:0 GreenCreeps:25];
	[m._waves addObject:wave];
    wave = nil;
    wave = [[Wave alloc] initWithCreep:[FastRedCreep creep] SpawnRate:3.0 RedCreeps:25 GreenCreeps:25];
	[m._waves addObject:wave];
	wave = nil;
}

- (Wave *)getCurrentWave{
	
	DataModel *m = [DataModel getModel];	
	Wave * wave = (Wave *) [m._waves objectAtIndex:self.currentLevel];
	
	return wave;
}

- (Wave *)getNextWave{
	
	DataModel *m = [DataModel getModel];
	
	self.currentLevel++;
	
	if (self.currentLevel >= 5){
        //self.currentLevel = 0;
        NSLog(@"you have reached the end of the game!");
    }
	
    Wave * wave = (Wave *) [m._waves objectAtIndex:self.currentLevel];
    
    return wave;
}



-(void)addWaypoint {
	DataModel *m = [DataModel getModel];
	
	CCTMXObjectGroup *objects = [self.tileMap objectGroupNamed:@"Objects"];
	WayPoint *wp = nil;
	
	int wayPointCounter = 0;
	NSMutableDictionary *wayPoint;
	while ((wayPoint = [objects objectNamed:[NSString stringWithFormat:@"Waypoint%d", wayPointCounter]])) {
		int x = [[wayPoint valueForKey:@"x"] intValue];
		int y = [[wayPoint valueForKey:@"y"] intValue];
		
		wp = [WayPoint node];
		wp.position = ccp(x, y);
		[m._waypoints addObject:wp];
		wayPointCounter++;
	}
	
	NSAssert([m._waypoints count] > 0, @"Waypoint objects missing");
	wp = nil;
}

- (CGPoint) tileCoordForPosition:(CGPoint) position 
{
	int x = position.x / self.tileMap.tileSize.width;
	int y = ((self.tileMap.mapSize.height * self.tileMap.tileSize.height) - position.y) / self.tileMap.tileSize.height;
	
	return ccp(x,y);
}

- (BOOL) canBuildOnTilePosition:(CGPoint) pos 
{
	CGPoint towerLoc = [self tileCoordForPosition: pos];
	
	int tileGid = [self.background tileGIDAt:towerLoc];
	NSDictionary *props = [self.tileMap propertiesForGID:tileGid];
	NSString *type = [props valueForKey:@"buildable"];
	
	if([type isEqualToString: @"1"]) {
		return YES;
	}
	
	return NO;
}

-(void)addTower: (CGPoint)pos: (int)towerTag{
	DataModel *m = [DataModel getModel];
	
	Tower *target = nil;
	
	CGPoint towerLoc = [self tileCoordForPosition: pos];
	
	int tileGid = [self.background tileGIDAt:towerLoc];
	NSDictionary *props = [self.tileMap propertiesForGID:tileGid];
	NSString *type = [props valueForKey:@"buildable"];
	
	
	NSLog(@"Buildable: %@", type);
	if([type isEqualToString: @"1"]) {
        
        
        switch (towerTag) {
            case 1:
                if (gameHUD.resources >= 25) {
                    target = [MachineGunTower tower];
                    [gameHUD updateResources:-25];
                }
                else
                    return;
                break;
            case 2:
                if (gameHUD.resources >= 35) {
                    target = [FreezeTower tower];
                    [gameHUD updateResources:-35];
                }
                else
                    return;
                break;
            case 3:
                if (gameHUD.resources >= 25) {
                    target = [MachineGunTower tower];
                    [gameHUD updateResources:-25];
                }
                else
                    return;
                break;
            case 4:
                if (gameHUD.resources >= 25) {
                    target = [MachineGunTower tower];
                    [gameHUD updateResources:-25];
                }  
                else
                    return;
                break;
            default:
                break;
        }
        
		target.position = ccp((towerLoc.x * 32) + 16, self.tileMap.contentSize.height - (towerLoc.y * 32) - 16);
		[self addChild:target z:1];
		
		target.tag = 1;
		[m._towers addObject:target];
        
		
	} else {
		NSLog(@"Tile Not Buildable");
	}
	
}

-(void)addTarget {
    
	DataModel *m = [DataModel getModel];
	Wave * wave = [self getCurrentWave];
	if (wave.redCreeps <= 0 && wave.greenCreeps <= 0) {
        
        return; //
	}
	
	//wave.totalCreeps--;
	
    Creep *target = nil;
    if ((arc4random() % 2) == 0) {
        if (wave.redCreeps > 0) {
            target = [FastRedCreep creep];
            wave.redCreeps--;
        }
        else if (wave.greenCreeps >0){
            target = [StrongGreenCreep creep];
            wave.greenCreeps--;
            // NSLog(@"no more red");
        }
    } 
    else {
        if (wave.greenCreeps >0) {
            target = [StrongGreenCreep creep];
            wave.greenCreeps--;
        }
        else if (wave.redCreeps >0){
            target = [FastRedCreep creep];
            wave.redCreeps--;
            //NSLog(@"no more green");
            
        }
    }	
	
	WayPoint *waypoint = [target getCurrentWaypoint ];
	target.position = waypoint.position;	
	waypoint = [target getNextWaypoint ];
	
	[self addChild:target z:1];
	
	int moveDuration = target.moveDuration;	
	id actionMove = [CCMoveTo actionWithDuration:moveDuration position:waypoint.position];
	id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(FollowPath:)];
	[target runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
	
	// Add to targets array
	target.tag = 1;
	[m._targets addObject:target];
	
}

-(void)FollowPath:(id)sender {
    
	Creep *creep = (Creep *)sender;
	
	WayPoint * waypoint = [creep getNextWaypoint];
    
	int moveDuration = creep.moveDuration;
	id actionMove = [CCMoveTo actionWithDuration:moveDuration position:waypoint.position];
    
	id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(FollowPath:)];
	[creep stopAllActions];
	[creep runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
}

-(void)ResumePath:(id)sender {
    Creep *creep = (Creep *)sender;
    
    WayPoint * cWaypoint = [creep getCurrentWaypoint];//destination
    WayPoint * lWaypoint = [creep getLastWaypoint];//startpoint
    
    float waypointDist = fabsf(cWaypoint.position.x - lWaypoint.position.x);
    float creepDist = fabsf(cWaypoint.position.x - creep.position.x);
    float distFraction = creepDist / waypointDist;
    float moveDuration = creep.moveDuration * distFraction; //Time it takes to go from one way point to another * the fraction of how far is left to go (meaning it will move at the correct speed)
    id actionMove = [CCMoveTo actionWithDuration:moveDuration position:cWaypoint.position];   
    id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(FollowPath:)];
	[creep stopAllActions];
	[creep runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
}

-(void)gameLogic:(ccTime)dt {
    
    
	
    //	DataModel *m = [DataModel getModel];
	Wave * wave = [self getCurrentWave];
	static double lastTimeTargetAdded = 0;
    double now = [[NSDate date] timeIntervalSince1970];
    if(lastTimeTargetAdded == 0 || now - lastTimeTargetAdded >= wave.spawnRate) {
        [self addTarget];
        lastTimeTargetAdded = now;
    }
	
}

- (void)update:(ccTime)dt {
    
	DataModel *m = [DataModel getModel];
	NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    
	for (Projectile *projectile in m._projectiles) {
		
		CGRect projectileRect = CGRectMake(projectile.position.x - (projectile.contentSize.width/2), 
										   projectile.position.y - (projectile.contentSize.height/2), 
										   projectile.contentSize.width, 
										   projectile.contentSize.height);
        
		NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
        
		for (CCSprite *target in m._targets) {
            
			CGRect targetRect = CGRectMake(target.position.x - (target.contentSize.width/2), 
										   target.position.y - (target.contentSize.height/2), 
										   target.contentSize.width, 
										   target.contentSize.height);
            
			if (CGRectIntersectsRect(projectileRect, targetRect)) {
                
				[projectilesToDelete addObject:projectile];
                Creep *creep = (Creep *)target;
                if (projectile.tag ==1){//MachineGun Projectile
                    creep.hp--;
                    
                    if (creep.hp <= 0) {
                        [targetsToDelete addObject:target];
                        [gameHUD updateResources:1];
                    }
                    break;
                }
                else if (projectile.tag ==2){//Freeze projectile
                    id actionFreeze = [CCMoveTo actionWithDuration:1.5 position:creep.position];    
                    id actionMoveResume = [CCCallFuncN actionWithTarget:self selector:@selector(ResumePath:)];  
                    [creep stopAllActions];
                    [creep runAction:[CCSequence actions:actionFreeze, actionMoveResume, nil]];
                    break;
                }
                break;
                
			}						
		}
		
		for (CCSprite *target in targetsToDelete) {
			[m._targets removeObject:target];
			[self removeChild:target cleanup:YES];									
		}
		
		[targetsToDelete release];
	}
	
	for (CCSprite *projectile in projectilesToDelete) {
		[m._projectiles removeObject:projectile];
		[self removeChild:projectile cleanup:YES];
	}
	[projectilesToDelete release];
    
    
    Wave *wave = [self getCurrentWave];
    if ([m._targets count] ==0 && wave.redCreeps <= 0 && wave.greenCreeps <= 0) {
        [self getNextWave];
        [gameHUD updateWaveCount];
    }
}


- (CGPoint)boundLayerPos:(CGPoint)newPos {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CGPoint retval = newPos;
    retval.x = MIN(retval.x, 0);
    retval.x = MAX(retval.x, -_tileMap.contentSize.width+winSize.width); 
    retval.y = MIN(0, retval.y);
    retval.y = MAX(-_tileMap.contentSize.height+winSize.height, retval.y); 
    return retval;
}

- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {    
        
        CGPoint touchLocation = [recognizer locationInView:recognizer.view];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];                
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {    
        
        CGPoint translation = [recognizer translationInView:recognizer.view];
        translation = ccp(translation.x, -translation.y);
        CGPoint newPos = ccpAdd(self.position, translation);
        self.position = [self boundLayerPos:newPos];  
        [recognizer setTranslation:CGPointZero inView:recognizer.view];    
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
		float scrollDuration = 0.2;
		CGPoint velocity = [recognizer velocityInView:recognizer.view];
		CGPoint newPos = ccpAdd(self.position, ccpMult(ccp(velocity.x, velocity.y * -1), scrollDuration));
		newPos = [self boundLayerPos:newPos];
        
		[self stopAllActions];
		CCMoveTo *moveTo = [CCMoveTo actionWithDuration:scrollDuration position:newPos];            
		[self runAction:[CCEaseOut actionWithAction:moveTo rate:1]];            
        
    }        
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
    [self removeAllChildrenWithCleanup:YES];
	
    [smgr stop];
	[smgr release];
    
    
	[super dealloc];
}

-(void) back: (id) sender{
	[SceneManager goMenu];
}

#pragma mark Touch Functions
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{	
	//Calculate a vector based on where we touched and where the ball is
	CGPoint pt = [self convertTouchToNodeSpace:[touches anyObject]];
	//CGPoint forceVect = ccpSub(pt, ballSprite.position);
	
	//cpFloat len = cpvlength(forceVect);
	//cpVect normalized = cpvnormalize(forceVect);
	
	//This applys a one-time force, pretty much like firing a bullet
	//[ballSprite applyImpulse:ccpMult(forceVect, 1)];
	

    //Lets apply an explosion instead    
	//[smgr applyLinearExplosionAt:pt radius:240 maxForce:200];
	    
    
    
    
    
    cpShape * pin = [smgr addRectAt:pt mass:STATIC_MASS width:2 height:2 rotation:0];
    cpCCSprite * handle = [cpCCSprite spriteWithFile:@"Projectile.png"];
    handle.shape = pin;

    cpConstraint * joint = [smgr addSpringToBody:pigSprite.shape->body fromBody:handle.shape->body restLength:5.0f stiffness:100.0f damping:10.0f];

    
    cpConstraintNode * jointNode = [cpConstraintNode nodeWithConstraint:joint];
    jointNode.color = ccWHITE;
    jointNode.lineWidth = 2.0f;

    [self addChild:handle];
    [self addChild:jointNode];

    
    
    
	//Reset Scene
    if ([touches count] > 1)
    {
        CCScene *scene = [CCScene node];
        [scene addChild:[GameLayer node]];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.4 scene:scene  withColor:ccBLUE]];
    }
}


@end