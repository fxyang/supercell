//
//  riConstraintNode.m
//  supercell
//
//  Created by Feixue Yang on 12-02-03.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "riVerletRope.h"

@implementation riVerletPoint

@synthesize x;
@synthesize y;

-(void)setPos:(float)argX y:(float)argY {
	x = oldx = argX;
	y = oldy = argY;
}

-(void)update{
	float tempx = x;
	float tempy = y;
    float dx = x - oldx;;
    float dy = y - oldy;;

    if(dx == 0) dx++;
    if(dy == 0) dy++;

	x += dx;
	y += dy;
	oldx = tempx;
	oldy = tempy;
}

-(void)applyGravity:(float)dt {
	y -= kRopeGravityFactor*dt; //gravity magic number
}

-(void)setX:(float)argX {
	x = argX;
}

-(void)setY:(float)argY {
	y = argY;
}

-(float)getX {
	return x;
}

-(float)getY {
	return y;
}

@end

@implementation riVerletStick


-(id)initWith:(riVerletPoint*)argA pointb:(riVerletPoint*)argB {
	if((self = [super init])) {
		pointA = argA;
		pointB = argB;
		hypotenuse = ccpDistance(ccp(pointA.x,pointA.y),ccp(pointB.x,pointB.y));
	}
	return self;
}

-(void)contract {

       	float dx = pointB.x - pointA.x;
        float dy = pointB.y - pointA.y;
        float h = ccpDistance(ccp(pointA.x,pointA.y),ccp(pointB.x,pointB.y));
        float diff = hypotenuse - h;
        float offx = (diff * dx / h) * 0.5;
        float offy = (diff * dy / h) * 0.5;
        pointA.x-=offx;
        pointA.y-=offy;
        pointB.x+=offx;
        pointB.y+=offy; 

}
-(riVerletPoint*)getPointA {
	return pointA;
}
-(riVerletPoint*)getPointB {
	return pointB;
}
@end


@interface riVerletRope(PrivateMethods)
- (BOOL) containsPoint:(cpVect)pt padding:(cpFloat)padding constraint:(cpConstraint*)constraint;
@end

@implementation riVerletRope

@synthesize gameLayer = _gameLayer;
@synthesize ropeConstraint = _ropeConstraint;
@synthesize spaceManager = _spaceManager;
@synthesize pointA = _pointA,pointB = _pointB;
@synthesize status = _status;
@synthesize ropeSegmentFactor = _ropeSegmentFactor;
@synthesize ropeLength = _ropeLength;


- (id) initWithConstraint:(cpConstraint*)c spriteSheet:(CCSpriteBatchNode*)spriteSheetArg isSolid:(BOOL)b spaceManager:smgr {
	if((self = [super init])) {
        _spaceManager = smgr;
        _ropeConstraint = c;
        _status = kRopeStatusActive;
        _ropeSegmentFactor = kRopeSegmentLengthFactorDefault;
        ropeSpriteSheet = spriteSheetArg;
        
        _pointA = c->a->p;
        _pointB = c->b->p;
        _ropeLength = ccpDistance(_pointA, _pointB);
        
        if(b)
            [self createSolidRope:c->a->p pointB:c->b->p];
        else
            [self createRope:c->a->p pointB:c->b->p];

    }
	return self;
}

-(id)initWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB spriteSheet:(CCSpriteBatchNode*)spriteSheetArg isSolid:(BOOL)b spaceManager:smgr{
	if((self = [super init])) {
        _ropeConstraint = nil;
        _spaceManager = smgr;
        _status = kRopeStatusActive;
        _ropeSegmentFactor = kRopeSegmentLengthFactorDefault;
        ropeSpriteSheet = spriteSheetArg;
        
        
        _pointA = pointA;
        _pointB = pointB;
        _ropeLength = ccpDistance(_pointA, _pointB);
        
        if(b)
            [self createSolidRope:_pointA pointB:_pointB];
        else
            [self createRope:_pointA pointB:_pointB];
	}
	return self;
}

