//
//  HelperProxy.h
//  AGModalHelper
//
//  Created by Seth Willits on 4/18/13.
//  Copyright (c) 2013 Araelium Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AGModalHelperShared.h"


@interface AGModalHelperProxy : NSObject <AGModalHelperApplicationProtocol>
{
	NSString * mServerName;
	NSString * mExecutablePath;
	
	NSConnection * mConnection;
	NSTask * mTask;
	NSDictionary * mResponse;
	NSDictionary * mArguments;
	NSError * mError;
	
	NSPanel * mTransparentWindow;
	BOOL mModalIsRunning;
}


+ (AGModalHelperProxy *)proxyWithName:(NSString *)serverName executable:(NSString *)executablePath;
- (BOOL)runModal:(NSDictionary *)args response:(NSDictionary **)response error:(NSError **)error;

@end
