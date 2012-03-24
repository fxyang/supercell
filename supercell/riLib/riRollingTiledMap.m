//
//  riRollingTiledMap.m
//  supercell
//
//  Created by Feixue Yang on 12-03-02.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "riRollingTiledMap.h"

@implementation riRollingTiledMap

-(id) init{
	self = [super init];
	if (!self) {
		return nil;
	}
    return self;
}

-(void) loadTiledMap
{
    backgroundMapCenter = CGPointZero;
    
    CCTMXTiledMap * rollingTiledMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap_Foreground.tmx"];
    CCTMXTiledMap * rollingTiledMapX = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap_Foreground.tmx"];
    CCTMXTiledMap * rollingTiledMapY = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap_Foreground.tmx"];
    CCTMXTiledMap * rollingTiledMapXY = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap_Foreground.tmx"];
    
    [self addChild:rollingTiledMap z:1 tag:kTagBackgroundTileMap];
    
    CGPoint mapAnchorPoint = ccp(0,0);
	if(rollingTiledMap)
	{
		CCTMXTiledMap * tm = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMap];
		if( !tm )
			[self addChild:rollingTiledMap z:1 tag:kTagBackgroundTileMap];
		else if(tm != rollingTiledMap)
		{
			[self removeChild:tm cleanup:YES];
			[self addChild:rollingTiledMap z:1 tag:kTagBackgroundTileMap];
		}
		rollingTiledMap.anchorPoint = mapAnchorPoint;
		[rollingTiledMap setPosition:backgroundMapCenter];
		
		CCTMXTiledMap * tileMapX = rollingTiledMapX;
		CCTMXTiledMap * tileMapY = rollingTiledMapY;
		CCTMXTiledMap * tileMapXY = rollingTiledMapXY;
		
		CGFloat mapWidth = [rollingTiledMap mapSize].width * [rollingTiledMap tileSize].width;
		CGFloat mapHeight = [rollingTiledMap mapSize].height * [rollingTiledMap tileSize].height;
		
		if(tileMapX)
		{
			CCTMXTiledMap * tmx = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapX];
			if(!tmx)
				[self addChild:tileMapX z:1 tag:kTagBackgroundTileMapX];
			else if(tmx != tileMapX)
			{
				[self removeChild:tmx cleanup:YES];
				[self addChild:tileMapX z:1 tag:kTagBackgroundTileMapX];
			}
			tileMapX.anchorPoint = mapAnchorPoint;
			[tileMapX setPosition:ccpAdd(backgroundMapCenter, ccp(mapWidth,0))];
		}
		if(tileMapY)
		{
			CCTMXTiledMap * tmy = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapY];
			if(!tmy)
				[self addChild:tileMapY z:1 tag:kTagBackgroundTileMapY];
			else if(tmy != tileMapY)
			{
				[self removeChild:tmy cleanup:YES];
				[self addChild:tileMapY z:1 tag:kTagBackgroundTileMapY];
			}
			tileMapY.anchorPoint = mapAnchorPoint;
			[tileMapY setPosition:ccpAdd(backgroundMapCenter, ccp(0,mapHeight))];
		}
		if(tileMapXY)
		{
			CCTMXTiledMap * tmxy = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapXY];
			if(!tmxy)
				[self addChild:tileMapXY z:1 tag:kTagBackgroundTileMapXY];
			else if(tmxy != tileMapXY)
			{
				[self removeChild:tmxy cleanup:YES];
				[self addChild:tileMapXY z:1 tag:kTagBackgroundTileMapXY];
			}
			tileMapXY.anchorPoint = mapAnchorPoint;
			[tileMapXY setPosition:ccpAdd(backgroundMapCenter, ccp(mapWidth,mapHeight))];
		}
	}
    
	
	tilemapRepeat = 1;
	
	//			for( TMXLayer* child in [ftileMapXY children] ) 
	//				[[child texture] setAntiAliasTexParameters];
    
}


