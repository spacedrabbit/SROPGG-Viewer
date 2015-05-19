//
//  AppDelegate.m
//  SROPGG-Viewer
//
//  Created by Louis Tur on 5/18/15.
//  Copyright (c) 2015 Louis Tur. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *fileBrowserWindow;
@property (weak) IBOutlet NSButton *openFileBtn;
@property (weak) IBOutlet NSTextField *fileLocationLabel;

- (IBAction)openFileBroser:(NSButton *)sender;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)openFileBroser:(NSButton *)sender {
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.delegate = self;
    openPanel.title = @"Select OP.GG file to Open";
    openPanel.allowedFileTypes = @[ @"cmd" ];
    openPanel.allowsMultipleSelection = YES;
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *selectedDocument = [openPanel URLs];
            
        }
        
    }];

}

- (void) presentSelectedDirectory:(NSURL *)directory inTextField:(NSTextField *)textField{
    
    
}

@end