-(void)createRope:(CGPoint)pointA pointB:(CGPoint)pointB {
	vPoints = [[NSMutableArray alloc] init];
	vSticks = [[NSMutableArray alloc] init];
	ropeSprites = [[NSMutableArray alloc] init];
	float distance = ccpDistance(pointA,pointB);
	//int segmentFactor = 30; //increase value to have less segments per rope, decrease to have more segments
	numPoints =kRopeNumOfSegmentsFactorDefault - distance/_ropeSegmentFactor;
    if(numPoints<6) numPoints = 6;
    NSLog(@"_ropeSegmentFactor = %d",_ropeSegmentFactor);

    NSLog(@"num of Points = %d",numPoints);
	CGPoint diffVector = ccpSub(pointB,pointA);

	float multiplier = distance / (numPoints-1);
	antiSagHack = 0.1f; //HACK: scale down rope points to cheat sag. set to 0 to disable, max suggested value 0.1
	for(int i=0;i<numPoints;i++) {
		CGPoint tmpVector = ccpAdd(pointA, ccpMult(ccpNormalize(diffVector),multiplier*i*(1-antiSagHack)));
		riVerletPoint *tmpPoint = [[riVerletPoint alloc] init];
		[tmpPoint setPos:tmpVector.x y:tmpVector.y];
		[vPoints addObject:tmpPoint];
	}
	for(int i=0;i<numPoints-1;i++) {
		riVerletStick *tmpStick = [[riVerletStick alloc] initWith:[vPoints objectAtIndex:i] pointb:[vPoints objectAtIndex:i+1]];
		[vSticks addObject:tmpStick];
	}
	if(ropeSpriteSheet!=nil) {
		for(int i=0;i<numPoints-1;i++) {
			riVerletPoint *point1 = [[vSticks objectAtIndex:i] getPointA];
			riVerletPoint *point2 = [[vSticks objectAtIndex:i] getPointB];
			CGPoint stickVector = ccpSub(ccp(point1.x,point1.y),ccp(point2.x,point2.y));
			float stickAngle = ccpToAngle(stickVector);
			cpCCSprite *tmpSprite = [cpCCSprite spriteWithBatchNode:ropeSpriteSheet rect:CGRectMake(0,0,multiplier,[[[ropeSpriteSheet textureAtlas] texture] pixelsHigh])];
			ccTexParams params = {GL_LINEAR,GL_LINEAR,GL_REPEAT,GL_REPEAT};
			[tmpSprite.texture setTexParameters:&params];
			[tmpSprite setPosition:ccpMidpoint(ccp(point1.x,point1.y),ccp(point2.x,point2.y))];
			[tmpSprite setRotation:-1 * CC_RADIANS_TO_DEGREES(stickAngle)];
			[ropeSpriteSheet addChild:tmpSprite];
			[ropeSprites addObject:tmpSprite];
		}
	}
}

-(void)createSolidRope:(CGPoint)pointA pointB:(CGPoint)pointB {
    [self createRope:pointA pointB:pointB];
    if(_spaceManager != nil){
        cpShape * rope = [_spaceManager addSegmentAtWorldAnchor:pointA toWorldAnchor:pointB mass:STATIC_MASS radius:5];
        rope->e =1.0;
    }

}

- (void) dealloc
{
    for(int i=0;i<numPoints;i++) {
		[[vPoints objectAtIndex:i] release];
		if(i!=numPoints-1)
			[[vSticks objectAtIndex:i] release];
	}
	[vPoints removeAllObjects];
	[vSticks removeAllObjects];
	[vPoints release];
	[vSticks release];
    if(ropeSprites != nil){
        [ropeSprites release];
        ropeSprites = nil;
    }
	[super dealloc];
}

