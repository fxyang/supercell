//
//  WayPoint.m
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "riTiledMapWaypoint.h"
#import "DataModel.h"
#import "riActor.h"

@interface riTiledMapWaypoint (private)
-(CCActionInterval *) initActionFromInfoDictionaryForActor:(riActor*)actor;
@end

@implementation riTiledMapWaypoint

@synthesize waypointName = _waypointName;
@synthesize infoDict = _infoDict;
@synthesize nextWaypoint = _nextWaypoint;

+(id) WaypointWithInfoDictionary:(NSMutableDictionary *)dict
{
	return [[[self alloc] initWaypointWithInfoDictionary:dict] autorelease];
}

- (id) init
{
	if ((self = [super init])) {
        _waypointName = nil;
        _infoDict = nil;
        _nextWaypoint = nil;
	}
 
	return self;
}

- (id) initWaypointWithInfoDictionary:(NSMutableDictionary*)dict{
    self = [self init];
    self.infoDict = dict;
    self.waypointName = [_infoDict valueForKey:@"name"];
    int x = [[_infoDict valueForKey:@"x"] intValue];
    int y = [[_infoDict valueForKey:@"y"] intValue];
    self.position = ccp(x,y);
    
    return self;
}

-(riTiledMapWaypoint *) initWithWaypointName:(NSString *) name_{
    self = [self init];
    if(self != nil)
        self.waypointName = name_;
    return self;
}

- (void) dealloc{
    [_waypointName release];
    _waypointName = nil;
    [_infoDict release];
    _infoDict = nil;
    [super dealloc];
}

- (riTiledMapWaypoint *) nextWaypoint{
    if(_infoDict != nil){
        NSString * nextWaypointName = [_infoDict objectForKey:@"NextWaypoint"];
        DataModel * m = [DataModel sharedDataModel];
        riTiledMapWaypoint * wp = nil;
        if(nextWaypointName != nil && ![nextWaypointName isEqualToString:@""]){
            wp = [m.waypoints objectForKey:nextWaypointName];
        }else if([nextWaypointName isEqualToString:@""]){
            NSArray * names = [m.waypoints allKeys];
            NSString * name = [names objectAtIndex:arc4random()%[names count]];
            wp = [m.waypoints objectForKey:name];
        }
        _nextWaypoint = wp;
        return  wp;
    }
    _nextWaypoint = nil;
    return nil;
}

-(CCActionInterval *) getAdjustmentActionFor:(riActor*)actor {
    
    if(_infoDict != nil){
        CCActionInterval * action = nil;
        CCActionInterval * movementAction = nil;
        CCAnimation * animation = nil;
        CCActionInterval * animateAction = nil;
        CCAnimate * animate = nil;

        int speed = [actor speed];
        if(speed == 0)
            speed = [[_infoDict objectForKey:@"Speed"] intValue];
        if (speed == 0) 
            speed = 10;
        int duration = ccpDistance([actor position], self.position)/speed;
        
        //Construct Animation Here...
        NSString * animationName = [_infoDict objectForKey:@"Animation"];
        if(animationName != nil && ![animationName isEqualToString:@""]){
            NSString * aname = [NSString stringWithFormat:@"%@_%@",actor.name,animationName];
            NSLog(@"Animation Name = %@",aname);
            animation = [[CCAnimationCache sharedAnimationCache] animationByName:aname];            
            float delay = animation.delay;
            int frameCount = [animation.frames count];
            int times = duration / (delay*frameCount);
            if(animation != nil){
                animate = [CCAnimate actionWithAnimation:animation restoreOriginalFrame:NO];
                if (times != INFINITY) 
                    animateAction = [CCRepeat actionWithAction:animate times:times];
                else
                    animateAction = [CCRepeatForever actionWithAction:animate];
            }
        }
        
        movementAction = [CCMoveTo actionWithDuration:duration position:[self position]];
        
        if(movementAction == nil || duration == INFINITY)
            return animateAction;
        else{
            action = [CCSpawn actions:movementAction,animateAction, nil];
            return action;
        }
    }
    return nil;
}

-(CCActionInterval *) getNextActionFor:(riActor *)actor{
    if(_infoDict != nil)
        return [self initActionFromInfoDictionaryForActor:actor];
    else
        return nil;
}
/*
 - return nil if no action or animation or nextwaypoint defined
 - return animation only if defined only
 - return move action only if defined only
 - return animation and move action if defined both
 
 - after using this method, release the returned action
 */


