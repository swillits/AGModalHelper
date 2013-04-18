//
//  AGModalHelperShared.h
//  AGModalHelper
//
//  Created by Seth Willits on 4/18/13.
//  Copyright (c) 2013 Araelium Group. All rights reserved.
//


enum {
	AGModalHelperExitStatus_ArgError = 101,
	AGModalHelperExitStatus_NoConnectionError,
	AGModalHelperExitStatus_ConnectionProxyError,
	AGModalHelperExitStatus_CommunicationError,
	AGModalHelperExitStatus_TimeoutError
};


@protocol AGModalHelperServiceProtocol <NSObject>
- (void)performServiceWithArguments:(NSDictionary *)args;
@end


@protocol AGModalHelperApplicationProtocol <NSObject>
- (void)helperConnected:(id<AGModalHelperServiceProtocol>)helper;
- (void)helperResponse:(NSDictionary *)response;
@end



