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

#import "riJoystick.h"

void bulletCallback(cpSpace *space, void *obj, void *data)
{
    GameLayer *game = data;
    riActor * bullet = (riActor *)obj;
    
    if(bullet != nil){
        
        [bullet stopAction:bullet.curMovement];
        
        CCParticleSystemQuad * bulletExplosionParticle = [CCParticleSystemQuad particleWithFile:@"BulletExplosionParticle.plist"];
        bulletExplosionParticle.position = bullet.position;
        bulletExplosionParticle.autoRemoveOnFinish = YES;
        [game addChild:bulletExplosionParticle z:kBulletParticleZ];
        
        CCActionInterval * bulletFinishing = [CCSpawn actions:
                                              [CCScaleTo actionWithDuration:1.5 scale:0.1],
                                              [CCFadeOut actionWithDuration:1.5],
                                              nil];
        
        
        [bullet runAction:[CCSequence actions:bulletFinishing,[CCCallFuncO actionWithTarget:game selector:@selector(bulletStop:) object:bullet], nil]];
        
        
        if([bullet countType] == kCountLimitFinity)
            [[game levelLoader] increaseActorCountWithName:bullet.name count:1 delay:2.0];
        
        //Bullet shape is managed by GameLayer. So use spaceManager to remove it.
        [[game spaceManager] removeAndFreeShape:bullet.shape];
        
        /*The memory address of bullet.shape will be reused. so set it point to nil will avoid making messy
         before it is removed by game.*/
        bullet.shape = nil;
        
    }
}

void targetCallback(cpSpace *space, void *obj, void *data)
{
    GameLayer *game = data;
    riActor * actor = (riActor *)obj;
    
    if(actor != nil && actor.health <= actor.damage){
        [actor stopAction:actor.curMovement];
        
        int n = actor.score;
        for(int i = 1;i <= n; i++){
            riActor * coin = [riActor spriteWithFile:@"gold_coin_128_128.png"];
            coin.position = actor.position;
            coin.scale = 0.3;
            
            CCParticleSystemQuad * coinParticle = [CCParticleSystemQuad particleWithFile:@"CoinParticle.plist"];
            coinParticle.position = actor.position;
            coinParticle.autoRemoveOnFinish = YES;
            
            coin.curParticle = coinParticle;
            coin.curParticleToFollow = YES;
            
            [game addChild:coin z:kCoinZ];
            [game addChild:coinParticle z:kCoinParticleZ];
            
            float duration = 1.0 + 0.5 *i;
            
            [coin runAction:[CCSequence actions:[CCSpawn actions:[CCSequence actions:[CCScaleTo actionWithDuration:0.05 scale:0.3], [CCScaleTo actionWithDuration:1.45 scale:0.1],nil],[CCMoveTo actionWithDuration:duration position:ccp(abs(game.position.x),kWinHeight)],nil],
                             [CCCallFuncND actionWithTarget:game selector:@selector(coinStop:) data:coin],
                             nil]];
        }

        CCActionInterval * targetDying = [CCSpawn actions:
                                            [CCScaleTo actionWithDuration:1.5 scale:0.1],
                                            [CCFadeOut actionWithDuration:1.5],
                                            nil];

        
        [actor runAction:[CCSequence actions:targetDying,[CCCallFuncO actionWithTarget:game selector:@selector(targetDone:) object:actor], nil]];
        
        
        if([actor countType] == kCountLimitFinity)
            [[game levelLoader] increaseActorCountWithName:actor.name count:1 delay:2.0];
         
        //Actor's shape is added by LevelLoader.So use LevelLoader to remove it.
        [[game levelLoader] removeShapeOfActor:actor];
        
        /*The memory address of actor.shape will be reused. so set it nil will avoid making messy 
         before it is removed by game.*/
        actor.shape = nil;
        
    }

}


@interface GameLayer (PrivateMethods)
- (void) handleCollisionWithTarget:(CollisionMoment)moment arbiter:(cpArbiter*)arb space:(cpSpace*)space;
@end


@implementation GameLayer

@synthesize gameTime = _gameTime;
@synthesize levelLoader = _levelLoader;

@synthesize spaceManager = _spaceManager;
@synthesize space = _space;

@synthesize parallaxNode = _parallaxNode;

@synthesize background = _background;

@synthesize currentLevel = _currentLevel;

