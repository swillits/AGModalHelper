//
//  AppDelegate.m
//  AGModalHelper
//
//  Created by Seth Willits on 4/18/13.
//  Copyright (c) 2013 Araelium Group. All rights reserved.
//

#import "AppDelegate.h"
#import "AGModalHelperProxy.h"



@implementation AppDelegate


- (IBAction)showDialog:(id)sender
{
	NSString * proxyPath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"Helper.app/Contents/MacOS/Helper"];
	AGModalHelperProxy * proxy = [AGModalHelperProxy proxyWithName:@"ModalWindowTest" executable:proxyPath];
	NSDictionary * response = nil;
	NSError * error = nil;
		
	if (![proxy runModal:@{@"arg1": @"blah"} response:&response error:&error]) {
		NSBeep();
		[NSApp presentError:error];
		return;
	}
	
	self.textField.stringValue = [response description];
}


@end
