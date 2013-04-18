//
//  HelperProxy.m
//  AGModalHelper
//
//  Created by Seth Willits on 4/18/13.
//  Copyright (c) 2013 Araelium Group. All rights reserved.
//

#import "AGModalHelperProxy.h"



@interface AGModalHelperTransparentWindow : NSPanel
@end


@implementation AGModalHelperTransparentWindow
- (BOOL)canBecomeKeyWindow; { return YES; }
- (BOOL)canBecomeMainWindow; { return NO; }
@end






@implementation AGModalHelperProxy

+ (AGModalHelperProxy *)proxyWithName:(NSString *)serverName executable:(NSString *)executablePath;
{
	return [[[AGModalHelperProxy alloc] initWithServerName:serverName executable:executablePath] autorelease];
}



- (id)init;
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}



- (id)initWithServerName:(NSString *)serverName executable:(NSString *)executablePath;
{
	if (!(self = [super init])) {
		return nil;
	}
	
	mServerName = [serverName copy];
	mExecutablePath = [executablePath copy];
	
	mTransparentWindow = [[AGModalHelperTransparentWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100) styleMask:NSBorderlessWindowMask backing:NSBackingStoreRetained defer:NO];
	mTransparentWindow.backgroundColor = [NSColor clearColor];
	mTransparentWindow.opaque = NO;
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
	
	return self;
}



- (void)dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[mServerName release];
	[mExecutablePath release];
	
	[mResponse release];
	[mArguments release];
	[mError release];
	[mTransparentWindow release];
	[super dealloc];
}





#pragma mark -
#pragma mark Public

- (BOOL)runModal:(NSDictionary *)args response:(NSDictionary **)response error:(NSError **)error;
{
	[mResponse release];
	[mArguments release];
	[mError release];
	mResponse = nil;
	mArguments = nil;
	mError = nil;
	
	mArguments = [args copy];
	
	
	if ([self setupServerConnection:error]) {
		if ([self launchTaskWithArguments:nil error:error]) {
			
			// Run a transparent modal window to block the rest of the app
			mModalIsRunning = YES;
			
			NSWindow * window = [[NSApp mainWindow] retain];
			[NSApp runModalForWindow:mTransparentWindow];
			[[window autorelease] makeKeyAndOrderFront:nil];
			
			
			// Any error?
			if (!mResponse && mError) {
				if (error) {
					*error = [[mError copy] autorelease];
				}
			}
		}
	}
	
	
	// Shut down
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSConnectionDidDieNotification object:mConnection];
	[mConnection release];
	mConnection = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:mTask];
	[mTask release];
	mTask = nil;
	
	
	if (mResponse) {
		*response = mResponse;
		return YES;
	}
	
	return NO;
}



- (void)stopModalDueToError:(NSError *)error;
{
	if (!mError) {
		mError = [error copy];
	}
	
	if (mModalIsRunning) {
		[NSApp stopModalWithCode:NSOKButton];
	}
}




#pragma mark -
#pragma mark Helper Callbacks


- (void)helperConnected:(id<AGModalHelperServiceProtocol>)helper;
{
	[helper performServiceWithArguments:mArguments];
}


- (void)helperResponse:(NSDictionary *)response;
{
	mResponse = [response copy];
	[self stopModalDueToError:nil];
}





#pragma mark -
#pragma mark Server

- (BOOL)setupServerConnection:(NSError **)error;
{
	assert(!mConnection);
	assert(mServerName);
	
	NSString * serverName = [NSString stringWithFormat:@"%@.%lu", mServerName, (unsigned long)getpid()];
	
	if ([NSPortNameServer.systemDefaultPortNameServer portForName:serverName]) {
		[[NSPortNameServer.systemDefaultPortNameServer portForName:serverName] invalidate];
	}
	
	
	mConnection = [[NSConnection alloc] init];
	[mConnection setRootObject:self];
	if (![mConnection registerName:serverName]) {
		if (error) {
			*error = [[[NSError alloc] initWithDomain:@"AGModalHelper" code:0 userInfo:@{
						   NSLocalizedDescriptionKey : @"Could not start the modal helper.",
					NSLocalizedFailureReasonErrorKey : @"Can't register connection server name."
					   }] autorelease];
		}
		
		return NO;
	}
	
	[mConnection runInNewThread];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidDie:) name:NSConnectionDidDieNotification object:mConnection];
	
	return YES;
}