@synthesize actorsArray = _actorsArray;
@synthesize bulletsArray = _bulletsArray;


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
    _winSize = [[CCDirector sharedDirector] winSize];
    
    
    gameHUD = [GameHUD sharedHUD];
    [gameHUD schedule:@selector(updateMoney) interval: 2.0];
    
	_spaceManager = [[SpaceManagerCocos2d alloc] init];
	_spaceManager.constantDt = 1.0/55.0;
    _spaceManager.damping = 1.0;
    _spaceManager.rehashStaticEveryStep = YES;
    
    self.space = [_spaceManager space];
    
    cpShape * bottom = [_spaceManager addSegmentAt:ccp(kWinWidth/2,0) fromLocalAnchor:ccp(-kWinWidth*2, 0) toLocalAnchor:ccp(kWinWidth*2, 1) mass:INFINITY radius:10];
    cpShapeTextureNode * ground = [cpShapeTextureNode nodeWithShape:bottom file:@"rope.png"]; 
    [self addChild:ground z:0 tag:0];
    
    _actorsArray = [[NSMutableArray alloc] init];
    _bulletsArray = [[NSMutableArray alloc] init];
    _deadActorsSet = [[NSMutableSet alloc] init];
    _deadBulletsSet = [[NSMutableSet alloc] init];
    
    _trajectoryDict = [[NSMutableDictionary alloc] init];
    _trajectory = nil;
    
    //Load TiledMAP/BatchNode/....
    _levelLoader = [[riLevelLoader alloc] initWithContentOfFile:@"Level0"];
    _levelLoader.spaceManager = _spaceManager;
    _levelLoader.space = _space;
    _levelLoader.gameLayer = self;
    [_levelLoader addEverythingToSpaceAndGameLayer];
    
    _tiledMaps = [DataModel sharedDataModel].tiledMaps;
    _background = [[[_tiledMaps objectAtIndex:0] objectForKey:@"TiledMap"] layerNamed:@"Background"];

    
    _parallaxNode = [CCParallaxNode node];
    for(NSDictionary * tm in _tiledMaps){
        CCTMXTiledMap * tiledMap = [tm objectForKey:@"TiledMap"];
        int z = [[tm objectForKey:@"OrderZ"] intValue];
        CGPoint ratio = CGPointFromString([tm objectForKey:@"Ratio"]);
        CGPoint offset = CGPointFromString([tm objectForKey:@"Offset"]);
        tiledMap.tag = z;
        [_parallaxNode addChild:tiledMap z:z parallaxRatio:ratio positionOffset:offset];
    }

    [self addChild:_parallaxNode z:kParallaxNodeZ tag:kParallaxNodeTag];
    
    self.position = ccp(0,0);

    ropeSegmentSpriteBatchNode = [CCSpriteBatchNode batchNodeWithFile:@"rope.png" ]; 
    [ropeSegmentSpriteBatchNode retain];
    [self addChild:ropeSegmentSpriteBatchNode z:10]; 

    self.currentLevel = 0;

    
	CCMenuItemFont *back = [CCMenuItemFont itemFromString:@"back" target:self selector: @selector(back:)];
	CCMenu *menu = [CCMenu menuWithItems: back, nil];
	menu.position = ccp(160, 150);
	[gameHUD addChild: menu];
    
    
    
    [self schedule:@selector(update:)];
    [self schedule:@selector(gameLogic:) interval:0.1];	
    
    [_spaceManager addCollisionCallbackBetweenType:kButterflyCollisionType 
								otherType:kBulletCollisionType 
								   target:self 
								 selector:@selector(handleCollisionWithTarget:arbiter:space:)
                                  moments:COLLISION_BEGIN, nil];

    
	[_spaceManager start]; 
    
	return self;
}

- (void) dealloc
{
    [_spaceManager stop];

    self.levelLoader = nil;
    
    [self removeAllChildrenWithCleanup:YES];

    [verletRope release];
    verletRope = nil;

    [ropeSegmentSpriteBatchNode release];
    ropeSegmentSpriteBatchNode = nil;

    [_spaceManager release];
    _spaceManager = nil;
    
    
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
    
    
    [[DataModel sharedDataModel].waypoints removeAllObjects];
    [[DataModel sharedDataModel].tiledMaps removeAllObjects];


    [[gameHUD joystick] resetJoystick];
    
    [_actorsArray release];
    _actorsArray = nil;
    
    [_bulletsArray release];
    _bulletsArray = nil;
    
    [_deadActorsSet release];
    _deadActorsSet = nil;
    
    [_deadBulletsSet release];
    _deadBulletsSet = nil;
    
    [_trajectoryDict release];
    _trajectoryDict = nil;

	[super dealloc];
}

