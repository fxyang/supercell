//
//  PlayLayer.m
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"

#import "DataModel.h"
#import "GameHUD.h"
#import "SceneManager.h"

#import "riVerletRope.h"
#import "riActor.h"
#import "riLevelLoader.h"

#define kBallCollisionType		1
#define kCircleCollisionType	2
#define kRectCollisionType		3
#define kFragShapeCollisionType	4

static cpFloat
springForce(cpConstraint *spring, cpFloat dist)
{
    return cpfmin(cpDampedSpringGetRestLength(spring) - dist, 0.2f)*cpDampedSpringGetStiffness(spring);
}


@implementation GameLayer

@synthesize gameTime = _gameTime;

@synthesize spaceManager = _spaceManager;
@synthesize tileMap = _tileMap;
@synthesize background = _background;
@synthesize actorSprite = _actorSprite;
@synthesize actorActionArray = _actorActionArray;

@synthesize currentLevel = _currentLevel;

@synthesize flyActionArray = _flyActionArray;

@synthesize dragon = _dragon;
@synthesize moveAction = _moveAction;
@synthesize flyAction = _flyAction;

enum {
    kTagSpriteSheet = 1,
};

-(id) init{
	self = [super init];
	if (!self) {
		return nil;
	}
    
    self.isTouchEnabled = YES;
    
    _gameTime = 0;
    
	_spaceManager = [[SpaceManagerCocos2d alloc] init];
//	[_spaceManager addWindowContainmentWithFriction:1.0 elasticity:0.5 inset:cpvzero];
	_spaceManager.constantDt = 1.0/55.0;
    _spaceManager.damping = 1.0;
    
    space = [_spaceManager space];
    
    _actorActionArray = [[NSMutableArray alloc] init];
    
    ropeSegmentSpriteBatchNode = [CCSpriteBatchNode batchNodeWithFile:@"rope.png" ]; 
    [ropeSegmentSpriteBatchNode retain];
    [self addChild:ropeSegmentSpriteBatchNode z:10]; 

    [self addActorAt:ccp(200,800)];
    [_actorSprite runAction:[_actorSprite.actionArray  objectAtIndex:0]];

    
    _curSeg = nil;
    
    self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
    self.background = [_tileMap layerNamed:@"Background"];
    self.background.anchorPoint = ccp(0, 0);
    [self addChild:_tileMap z:0];
    
    [self addWaypoint];
    [self addWaves];
    
    
	
    
    
    self.currentLevel = 0;
    
    //self.position = ccp(-228, -122);
    self.position = ccp(0, 0);

    
    gameHUD = [GameHUD sharedHUD];
    [gameHUD schedule:@selector(updateResourcesNom) interval: 2.0];
    
	CCMenuItemFont *back = [CCMenuItemFont itemFromString:@"back" target:self selector: @selector(back:)];
	CCMenu *menu = [CCMenu menuWithItems: back, nil];
    
	menu.position = ccp(160, 150);
	[gameHUD addChild: menu];
    
    
    
    [self schedule:@selector(update:)];
    [self schedule:@selector(gameLogic:) interval:0.2];	
	[_spaceManager start]; 	
    
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
    [_spaceManager stop];

    [self removeAllChildrenWithCleanup:YES];

    [verletRope release];
    verletRope = nil;

    [ropeSegmentSpriteBatchNode release];
    ropeSegmentSpriteBatchNode = nil;
    
    [_actorSprite release];
    _actorSprite = nil;

    [_actorActionArray release];
    _actorActionArray = nil;
    
    [actorSpriteBatchNode release];
    actorSpriteBatchNode = nil;
    
    [_spaceManager release];
    
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];

	[super dealloc];
}

