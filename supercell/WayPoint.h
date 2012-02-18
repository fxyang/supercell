//
//  WayPoint.h
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface WayPoint : CCNode {
    NSString * _wayPointName;
    
    WayPoint * _nextWayPoint;
    CGFloat _travelSpeed;
    CCAnimation * _travelAnimation;
    CCAction * _travelAction;
    
}
@property (nonatomic, retain) NSString * wayPointName;
@property (nonatomic, retain) WayPoint * nextWayPoint;
@property (nonatomic, assign) CGFloat travelSpeed;
@property (nonatomic, retain) CCAnimation * travelAnimation;
@property (nonatomic, retain) CCAction * travelAction;


-(WayPoint *) initWithWayPointName:(NSString *) name_;
@end