//
//  riCCAnimationCacheExtensions.m
//  supercell
//
//  Created by Feixue Yang on 12-02-15.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "riCCAnimationCacheExtensions.h"

@implementation CCAnimationCache (ISExtensions)

/** Add animations to the cache from an NSDictionary that contains an 'animations' element at it's root. */
-(void)addAnimationsWithDictionary:(NSDictionary *)dictionary
{
    NSDictionary *animations = [dictionary objectForKey:@"animations"];
    
    if ( animations == nil ) {
        CCLOG(@"ISCCAnimationCacheExtensions: No animations found in provided dictionary.");
        return;
    }
    
    NSArray* animationNames = [animations allKeys];
    
    for( NSString *name in animationNames ) {
        NSDictionary* animationDict = [animations objectForKey:name];
        NSArray *frameNames = [animationDict objectForKey:@"frames"];
        NSNumber *delay = [animationDict objectForKey:@"delay"];
        CCAnimation* animation = nil;
        
        if ( frameNames == nil ) {
            CCLOG(@"ISCCAnimationCacheExtensions: Animation '%@' found in dictionary without any frames - cannot add to animation cache.", name);
            continue;
        }
        
        NSMutableArray *frames = [NSMutableArray arrayWithCapacity:[frameNames count]];
        
        for( NSString *frameName in frameNames ) {
            CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:frameName];
            CCLOG(@"ISCCAnimationCacheExtensions: Animation '%@' refers to frame '%@' which is not currently in the CCSpriteFrameCache. This frame will not be added to the animation.", name, frameName);
            
            if ( frame != nil ) {
                [frames addObject:frame];
            }
        }
        
        if ( [frames count] == 0 ) {
            CCLOG(@"ISCCAnimationCacheExtensions: None of the frames for animation '%@' were found in the CCSpriteFrameCache. Animation is not being added to the AnimationCache.", name);
            continue;
        } else if ( [frames count] != [frameNames count] ) {
            CCLOG(@"ISCCAnimationCacheExtensions: An animation in your dictionary refers to a frame which is not in the CCSpriteFrameCache. Some or all of the frames for the animation '%@' may be missing.", name);
        }
        
        if ( delay != nil ) {
            animation = [CCAnimation animationWithFrames:frames delay:[delay floatValue]];
        } else {
            animation = [CCAnimation animationWithFrames:frames];
        }
        
        [[CCAnimationCache sharedAnimationCache] addAnimation:animation name:name];
    }
}

/** Read an NSDictionary from a plist file and parse it automatically for animations. */
-(void)addAnimationsWithFile:(NSString *)plist
{
    NSString *directory = [plist stringByDeletingLastPathComponent];
    NSString *file = [plist lastPathComponent];
    NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:directory];
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if ( dict == nil ) {
        CCLOG(@"ISCCAnimationCacheExtensions: Couldn't load animations from plist file.");
    } else {
        [self addAnimationsWithDictionary:dict];
    }
}

@end
