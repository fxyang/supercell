//
//  GameHUD.m
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GameHUD.h"
#import "DataModel.h"
#import "GameLayer.h"

@implementation GameHUD

@synthesize resources = resources;
@synthesize baseHpPercentage = baseHpPercentage;

int waveCount;


static GameHUD *_sharedHUD = nil;

+ (GameHUD *)sharedHUD
{
	@synchronized([GameHUD class])
	{
		if (!_sharedHUD)
			[[self alloc] init];
		return _sharedHUD;
	}
	// to avoid compiler warning
	return nil;
}

+(id)alloc
{
	@synchronized([GameHUD class])
	{
		NSAssert(_sharedHUD == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedHUD = [super alloc];
		return _sharedHUD;
	}
	// to avoid compiler warning
	return nil;
}

-(id) init
{
	if ((self=[super init]) ) {
		
		CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGB565];
        background = [CCSprite spriteWithFile:@"hud.png"];
        background.anchorPoint = ccp(0,0);
        [self addChild:background];
        [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_Default];
		
        movableSprites = [[NSMutableArray alloc] init];
        NSArray *images = [NSArray arrayWithObjects:@"MachineGunTurret.png", @"FreezeTurret.png", @"MachineGunTurret.png", @"MachineGunTurret.png", nil];  
        for(int i = 0; i < images.count; ++i) {
            NSString *image = [images objectAtIndex:i];
            CCSprite *sprite = [CCSprite spriteWithFile:image];
            float offsetFraction = ((float)(i+1))/(images.count+1);
            sprite.position = ccp(winSize.width*offsetFraction, 35);
            sprite.tag = i+1;
            printf("tag %i", sprite.tag);
            [self addChild:sprite];
            [movableSprites addObject:sprite];
            
            //Set up and place towerCost labels
            CCLabelTTF *towerCost = [CCLabelTTF labelWithString:@"$" fontName:@"Marker Felt" fontSize:10];
            towerCost.position = ccp(winSize.width*offsetFraction, 15);
            towerCost.color = ccc3(0, 0, 0);
            [self addChild:towerCost z:1];
            
            //Set cost values
            switch (i) {
                case 0:
                    [towerCost setString:[NSString stringWithFormat:@"$ 25"]];
                    break;
                case 1:
                    [towerCost setString:[NSString stringWithFormat:@"$ 35"]];
                    break;
                case 2:
                    [towerCost setString:[NSString stringWithFormat:@"$ 25"]];
                    break;
                case 3:
                    [towerCost setString:[NSString stringWithFormat:@"$ 25"]];
                    break;
                default:
                    break;
            }
        }
        
        
        //CGSize winSize = [CCDirector sharedDirector].winSize;
        
        // Set up Resources and Resource label
        resources = 100;
        self->resourceLabel = [CCLabelTTF labelWithString:@"Money $100" dimensions:CGSizeMake(150, 25) alignment:UITextAlignmentRight fontName:@"Marker Felt" fontSize:20];
        resourceLabel.position = ccp(30, (winSize.height - 15));
        resourceLabel.color = ccc3(255,80,20);
        [self addChild:resourceLabel z:1];
        
        // Set up BaseHplabel
        CCLabelTTF *baseHpLabel = [CCLabelTTF labelWithString:@"Base Health" dimensions:CGSizeMake(150, 25) alignment:UITextAlignmentRight fontName:@"Marker Felt" fontSize:20];
        baseHpLabel.position = ccp((winSize.width - 185), (winSize.height - 15));
        baseHpLabel.color = ccc3(255,80,20);
        [self addChild:baseHpLabel z:1];
        
        // Set up wavecount label
        waveCount = 1;
        self->waveCountLabel = [CCLabelTTF labelWithString:@"Wave 1" dimensions:CGSizeMake(150, 25) alignment:UITextAlignmentRight fontName:@"Marker Felt" fontSize:20];
        waveCountLabel.position = ccp(((winSize.width/2) - 80), (winSize.height - 15));
        waveCountLabel.color = ccc3(100,0,100);
        [self addChild:waveCountLabel z:1];
        
        baseHpPercentage = 100;
        
        //Set up helth Bar
        self->healthBar = [CCProgressTimer progressWithFile:@"health_bar_green.png"];
        self->healthBar.type = kCCProgressTimerTypeHorizontalBarLR;
        self->healthBar.percentage = baseHpPercentage;
        [self->healthBar setScale:0.5]; 
        self->healthBar.position = ccp(winSize.width -55, winSize.height -15);
        [self addChild:healthBar z:1];
        
        
        [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
	}
    
    
    return self;
}

-(void) updateBaseHp:(int)amount{
    baseHpPercentage += amount;
    
    if (baseHpPercentage <= 25) {
        [self->healthBar setSprite:[CCSprite spriteWithFile:@"health_bar_red.png"]];
        [self->healthBar setScale:0.5]; 
    }
    
    if (baseHpPercentage <= 0) {
        //Game Over Scenario
        printf("Game Over\n");
        //Implement Game Over Scenario
    }
    
    [self->healthBar setPercentage:baseHpPercentage];
}

-(void) updateResources:(int)amount{
    resources += amount;
    [self->resourceLabel setString:[NSString stringWithFormat: @"Money $%i",resources]];
}

-(void) updateResourcesNom{
    resources += 1;
    [self->resourceLabel setString:[NSString stringWithFormat: @"Money $%i",resources]];
}
-(void) updateWaveCount{
    waveCount++;
    [self->waveCountLabel setString:[NSString stringWithFormat: @"Wave %i",waveCount]];
}


- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {  
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    CCSprite * newSprite = nil;
    for (CCSprite *sprite in movableSprites) {
        if (CGRectContainsPoint(sprite.boundingBox, touchLocation)) {  
			DataModel *m = [DataModel getModel];
			m._gestureRecognizer.enabled = NO;
			
			selSpriteRange = [CCSprite spriteWithFile:@"Range.png"];
			selSpriteRange.scale = 4;
			[self addChild:selSpriteRange z:-1];
			selSpriteRange.position = sprite.position;
			
            newSprite = [CCSprite spriteWithTexture:[sprite texture]]; //sprite;
			newSprite.position = sprite.position;
			selSprite = newSprite;
            selSprite.tag = sprite.tag;
			[self addChild:newSprite];
			
            break;
        }
    }     
	return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {  
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    
    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
    oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    CGPoint translation = ccpSub(touchLocation, oldTouchLocation);    
	
	if (selSprite) {
		CGPoint newPos = ccpAdd(selSprite.position, translation);
        selSprite.position = newPos;
		selSpriteRange.position = newPos;
		
		DataModel *m = [DataModel getModel];
		CGPoint touchLocationInGameLayer = [m._gameLayer convertTouchToNodeSpace:touch];
		
		BOOL isBuildable = [(GameLayer *)m._gameLayer canBuildOnTilePosition: touchLocationInGameLayer];
		if (isBuildable) {
			selSprite.opacity = 200;
		} else {
			selSprite.opacity = 50;		
		}
	}
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {  
	CGPoint touchLocation = [self convertTouchToNodeSpace:touch];	
	DataModel *m = [DataModel getModel];
    
	if (selSprite) {
		CGRect backgroundRect = CGRectMake(background.position.x, 
                                           background.position.y, 
                                           background.contentSize.width, 
                                           background.contentSize.height);
		
		if (!CGRectContainsPoint(backgroundRect, touchLocation)) {
			CGPoint touchLocationInGameLayer = [m._gameLayer convertTouchToNodeSpace:touch];
			[(GameLayer *)m._gameLayer addTower: touchLocationInGameLayer: selSprite.tag];
		}
		
		[self removeChild:selSprite cleanup:YES];
		selSprite = nil;		
		[self removeChild:selSpriteRange cleanup:YES];
		selSpriteRange = nil;			
	}
	
	m._gestureRecognizer.enabled = YES;
}
- (void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	[movableSprites release];
    movableSprites = nil;
	[super dealloc];
}
@end