- (void) backgroundTileMapNode:(CCTMXTiledMap *)node 
						 nodeX:(CCTMXTiledMap *)nodeX 
						 nodeY:(CCTMXTiledMap *)nodeY
						nodeXY:(CCTMXTiledMap *)nodeXY 
			  RepeatWithPlayer:(riActor *)player 
{
	NSAssert(node != nil,@"At least a TMXTileMap is needed for using tileMapRepeatWithPlay: !");
	
	CGFloat mapWidth = [node mapSize].width * [node tileSize].width;
	CGFloat mapHeight = [node mapSize].height * [node tileSize].height;
	CGPoint playerPos = [player position];
	
	CGPoint playerOffset = ccpSub(playerPos, backgroundMapCenter);
	CGFloat ox = fabs(playerOffset.x);
	CGFloat oy = fabs(playerOffset.y);
	
	if(node && nodeX && nodeY && nodeXY)
	{
		if(ox > mapWidth/2.0 && oy > mapHeight/2.0)
		{
			if(currentBackgroundMap == kTagBackgroundTileMap)
				currentBackgroundMap = kTagBackgroundTileMapXY;
			else if(currentBackgroundMap == kTagBackgroundTileMapX)
				currentBackgroundMap = kTagBackgroundTileMapY;
			else if(currentBackgroundMap == kTagBackgroundTileMapY)
				currentBackgroundMap = kTagBackgroundTileMapX;
			else if(currentBackgroundMap == kTagBackgroundTileMapXY)
				currentBackgroundMap = kTagBackgroundTileMap;
		}
		else if(ox > mapWidth/2.0 && oy <= mapHeight/2.0)
		{
			
			if(currentBackgroundMap == kTagBackgroundTileMap)
				currentBackgroundMap = kTagBackgroundTileMapX;
			else if(currentBackgroundMap == kTagBackgroundTileMapX)
				currentBackgroundMap = kTagBackgroundTileMap;
			else if(currentBackgroundMap == kTagBackgroundTileMapY)
				currentBackgroundMap = kTagBackgroundTileMapXY;
			else if(currentBackgroundMap == kTagBackgroundTileMapXY)
				currentBackgroundMap = kTagBackgroundTileMapY;
		}
		else if(ox <= mapWidth/2.0 && oy > mapHeight/2.0)
		{
			if(currentBackgroundMap == kTagBackgroundTileMap)
				currentBackgroundMap = kTagBackgroundTileMapY;
			else if(currentBackgroundMap == kTagBackgroundTileMapX)
				currentBackgroundMap = kTagBackgroundTileMapXY;
			else if(currentBackgroundMap == kTagBackgroundTileMapY)
				currentBackgroundMap = kTagBackgroundTileMap;
			else if(currentBackgroundMap == kTagBackgroundTileMapXY)
				currentBackgroundMap = kTagBackgroundTileMapX;
		}
		else if(ox <= mapWidth/2.0 && oy <= mapHeight/2.0)
		{
		}
		
		backgroundMapCenter = [(CCTMXTiledMap *)[self getChildByTag:currentBackgroundMap] position];
		
		
		if(currentBackgroundMap == kTagBackgroundTileMap)
		{
			node = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMap];
			nodeX = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapX];
			nodeY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapY];
			nodeXY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapXY];
		}
		else if(currentBackgroundMap == kTagBackgroundTileMapX)
		{
			node = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapX];
			nodeX = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMap];
			nodeY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapXY];
			nodeXY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapY];
		}
		else if(currentBackgroundMap == kTagBackgroundTileMapY)
		{
			node = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapY];
			nodeX = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapXY];
			nodeY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMap];
			nodeXY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapX];
		}
		else if(currentBackgroundMap == kTagBackgroundTileMapXY)
		{
			node = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapXY];
			nodeX = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapY];
			nodeY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapX];
			nodeXY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMap];
		}
		
		
		CGPoint newPlayerOffset = ccpSub(playerPos, backgroundMapCenter);
		CGFloat nox = newPlayerOffset.x;
		CGFloat noy = newPlayerOffset.y;
		
		
		if(nox > 0 && noy > 0)
		{
			[nodeX setPosition:ccpAdd(backgroundMapCenter, ccp(mapWidth,0))];
			[nodeY setPosition:ccpAdd(backgroundMapCenter, ccp(0,mapHeight))];
			[nodeXY setPosition:ccpAdd(backgroundMapCenter, ccp(mapWidth,mapHeight))];
		}
		else if(nox > 0 && noy <= 0)
		{
			[nodeX setPosition:ccpAdd(backgroundMapCenter, ccp(mapWidth,0))];
			[nodeY setPosition:ccpAdd(backgroundMapCenter, ccp(0,-mapHeight))];
			[nodeXY setPosition:ccpAdd(backgroundMapCenter, ccp(mapWidth,-mapHeight))];
		}
		else if(nox <= 0 && noy > 0)
		{
			[nodeX setPosition:ccpAdd(backgroundMapCenter, ccp(-mapWidth,0))];
			[nodeY setPosition:ccpAdd(backgroundMapCenter, ccp(0,mapHeight))];
			[nodeXY setPosition:ccpAdd(backgroundMapCenter, ccp(-mapWidth, mapHeight))];
		}
		else if(nox <= 0 && noy <= 0)
		{
			[nodeX setPosition:ccpAdd(backgroundMapCenter, ccp(-mapWidth,0))];
			[nodeY setPosition:ccpAdd(backgroundMapCenter, ccp(0,-mapHeight))];
			[nodeXY setPosition:ccpAdd(backgroundMapCenter, ccp(-mapWidth,-mapHeight))];
		}
	}
	else if(node && nodeX && !nodeY)
	{
		if(ox > mapWidth/2.0)
		{
			if(currentBackgroundMap == kTagBackgroundTileMap)
				currentBackgroundMap = kTagBackgroundTileMapX;
			else if(currentBackgroundMap == kTagBackgroundTileMapX)
				currentBackgroundMap = kTagBackgroundTileMap;
		}
		
		backgroundMapCenter = [(CCTMXTiledMap *)[self getChildByTag:currentBackgroundMap] position];
		
		if(currentBackgroundMap == kTagBackgroundTileMap)
		{
			node = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMap];
			nodeX = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapX];
		}
		else if(currentBackgroundMap == kTagBackgroundTileMapX)
		{
			node = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapX];
			nodeX = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMap];
		}
		
		CGPoint newPlayerOffset = ccpSub(playerPos, backgroundMapCenter);
		CGFloat nox = newPlayerOffset.x;
		if(nox > 0)
			[nodeX setPosition:ccpAdd(backgroundMapCenter, ccp(mapWidth,0))];
		else if(nox <= 0)
			[nodeX setPosition:ccpAdd(backgroundMapCenter, ccp(-mapWidth,0))];
	}
	else if(node && nodeY && !nodeX )
	{
		if(oy > mapWidth/2.0)
		{
			if(currentBackgroundMap == kTagBackgroundTileMap)
				currentBackgroundMap = kTagBackgroundTileMapY;
			else if(currentBackgroundMap == kTagBackgroundTileMapY)
				currentBackgroundMap = kTagBackgroundTileMap;
		}
		
		backgroundMapCenter = [(CCTMXTiledMap *)[self getChildByTag:currentBackgroundMap] position];
		
		if(currentBackgroundMap == kTagBackgroundTileMap)
		{
			node = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMap];
			nodeY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapY];
		}
		else if(currentBackgroundMap == kTagBackgroundTileMapY)
		{
			node = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapY];
			nodeY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMap];
		}
		
		CGPoint newPlayerOffset = ccpSub(playerPos, backgroundMapCenter);
		CGFloat noy = newPlayerOffset.y;
		if(noy > 0)
			[nodeY setPosition:ccpAdd(backgroundMapCenter, ccp(0,mapHeight))];
		else if(noy <= 0)
			[nodeY setPosition:ccpAdd(backgroundMapCenter, ccp(0,-mapHeight))];
	}
	else if(node && !nodeX && !nodeY)
	{
	}
	else
		NSLog(@"Check TMXTileMap Setting!");
}

- (void)update:(ccTime)dt {
    
    CCTMXTiledMap * node = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMap];
    if(node && tilemapRepeat == 1)
    {
        CCTMXTiledMap * nodeX = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapX];
        CCTMXTiledMap * nodeY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapY];
        CCTMXTiledMap * nodeXY = (CCTMXTiledMap *)[self getChildByTag:kTagBackgroundTileMapXY];
        [self backgroundTileMapNode:node nodeX:nodeX nodeY:nodeY nodeXY:nodeXY RepeatWithPlayer:hero];
    }
    
    
    
}

@end
