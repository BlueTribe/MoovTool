//
//  AppDelegate.m
//  MoovTool
//
//  Created by Geoffrey Kruse on 3/3/15.
//  Copyright (c) 2015 Geoffrey Kruse. All rights reserved.
//

#import "AppDelegate.h"
#import "MoovInterface.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
static MoovInterface * mi;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    mi = [[MoovInterface alloc] init];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end
