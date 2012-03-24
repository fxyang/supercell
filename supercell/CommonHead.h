//
//  CommonHead.h
//  supercell
//
//  Created by Feixue Yang on 12-02-04.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef supercell_CommonHead_h
#define supercell_CommonHead_h

#import <Foundation/Foundation.h>
#import "SpaceManagerCocos2d.h"
#import "chipmunk.h"
#import "cocos2d.h"

#import "SceneManager.h"
#import "BaseLayer.h"
#import "DataModel.h"
#import "GameHUD.h"

#endif

//int seglen = 20;
//int segno = 0;
//segno = cpvdist(_touchEndPos, _touchBeginPos) / seglen;
//if(segno >0){
//    if(_curSeg != nil){
//        [_spaceManager removeAndFreeShape:[_curSeg shape]];
//        [self removeChild:_curSeg cleanup:YES];
//        _curSeg = nil;
//        NSLog(@"seg removed");
//
//    }
//    cpShape * seg = [_spaceManager addSegmentAtWorldAnchor:_touchBeginPos toWorldAnchor:_touchEndPos mass:STATIC_MASS radius:10];
//    seg->e = 1.5;
//    cpShapeNode * segNode = [cpShapeNode nodeWithShape:seg];
//    [self addChild:segNode z:11];
//    _curSeg = segNode;
//}