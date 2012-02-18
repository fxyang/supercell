//
//  riCCAnimationCacheExtensions.h
//  supercell
//
//  Created by Feixue Yang on 12-02-15.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@interface CCAnimationCache (ISExtensions)

-(void)addAnimationsWithDictionary:(NSDictionary *)dictionary;
-(void)addAnimationsWithFile:(NSString *)plist;

@end
