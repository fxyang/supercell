//
//  riRollingTiledMap.h
//  supercell
//
//  Created by Feixue Yang on 12-03-02.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@class riActor;

typedef enum {	
	kTagBackground = 20,
	kTagBackgroundTileMap = 22,
	kTagBackgroundTileMapX = 23,
	kTagBackgroundTileMapY = 24,
	kTagBackgroundTileMapXY = 25,
    
} ObjectTag;

@interface riRollingTiledMap : CCLayer {
    
    ObjectTag currentBackgroundMap;
    CGPoint backgroundMapCenter;
    ObjectTag currentForegroundMap;
    CGPoint foregroundMapCenter;
    int tilemapRepeat;
    riActor * hero;

}



-(void) loadTiledMap;

- (void) backgroundTileMapNode:(CCTMXTiledMap *)node 
                         nodeX:(CCTMXTiledMap *)nodeX 
                         nodeY:(CCTMXTiledMap *)nodeY
                        nodeXY:(CCTMXTiledMap *)nodeXY 
              RepeatWithPlayer:(riActor *)player;

@end
