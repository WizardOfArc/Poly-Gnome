//
//  PGKonokol.m
//  Poly-Gnome
//
//  Created by Azi Crawford on 5/24/14.
//  Copyright (c) 2014 Azi Crawford. All rights reserved.
//

#import "PGKonokol.h"

@interface PGKonokol()

@property NSArray * masterWordList;
@property NSArray * chantWords;
@end

@implementation PGKonokol

-(instancetype) init
{
    self = [super init];
    if (self)
    {
        self.masterWordList = @[
                                @[],
                                @[@"Ta"],
                                @[@"Ta", @"ka"],
                                @[@"Ta", @"ki", @"ta"],
                                @[@"Ta", @"ka", @"di", @"mi"],
                                @[@"Ta", @"ka", @"Ta", @"ki", @"ta"],
                                @[@"Ta", @"ki", @"ta", @"Ta", @"ki", @"ta"],
                                @[@"Ta", @"ki", @"ta", @"Ta", @"ka", @"di", @"mi"]];
    }
    return self;
    
}

-(instancetype) initWithCount:(int)count
{
    self = [self init];
    if(self)
    {
        [self setCount:count];
    }
    return self;
}

-(void) setCount:(int)count
{
    self.chantWords = [self.masterWordList objectAtIndex:count];
    
}

-(NSArray *) getChantWords
{
    return self.chantWords;
}

-(NSString *) getChantString
{
    return [self.chantWords componentsJoinedByString:@""];
}
@end