- (void) addBackgroundParticle
{
    CCParticleSystemQuad * dandelionParticle = [CCParticleSystemQuad particleWithFile:@"DandelionParticle.plist"];
    dandelionParticle.position = ccp(_winSize.width/2,_winSize.height/2);
    dandelionParticle.autoRemoveOnFinish = YES;
    [self addChild:dandelionParticle z:kDandelionParticleZ];
}

-(void)gameLogic:(ccTime)dt {

    _gameTime = _gameTime + dt;
    [_levelLoader step];
}

- (void)update:(ccTime)dt {
    if(verletRope != nil)
        [verletRope update:dt];
}


- (CGPoint)boundLayerPos:(CGPoint)newPos tiledMap:(CCTMXTiledMap*)tiledMap {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CGPoint retval = newPos;
    retval.x = MIN(retval.x, 0);
    retval.x = MAX(retval.x, -tiledMap.contentSize.width+winSize.width); 
    retval.y = MIN(0, retval.y);
    retval.y = MAX(-tiledMap.contentSize.height+winSize.height, retval.y); 
    return retval;
}

- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
    CCTMXTiledMap * tiledMap = [[_tiledMaps objectAtIndex:0] objectForKey:@"TiledMap"];
    if (recognizer.state == UIGestureRecognizerStateBegan) {    
        CGPoint touchLocation = [recognizer locationInView:recognizer.view];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];                
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {    
        CGPoint translation = [recognizer translationInView:recognizer.view];
        translation = ccp(translation.x, -translation.y);
        CGPoint newPos = ccpAdd(self.position, translation);
        self.position = [self boundLayerPos:newPos tiledMap:tiledMap ];  
        [recognizer setTranslation:CGPointZero inView:recognizer.view];    
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
		float scrollDuration = 0.2;
		CGPoint velocity = [recognizer velocityInView:recognizer.view];
		CGPoint newPos = ccpAdd(self.position, ccpMult(ccp(velocity.x, velocity.y * -1), scrollDuration));
		newPos = [self boundLayerPos:newPos tiledMap:tiledMap];
        
		[self stopAllActions];
		CCMoveTo *moveTo = [CCMoveTo actionWithDuration:scrollDuration position:newPos];            
		[self runAction:[CCEaseOut actionWithAction:moveTo rate:1]];            
        
    }        
}

-(void)draw{
	[super draw];
    if(verletRope != nil)
        [verletRope updateSprites];
}

-(void) back: (id) sender{
	[SceneManager goMenu];
}

-(void) bulletStop:(riActor*)bullet{
    if(bullet != nil){
        [_bulletsArray removeObject:bullet];
        [_actorsArray removeObject:bullet];
        [_levelLoader removeSpriteOfActor:bullet];
    }else {
        NSLog(@"NIL BULLET...............");
    }
}

-(void) targetDone:(riActor*)actor{
    if(actor != nil){
        [[GameHUD sharedHUD] updateMoney:actor.score];
        [_actorsArray removeObject:actor];
        [_levelLoader removeSpriteOfActor:actor];
    }else {
        NSLog(@"NIL ACTOR...............");
    }
}

-(void) coinStop:(riActor*)coin{
    [self removeChild:coin cleanup:YES];
}

