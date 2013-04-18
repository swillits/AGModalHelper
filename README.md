AGModalHelper
=============

Using AGModalHelper, your main application can call upon a helper
service to run a modal window in a separate process and return the
result.

Why? Consider the case where the window (or surrounding work needed
to display it) requires being in a 32-bit application, but the main
app is 64-bit. For example, the ancient QuickTime settings windows
require a 32-bit application, and there is still no 64-bit solution.
That's where AGModalHelper can come in handy.

This is an "experimental" project, but it should be working fine.

This project only requires 10.6 and uses an NSConnection under
the hood. An XPC-based implementation would be lovely, but my own
use cases have to work on 10.6.


Usage
=============
There are two classes in this project: AGModalHelperProxy and
AGModalHelperService. Both classes are design to be self contained
and need no subclassing.

The main application use AGModalHelperProxy to communicate with the
AGModalHelperService. The helper service is launched on demand,
given an NSDictionary of arguments, and returns an NSDictionary
response.


In the main application, the app simply needs to create a proxy
and call the runModal:response:error: method.

	- (IBAction)showDialog:(id)sender
	{
		NSString * proxyPath = @"path/to/helper/executable"
		AGModalHelperProxy * proxy = [AGModalHelperProxy proxyWithName:@"WellKnownName" executable:proxyPath];
		NSDictionary * response = nil;
		NSError * error = nil;
		
		if (![proxy runModal:@{@"arg1": @"blah"} response:&response error:&error]) {
			[NSApp presentError:error];
			return;
		}
	
		... handle response ...
	}



The helper service simply needs to call one method immediately at launch:

	- (void)applicationDidFinishLaunching:(NSNotification *)notification
	{
		[AGModalHelperService runWithServerName:@"WellKnownName" block:^NSDictionary *(NSDictionary *arguments) {
		
			// Run a modal window (or any other synchronous operation)
			[NSApp runModalForWindow:window];
		
			return @{... response ...};
		}];
	}


The helper service will terminate after the response is sent to the main app.

Easy as pie.
	


Requirements
=============
- OS X 10.6


License
=============
Code-level credit would be nice. No credit visible to the end-user
is necessary.


--

Seth Willits
http://www.araelium.com/