-(void)addActorAt:(CGPoint) pt{
    
    CCTexture2D *actorTexture = [[CCTextureCache sharedTextureCache] addImage:@"dragon.png"];
    actorSpriteBatchNode = [CCSpriteBatchNode batchNodeWithTexture:actorTexture capacity:10];
    [actorSpriteBatchNode retain];
    [self addChild:actorSpriteBatchNode z:10]; 
    
    _actorSprite = [[riActor alloc] initWithTexture:actorTexture width:75 height:70 column:10 row:8];
    CCSpriteFrame *frameFirst = [CCSpriteFrame frameWithTexture:actorTexture rect:CGRectMake(0, 0, 75, 70)];
    [_actorSprite setDisplayFrame: frameFirst];
    _actorSprite.position = pt;
    _actorSprite.gameLayer = self;
    _actorSprite.ignoreRotation = YES;
    _actorSprite.spaceManager = _spaceManager;
    cpShape *actorShape = [_spaceManager addCircleAt:pt mass:1 radius:20];
    actorShape->collision_type = kBallCollisionType;
    actorShape->e = 1.0;
    _actorSprite.shape = actorShape;
    
    _actorSprite.life = 100.0;
    
    [actorSpriteBatchNode addChild:_actorSprite];
    
    
    cpShape *pivotShape = [_spaceManager addCircleAt:cpv(228,280) mass:STATIC_MASS radius:10];
    pivotShape->e = 0.1f;
    pivotShape->u = 1.0f;
    pivotShape->collision_type = kBallCollisionType;
    cpCCSprite * pivotSprite = [cpCCSprite spriteWithFile:@"Enemy1.png"];
    pivotSprite.shape = pivotShape;
    pivotSprite.autoFreeShapeAndBody = YES;
    pivotSprite.spaceManager = _spaceManager;
    [self addChild:pivotSprite z:10];
    [pivotSprite runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCMoveBy actionWithDuration:4.0f position:ccp(300,0)],[CCMoveBy actionWithDuration:4.0f position:ccp(-300,0)],nil]]];
    
    ropeNodeA = pivotShape->body;
    
    
    
    levelLoader = [[riLevelLoader alloc] initWithContentOfFile:@"Level0"];
    levelLoader.spaceManager = _spaceManager;
    
    if([levelLoader hasWorldBoundaries])
        [levelLoader createWorldBoundaries:space];
    
    [levelLoader addActorsToWorld:space gameLayer:self];

    CCSprite* spr =  [levelLoader spriteWithUniqueName:@"TutorialTexture_3"];
    [spr setColor:ccc3(10, 10, 10)];
    cpBody* ball = [levelLoader bodyWithUniqueName:@"TutorialTexture_3"];
    ball->p = ccp(500, 200);

        
    //cpConstraint* joint = [lh jointWithUniqueName:@"TutorialTexture_4_18_TutorialTexture_3_1"];
    
}

-(void)addRope{
    //Remove Rope 
    if(verletRope !=nil && verletRope.status == kRopeStatusActive){       
        [verletRope removeRopeWithCutAt:CGPointZero duration:0.5f];
    }else if((verletRope !=nil && verletRope.status == kRopeStatusRemoved) || verletRope == nil){
        int ropeLength = cpvdist(ropeNodeA->p, [_actorSprite shape]->body->p);
        
        cpConstraint * ropeConstraint = [_spaceManager addSlideToBody:ropeNodeA fromBody:_actorSprite.body toBodyAnchor:cpv(0.0,0.0) fromBodyAnchor:cpv(0.0,0.0) minLength:0 maxLength:ropeLength];
        
        //        cpConstraint * ropeConstraint = [_spaceManager addSpringToBody:ropeNodeA fromBody:_actorSprite.body restLength:ropeLength stiffness:10 damping:10];
        //        cpDampedSpringSetSpringForceFunc(ropeConstraint, springForce);
        
        
        verletRope = [[riVerletRope alloc] initWithConstraint:ropeConstraint spriteSheet:ropeSegmentSpriteBatchNode isSolid:NO spaceManager:_spaceManager];
        verletRope.gameLayer = self;
    }
    
    
    [_actorSprite applyImpulse:ccpMult([_actorSprite body]->v, [_actorSprite body]->m *1.5)];
}

-(void)addWaves {
	DataModel *m = [DataModel getModel];
	
	Wave *wave = nil;
	wave = [[Wave alloc] initWithCreep:[FastRedCreep creep] SpawnRate:10 RedCreeps:0 GreenCreeps:5];
	[m._waves addObject:wave];
	wave = nil;
	wave = [[Wave alloc] initWithCreep:[FastRedCreep creep] SpawnRate:10 RedCreeps:5 GreenCreeps:5];
	[m._waves addObject:wave];
	wave = nil;	
    wave = [[Wave alloc] initWithCreep:[FastRedCreep creep] SpawnRate:10 RedCreeps:5 GreenCreeps:5];
	[m._waves addObject:wave];
	wave = nil;
	wave = [[Wave alloc] initWithCreep:[FastRedCreep creep] SpawnRate:10 RedCreeps:5 GreenCreeps:5];
	[m._waves addObject:wave];
    wave = nil;
    wave = [[Wave alloc] initWithCreep:[FastRedCreep creep] SpawnRate:10 RedCreeps:5 GreenCreeps:5];
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
        self.currentLevel = 0;
        NSLog(@"you have reached the end of the game!");
    }
	
    Wave * wave = (Wave *) [m._waves objectAtIndex:self.currentLevel];
    
    return wave;
}



