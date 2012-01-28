//
//  Projectile.m
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Projectile.h"

@implementation Projectile

+ (id)projectile {
	
    Projectile *projectile = nil;
    
    if ((projectile = [[[super alloc] initWithFile:@"Projectile.png"] autorelease])) {
    }    
    
    return projectile;
    
}

- (void) dealloc
{  
    [super dealloc];
}

@end

@implementation IceProjectile

+ (id)projectile {
	
    IceProjectile *projectile = nil;
    
    if ((projectile = [[[super alloc] initWithFile:@"IceProjectile.png"] autorelease])) {
    }    
    
    return projectile;
    
}

- (void) dealloc
{  
    [super dealloc];
}

@end