-(void)reset {
    if(_ropeConstraint != nil){
        CGPoint pointA = ccp(_ropeConstraint->a->p.x,_ropeConstraint->a->p.y);
        CGPoint pointB = ccp(_ropeConstraint->b->p.x,_ropeConstraint->b->p.y);
        [self resetWithPoints:pointA pointB:pointB];
    }
}

-(void)resetWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB {
	float distance = ccpDistance(pointA,pointB);
	CGPoint diffVector = ccpSub(pointB,pointA);
	float multiplier = distance / (numPoints - 1);
	for(int i=0;i<numPoints;i++) {
		CGPoint tmpVector = ccpAdd(pointA, ccpMult(ccpNormalize(diffVector),multiplier*i*(1-antiSagHack)));
		riVerletPoint *tmpPoint = [vPoints objectAtIndex:i];
		[tmpPoint setPos:tmpVector.x y:tmpVector.y];
	}
}

-(void)removeRopeWithCutAt:(CGPoint)p  duration:(float)dt {
    if(_status == kRopeStatusActive || _status == kRopeStatusHide){
        
        _status = kRopeStatusRemoving;
        
        if(_ropeConstraint != nil){
            
            //add two end point shape to removing rope
            cpShape *pointAShape = [_spaceManager addCircleAt:_ropeConstraint->a->p mass:5 radius:1];
            cpCCSprite * pointASprite = [ropeSprites objectAtIndex:0];
            pointASprite.shape = pointAShape;
            pointAShape->e = 0.0;
            pointASprite.autoFreeShapeAndBody = YES;
            pointASprite.ignoreRotation = YES;
            pointASprite.spaceManager = _spaceManager;
            
            cpShape *pointBShape = [_spaceManager addCircleAt:_ropeConstraint->b->p mass:5 radius:1];
            cpCCSprite * pointBSprite = [ropeSprites objectAtIndex:numPoints-2];
            pointBShape->e = 0.0;
            pointBSprite.shape = pointBShape;
            pointBSprite.autoFreeShapeAndBody = YES;
            pointBSprite.ignoreRotation = YES;
            pointBSprite.spaceManager = _spaceManager;
            
            pointASprite.position = ccp(10,10);
            pointBSprite.position = ccp(50,20);

            //remove old constraint and rebuild new constraint
            [_spaceManager removeConstraint:_ropeConstraint];
            _ropeConstraint = nil;
     
        }
        
        //removing rope fadeout and callback
        for(int i=0;i<numPoints-1;i++) {
            cpCCSprite *tmpSprite = [ropeSprites objectAtIndex:i];
            [tmpSprite runAction:[CCSequence actions:[CCFadeOut actionWithDuration:dt],
                                  [CCCallFuncND actionWithTarget:self selector:@selector(removeSprite:data:) data:tmpSprite] ,nil]];
        }
    }
}

-(void)removeSprite:(id)node data:(cpCCSprite *)sp {
   if((sp != nil) && (ropeSpriteSheet !=nil)){
        [ropeSprites removeObject:sp];
       [ropeSpriteSheet removeChild:sp cleanup:YES];
       _status = kRopeStatusRemoved;

       if(_spaceManager != nil && _ropeConstraint != nil){
           [_spaceManager removeAndFreeConstraint:_ropeConstraint];
           _ropeConstraint = nil;
       }
       
       if(_spaceManager != nil && [sp shape] != nil){
           [_spaceManager removeShape:[sp shape]];
       }
       
       if([ropeSprites count] == 0){
           [ropeSprites release];
           ropeSprites = nil;
       }
    }
}

-(void)removeSprites {
    if(_status != kRopeStatusRemoved){
        int n = [ropeSprites count];
        for(int i=0;i<n-1;i++) {
            cpCCSprite *tmpSprite = [ropeSprites objectAtIndex:i];
            [ropeSpriteSheet removeChild:tmpSprite cleanup:YES];
            if(_spaceManager != nil  && [tmpSprite shape] != nil)
                [_spaceManager removeAndFreeShape:[tmpSprite shape]];
            [ropeSprites removeObject:tmpSprite];
            [tmpSprite release];
            tmpSprite = nil;
        }
        [ropeSprites release];
        ropeSprites = nil;
        _status = kRopeStatusRemoved;
    }
}


