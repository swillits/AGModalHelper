//
//  AppDelegate.m
//  Helper
//
//  Created by Seth Willits on 4/18/13.
//

#import "AppDelegate.h"
#import "AGModalHelperService.h"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[AGModalHelperService runWithServerName:@"ModalWindowTest" block:^NSDictionary *(NSDictionary *arguments) {
		
		// Display a modal window and return the result
		NSInteger result = [NSApp runModalForWindow:window];
		[window orderOut:nil];
		
		return @{@"result": @(result), @"text": textField.stringValue};
	}];
}



- (IBAction)ok:(id)sender;
{
	[NSApp stopModalWithCode:NSOKButton];
}


- (IBAction)cancel:(id)sender;
{
	[NSApp stopModalWithCode:NSCancelButton];
}


@end