-(void)addWaypoint {
	DataModel *m = [DataModel getModel];
	
	CCTMXObjectGroup *objectsGroup = [self.tileMap objectGroupNamed:@"Waypoints"];
	WayPoint *wp = nil;
	NSMutableDictionary *wayPoint;
    
    NSMutableArray * wpArray = objectsGroup.objects;
    if (wpArray != nil){
        int n = [wpArray count];
        for(int i = 0;i < n; i++){
            wayPoint = [wpArray objectAtIndex:i];
            int x = [[wayPoint valueForKey:@"x"] intValue];
            int y = [[wayPoint valueForKey:@"y"] intValue];
            NSString * wname = [wayPoint valueForKey:@"name"];
            wp = [WayPoint node];
            wp.position = ccp(x, y);
            wp.wayPointName = wname;
            [m._waypoints addObject:wp];
        }
        NSAssert([m._waypoints count] > 0, @"Waypoint objects missing");
        wp = nil;
    }

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
    _gameTime = _gameTime + dt;
    [levelLoader step];
    
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
                    creep.health--;
                    
                    if (creep.health <= 0) {
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
    

    if(verletRope != nil)
        [verletRope update:dt];

    
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

-(void)draw
{
	[super draw];
    if(verletRope != nil)
        [verletRope updateSprites];
    
}

-(void) back: (id) sender{
	[SceneManager goMenu];
}

-(void) addLine{
    
}

#pragma mark Touch Functions
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{	
	//Calculate a vector based on where we touched and where the ball is
	CGPoint pt = [self convertTouchToNodeSpace:[touches anyObject]];
    _touchBeginPos = pt;
	//CGPoint forceVect = ccpSub(pt, ballSprite.position);
	
	//cpFloat len = cpvlength(forceVect);
	//cpVect normalized = cpvnormalize(forceVect);
	
	//This applys a one-time force, pretty much like firing a bullet
	//[ballSprite applyImpulse:ccpMult(forceVect, 1)];
	

    //Lets apply an explosion instead    
	//[_spaceManager applyLinearExplosionAt:pt radius:240 maxForce:200];

//    [self addRope];
    //[self addLine];
    
//    cpShape * pin = [_spaceManager addRectAt:pt mass:STATIC_MASS width:2 height:2 rotation:0];
//    cpCCSprite * handle = [cpCCSprite spriteWithFile:@"Projectile.png"];
//    handle.shape = pin;

//    cpConstraint * joint = [_spaceManager addSpringToBody:_actorSprite.shape->body fromBody:handle.shape->body restLength:5.0f stiffness:5.0f damping:0.5f];

    
//    cpConstraintNode * jointNode = [cpConstraintNode nodeWithConstraint:joint];
//    jointNode.color = ccWHITE;
//    jointNode.lineWidth = 2.0f;
//
//    [self addChild:handle];
//    [self addChild:jointNode];


    
    
	//Reset Scene
    if ([touches count] > 1)
    {
        CCScene *scene = [CCScene node];
        [scene addChild:[GameLayer node]];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.4 scene:scene  withColor:ccBLUE]];
    }
    NSLog(@"Touch Start");

}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{	
    CGPoint pt = [self convertTouchToNodeSpace:[touches anyObject]];
    _touchEndPos = pt;
    
    int seglen = 20;
    int segno = 0;
    segno = cpvdist(_touchEndPos, _touchBeginPos) / seglen;
    if(segno >0){
        if(_curSeg != nil){
            [_spaceManager removeAndFreeShape:[_curSeg shape]];
            [self removeChild:_curSeg cleanup:YES];
            _curSeg = nil;
            NSLog(@"seg removed");

        }
        cpShape * seg = [_spaceManager addSegmentAtWorldAnchor:_touchBeginPos toWorldAnchor:_touchEndPos mass:STATIC_MASS radius:10];
        seg->e = 1.5;
        cpShapeNode * segNode = [cpShapeNode nodeWithShape:seg];
        [self addChild:segNode z:11];
        _curSeg = segNode;
        NSLog(@"Touch Moving");
    }
    
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{	
    CGPoint pt = [self convertTouchToNodeSpace:[touches anyObject]];
    _touchEndPos = pt;
    NSLog(@"Touch End");


	
}

@end