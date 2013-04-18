//
//  AGModalHelperService.h
//  AGModalHelper
//
//  Created by Seth Willits on 4/18/13.
//  Copyright (c) 2013 Araelium Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AGModalHelperShared.h"


@interface AGModalHelperService : NSObject <AGModalHelperServiceProtocol>
{
	NSDictionary * (^mWorkBlock)(NSDictionary * arguments);
	NSString * mServerName;
	NSConnection * mConnection;
	NSTimer * mTimeoutTimer;
	id<AGModalHelperApplicationProtocol> mMainApp;
}

+ (void)runWithServerName:(NSString *)serverName block:(NSDictionary * (^)(NSDictionary * arguments))block;

@end