-(CCActionInterval *) initActionFromInfoDictionaryForActor:(riActor*)actor{
    
    CCActionInterval * action = nil;
    
    CCAnimation * animation = nil;
    CCAnimate * animate = nil;
//    riTiledMapWaypoint * nextWaypoint = nil;
    float duration = INFINITY;
    
    //Construct Movement Action Here...
    CCActionInterval * movementAction = nil;
    
    NSString * actionName = [_infoDict objectForKey:@"Action"];
    if(actionName != nil && ![actionName isEqualToString:@""]){
        
        int speed = [actor speed]*[[_infoDict objectForKey:@"Speed"] floatValue];
//        if(speed == 0)
//            speed = [[_infoDict objectForKey:@"Speed"] intValue];
        
        if (speed == 0) 
            speed = 10;
        
        //If we also have a NextWaypoint.
        
//        nextWaypoint = [self nextWaypoint];
        duration = [self distanceToWaypoint:_nextWaypoint]/speed;
        
        if(_nextWaypoint != nil && duration != INFINITY){
            if ([actionName isEqualToString:@"CCMoveTo"]) {
                movementAction = [CCMoveTo actionWithDuration:duration position:_nextWaypoint.position];
            } else if([actionName isEqualToString:@"CCJumpTo"]){
                float height = [[_infoDict objectForKey:@"Height"] floatValue];
                int jumps = [[_infoDict objectForKey:@"Jumps"] intValue];
                if(height != 0 && jumps != 0)
                    movementAction = [CCJumpTo actionWithDuration:duration position:_nextWaypoint.position height:height jumps:jumps];
                else
                    movementAction = [CCMoveTo actionWithDuration:duration position:_nextWaypoint.position];
            } else if([actionName isEqualToString:@"CCBezierTo"]){
                ccBezierConfig bconfig;                
                bconfig.endPosition = _nextWaypoint.position;
                NSString * controlA = [_infoDict objectForKey:@"ControlPointA"];
                NSString * controlB = [_infoDict objectForKey:@"ControlPointB"];
                if(controlA != nil && controlB != nil){
                    bconfig.controlPoint_1 = [[[[DataModel sharedDataModel] controlPoints] objectForKey:controlA] position];
                    bconfig.controlPoint_2 = [[[[DataModel sharedDataModel] controlPoints] objectForKey:controlB] position];
                }else{
                    bconfig.controlPoint_1 = cpvzero;
                    bconfig.controlPoint_2 = cpvzero;
                }

//                bconfig.controlPoint_1 = CGPointFromString([_infoDict objectForKey:@"ControlPointA"]);
//                bconfig.controlPoint_2 = CGPointFromString([_infoDict objectForKey:@"ControlPointB"]);
                movementAction = [CCBezierTo actionWithDuration:duration bezier:bconfig];
            }
            // More Actions To Be Defined Here...
            
        } 
    }
    
    //Construct Animation Here...
    CCActionInterval * animateAction = nil;

    NSString * animationName = [_infoDict objectForKey:@"Animation"];
    if(animationName != nil && ![animationName isEqualToString:@""]){
        animation = [[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"%@_%@",actor.name,animationName]];
        float delay = animation.delay;
        int frameCount = [animation.frames count];
        int times = duration / (delay*frameCount);
        if(animation != nil){
            animate = [CCAnimate actionWithAnimation:animation restoreOriginalFrame:NO];
            if (times != INFINITY) 
                animateAction = [CCRepeat actionWithAction:animate times:times];
            else
                animateAction = [CCRepeatForever actionWithAction:animate];
        }
    }

    if(movementAction == nil || duration == INFINITY)
        if (animateAction != nil) 
            return animateAction;
        else
            return nil;

    else{
        if (animateAction != nil) {
            action = [CCSpawn actions:movementAction,animateAction, nil];
            return action;
        }else
            return movementAction;
    }
}

-(float) distanceToWaypointWithName:(NSString *)wname{
    if(wname != nil && ![wname isEqualToString:@""]){
        riTiledMapWaypoint * wp = [[DataModel sharedDataModel].waypoints objectForKey:wname];
        if (wp == nil) 
            return INFINITY;
        else{
            float dis = ccpDistance(self.position, wp.position);
            return dis;
        }
    }
    return INFINITY;
}

-(float) distanceToWaypoint:(riTiledMapWaypoint *)wp{
    if(wp != nil)
        return ccpDistance(self.position, wp.position);
    return INFINITY;
}

@end