- (void)connectionDidDie:(NSNotification *)notification
{
	NSConnection * connectionThatDied = [notification object];
	
	
	// If the server connection dies, then all of the exports that
	// were happening are all dead or soon will be when their tasks
	// exit with angry terminationStatuses.
	if (connectionThatDied == mConnection) {
		[mConnection release];
		mConnection = nil;
		
		
		NSError * error = nil;
		error = [[[NSError alloc] initWithDomain:@"AGModalHelper" code:0 userInfo:@{
					  NSLocalizedDescriptionKey : @"The modal helper service died.",
			   NSLocalizedFailureReasonErrorKey : @"The server connection for the modal helper service has died."
				  }] autorelease];
		
		[self stopModalDueToError:error];
	}
}





#pragma mark -
#pragma mark Task

- (BOOL)launchTaskWithArguments:(NSDictionary *)args error:(NSError **)error;
{
	mTask = [[NSTask alloc] init];
	mTask.launchPath = mExecutablePath;
	mTask.arguments = @[];
	mTask.standardOutput = [NSFileHandle fileHandleWithStandardOutput];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidTerminate:) name:NSTaskDidTerminateNotification object:mTask];
	
	
	@try {
		[mTask launch];
	}
	@catch (NSException * e) {
		if (error) {
			NSString * description = @"Could not start the modal helper service.";
			NSString * reason = [NSString stringWithFormat:@"Launching failed because %@.", e.reason];
			NSString * suggestion = @"This error generally occurs when the application is damaged.";
			*error = [[[NSError alloc] initWithDomain:@"AGModalHelper" code:0 userInfo:@{
						   NSLocalizedDescriptionKey : description,
					NSLocalizedFailureReasonErrorKey : reason,
			   NSLocalizedRecoverySuggestionErrorKey : suggestion
					   }] autorelease];
		}
		return NO;
	}
	
	
	return YES;
}



- (void)taskDidTerminate:(NSNotification *)notification
{
	NSTask * taskThatDied = [notification object];
	
	
	// If the task exited normally then there was no catastrophic
	// error that we need to report from this method.
	if (taskThatDied.terminationStatus == 0) {
		return;
	}
	
	
	{
		NSString * description = @"Communicating with the modal helper failed because the process terminated.";
		NSString * reason = nil;
		NSError * error = nil;
		
		switch (taskThatDied.terminationStatus) {
			case AGModalHelperExitStatus_ArgError:
				reason = @"An internal error (argument mismatch) occurred.";
				break;
				
			case AGModalHelperExitStatus_CommunicationError:
				reason = @"An communication failure occurred.";
				break;
				
			case AGModalHelperExitStatus_NoConnectionError:
				reason = @"The helper process could not find the main app.";
				break;
				
			case AGModalHelperExitStatus_ConnectionProxyError:
				reason = @"The helper process could not connect to the main app.";
				break;
				
			default:
				reason = [NSString stringWithFormat:@"Termination status %d.", taskThatDied.terminationStatus];
				break;
		}
		
		error = [[[NSError alloc] initWithDomain:@"AGModalHelper" code:0 userInfo:@{
					   NSLocalizedDescriptionKey : description,
				NSLocalizedFailureReasonErrorKey : reason
				   }] autorelease];
		
		[self stopModalDueToError:error];
	}
}


- (void)applicationDidBecomeActive:(NSNotification *)notification;
{
	if (mTask.isRunning) {
		[[NSRunningApplication runningApplicationWithProcessIdentifier:mTask.processIdentifier]
		 activateWithOptions:NSApplicationActivateIgnoringOtherApps];
	}
}



@end
