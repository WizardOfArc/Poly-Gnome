//
//  PGKonokol.h
//  Poly-Gnome
//
//  Created by Azi Crawford on 5/24/14.
//  Copyright (c) 2014 Azi Crawford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PGKonokol : NSObject

-(instancetype) initWithCount: (int) count;
-(NSArray *) getChantWords;
-(NSString *) getChantString;
-(void) setCount: (int) count;


@end
