//
//  AGModalHelperService.m
//  AGModalHelper
//
//  Created by Seth Willits on 4/18/13.
//  Copyright (c) 2013 Araelium Group. All rights reserved.
//

#import "AGModalHelperService.h"
#import "AGModalHelperShared.h"


@implementation AGModalHelperService


#pragma mark -
#pragma mark Public

+ (void)runWithServerName:(NSString *)serverName block:(NSDictionary * (^)(NSDictionary * arguments))block;
{
	static AGModalHelperService * service = nil;
	assert(!service);
	service = [[AGModalHelperService alloc] initWithBlock:block];
	[service phoneHomeToServer:serverName];
}


- (id)initWithBlock:(NSDictionary * (^)(NSDictionary * arguments))block;
{
	if (!(self = [super init])) {
		return nil;
	}
	
	mWorkBlock = [block copy];
	
	return self;
}








#pragma mark -
#pragma mark HelperApp Protocol

- (void)performServiceWithArguments:(NSDictionary *)args;
{
	[mTimeoutTimer invalidate];
	mTimeoutTimer = nil;
	
	// There's an issue with running the modal window immediately and sending the response.
	// My initial thought was to dispatch_async on the main thread everything in the showWindow
	// method, but the response to the main app never finishes. I'm not sure why that is, but
	// doing it after a delay with performSelector works as desired.
	[self performSelector:@selector(_performServiceWithArguments:) withObject:args afterDelay:0.1];
}







#pragma mark -
#pragma mark Internal

- (BOOL)phoneHomeToServer:(NSString *)baseServerName;
{
	NSString * serverName = [NSString stringWithFormat:@"%@.%lu", baseServerName, (unsigned long)getppid()];
	
	
	// Setup the connection to the server
	// -----------------------------------------------
	@try {
		mConnection = [[NSConnection connectionWithRegisteredName:serverName host:nil] retain];
		if (!mConnection) {
			perror("Helper could not create a connection to main app.");
			exit(AGModalHelperExitStatus_NoConnectionError);
		}
		
		//		[mConnection runInNewThread];
		[mConnection addRequestMode:NSRunLoopCommonModes];
		[mConnection addRequestMode:NSModalPanelRunLoopMode];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidDie:) name:NSConnectionDidDieNotification object:nil];
		
		mMainApp = (id)[mConnection rootProxy];
		[(NSDistantObject *)mMainApp setProtocolForProxy:@protocol(AGModalHelperApplicationProtocol)];
	}
	@catch (NSException *exception) {
		perror([[NSString stringWithFormat:@"Helper error when creating a connection to main app. %@", exception] UTF8String]);
		exit(AGModalHelperExitStatus_ConnectionProxyError);
	}
	
	
	// Timeout if nothing happens
	mTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(timeout) userInfo:nil repeats:NO];
	
	
	// Say hello to the server
	// -----------------------------------------------
	@try {
		[mMainApp helperConnected:self];
	}
	@catch (NSException *exception) {
		perror([[NSString stringWithFormat:@"Helper error when saying hello to main app. %@", exception] UTF8String]);
		exit(AGModalHelperExitStatus_CommunicationError);
	}
	
	
	return YES;
}



- (void)_performServiceWithArguments:(NSDictionary *)args;
{
	// Always want this app to be active
	[NSApp activateIgnoringOtherApps:YES];
	
	// Delegate the synchronous process being run
	NSDictionary * response = mWorkBlock(args);
	
	@try {
		[mMainApp helperResponse:response];
	}
	@catch (NSException *exception) {
		perror([[NSString stringWithFormat:@"Helper error when responding to main app. %@", exception] UTF8String]);
		exit(AGModalHelperExitStatus_CommunicationError);
	}
	
	exit(0);
}



- (void)timeout;
{
	perror("Helper timed out.");
	exit(AGModalHelperExitStatus_TimeoutError);
}



- (void)connectionDidDie:(NSNotification *)notification
{
	perror("Helper lost connection to main app. Shutting down.");
	exit(AGModalHelperExitStatus_NoConnectionError);
}

@end