#pragma mark Touch Functions
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{	
    for(UITouch* t in touches) {
        if(_actorsArray != nil && [_actorsArray count] > 0){
            for(riActor * a in _actorsArray){
                if ([a touchedInLayer:self withTouchs:touches]) {
                    if ([[a actorType] isEqualToString:@"Bullet"]) {
                        a.actorType = @"Bullet_Firing";
                        a.currentTouch = t;
                        [_bulletsArray addObject:a];
                        break;
                    }
                }
            }
        }
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{	    
    for(UITouch* t in touches) {
        CGPoint pt = [self convertTouchToNodeSpace:t];        
        if(_bulletsArray != nil && [_bulletsArray count] > 0){
            for(riActor * b in _bulletsArray){
                if (b.currentTouch == t && [[b actorType] isEqualToString:@"Bullet_Firing"]) {
                    CGPoint direction = cpvsub(kBulletAnchorPosition, pt);
                    float length = ccpLength(direction);
                    CGPoint pos = pt;
                    if (length > kBulletLength) {
                        direction = ccpMult(direction, kBulletLength/length);
                        length = kBulletLength;
                        pos = ccpSub(kBulletAnchorPosition, direction);
                    }
                    
                    float rot = -CC_RADIANS_TO_DEGREES(cpvtoangle(direction));
                    float scale = length/kBulletLength;
                    
                    b.position = pos;;
                    CCSprite * trajectory = [_trajectoryDict objectForKey:b.signiture];
                    if(trajectory == nil){
                        trajectory = [CCSprite spriteWithFile:@"trajectory.png"];
                        trajectory.anchorPoint = ccp(0,0.5);
                        trajectory.position = pos;;
                        trajectory.rotation = rot; 
                        trajectory.scaleX = scale;
                        [_trajectoryDict setObject:trajectory forKey:b.signiture];
                        [self addChild:trajectory];
                    }else {
                        trajectory.position = pos;
                        trajectory.rotation = rot;
                        trajectory.scaleX = scale;
                    }
                }         
            }
        }
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{	

//    CGPoint pt = [self convertTouchToNodeSpace:[touches anyObject]];
//    _touchEndPos = pt;
//    _touchEndTime = [[NSDate date] timeIntervalSince1970];

//    float touchTime = _touchEndTime - _touchBeginTime;
//    if (touchTime < 0.001) touchTime = 0.001;
    
//    if(touchDistance < kFingerNoMovementFactor){
//                
////        [gameHUD updateMoney:bullet.score - 1];
//        
//        CCParticleSystemQuad * bulletParticle = [CCParticleSystemQuad particleWithFile:@"BulletParticle.plist"];
//        bulletParticle.position = _touchEndPos;
//        bulletParticle.autoRemoveOnFinish = YES;
//        [self addChild:bulletParticle z:kBulletParticleZ];
//
//    }else{
//    }
    for(UITouch* t in touches) {
        for(riActor * b in _bulletsArray){
            if(b.currentTouch == t && [[b actorType] isEqualToString:@"Bullet_Firing"]){
                b.actorType = @"Bullet_Fired";
                cpShape * bulletShape = [_spaceManager addCircleAt:b.position mass:1 radius:16];
                bulletShape->collision_type = kBulletCollisionType;
                bulletShape->group = 1;
                
                /*We have to set body and shape BOTH.Because this will point body and shape's data to Bullet,
                which is very important for collision callback to use the bullet object.*/
                b.body = bulletShape->body;
                b.shape = bulletShape;

                CGPoint direction = cpvsub(kBulletAnchorPosition, b.position);
                float length = ccpLength(direction);
                if (length > kBulletLength) {
                    direction = ccpMult(direction, kBulletLength/length);
                }                
                
                [b applyImpulse:cpvmult(direction,5)];
                
                CCSprite * trajectory = [_trajectoryDict objectForKey:b.signiture];
                if(trajectory != nil && [[self children] containsObject:trajectory]){
                    [_trajectoryDict removeObjectForKey:b.signiture];
                    [self removeChild:trajectory cleanup:YES];
                    trajectory = nil;
                }
                //[self runAction:[CCScaleTo actionWithDuration:2 scale:0.5]];
                //[self runAction:[CCFollow actionWithTarget:b]];
            }
        }
    }
}

- (void) handleCollisionWithTarget:(CollisionMoment)moment arbiter:(cpArbiter*)arb space:(cpSpace*)space
{	
    //Because some bodies have multi_shapes.We need the body to handle collision.
    CP_ARBITER_GET_BODIES(arb,a,b);
    
    riActor * actor = (riActor *)a->data;
    riActor * bullet = (riActor *)b->data;

    if (actor != nil && bullet !=nil && ![bullet.actorType isEqualToString:@"Bullet_Stop"]) {
        bullet.actorType = @"Bullet_Stop";
        cpSpaceAddPostStepCallback(_space, targetCallback, a->data, self);
        cpSpaceAddPostStepCallback(_space, bulletCallback, b->data, self);
        actor.damage = actor.damage + bullet.power;
        //    bullet.score ++;

    }


    
}



@end