-(void)update:(float)dt {
    
    if(_status == kRopeStatusActive || _status == kRopeStatusHide){
        _pointA = ccp(_ropeConstraint->a->p.x,_ropeConstraint->a->p.y);
        _pointB = ccp(_ropeConstraint->b->p.x,_ropeConstraint->b->p.y);
        [self updateWithPoints:_pointA pointB:_pointB dt:dt];

    }else if (_status == kRopeStatusRemoving){
        cpCCSprite * pointASprite = [ropeSprites objectAtIndex:0];
        cpCCSprite * pointBSprite = [ropeSprites objectAtIndex:numPoints-2];
        [self updateWithPoints:[pointASprite position] pointB:[pointBSprite position] dt:dt];
    }
}

-(void)updateWithPoints:(CGPoint)pointA pointB:(CGPoint)pointB dt:(float)dt {
	//manually set position for first and last point of rope
    _pointA = pointA;
    _pointB = pointB;
	[[vPoints objectAtIndex:0] setPos:pointA.x y:pointA.y];
	[[vPoints objectAtIndex:numPoints-1] setPos:pointB.x y:pointB.y];
	
	//update points, apply gravity
	for(int i=1;i<numPoints-1;i++) {
		[[vPoints objectAtIndex:i] applyGravity:dt];
		[[vPoints objectAtIndex:i] update];
	}
	
	//contract sticks
	for(int j=0;j<kRopeNumOfIterationsFactor;j++) {
		for(int i=0;i<numPoints-1;i++) {
			[[vSticks objectAtIndex:i] contract];
		}
	}
}

-(void)updateSprites {
	if(_status != kRopeStatusRemoved && ropeSprites !=nil) {
        int n = [ropeSprites count];
		for(int i=0;i<n;i++) {
			riVerletPoint *point1 = [[vSticks objectAtIndex:i] getPointA];
			riVerletPoint *point2 = [[vSticks objectAtIndex:i] getPointB];
			CGPoint point1_ = ccp(point1.x,point1.y);
			CGPoint point2_ = ccp(point2.x,point2.y);
			float stickAngle = ccpToAngle(ccpSub(point1_,point2_));
			cpCCSprite *tmpSprite = [ropeSprites objectAtIndex:i];
			[tmpSprite setPosition:ccpMidpoint(point1_,point2_)];
			[tmpSprite setRotation: -CC_RADIANS_TO_DEGREES(stickAngle)];
		}
	}	
}

-(void)debugDraw {
	//Depending on scenario, you might need to have different Disable/Enable of Client States
	//glDisableClientState(GL_TEXTURE_2D);
	//glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	//glDisableClientState(GL_COLOR_ARRAY);
	//set color and line width for ccDrawLine
	glColor4f(0.0f,0.0f,1.0f,1.0f);
	glLineWidth(5.0f);
	for(int i=0;i<numPoints-1;i++) {
		//"debug" draw
		riVerletPoint *pointA = [[vSticks objectAtIndex:i] getPointA];
		riVerletPoint *pointB = [[vSticks objectAtIndex:i] getPointB];
		ccDrawPoint(ccp(pointA.x,pointA.y));
		ccDrawPoint(ccp(pointB.x,pointB.y));
		//ccDrawLine(ccp(pointA.x,pointA.y),ccp(pointB.x,pointB.y));
	}
	//restore to white and default thickness
	glColor4f(1.0f,1.0f,1.0f,1.0f);
	glLineWidth(1);
	//glEnableClientState(GL_TEXTURE_2D);
	//glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	//glEnableClientState(GL_COLOR_ARRAY);
}




@end