//
//  AppDelegate.m
//  SROPGG-Viewer
//
//  Created by Louis Tur on 5/18/15.
//  Copyright (c) 2015 Louis Tur. All rights reserved.
//

#import "AppDelegate.h"

static NSString * const CLIENT_PATH = @"/Applications/League of Legends.app/Contents/LoL/RADS/projects/lol_air_client/releases/";
static NSString * const LAUNCHER_PATH = @"/Applications/League of Legends.app/Contents/LoL/RADS/solutions/lol_game_client_sln/releases/";

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *fileBrowserWindow;
@property (weak) IBOutlet NSButton *openFileBtn;
@property (weak) IBOutlet NSTextField *fileLocationLabel;

@property (strong, nonatomic) NSOpenPanel *sharedOpenPanel;

@property (strong, nonatomic) NSString * clientVersion;
@property (strong, nonatomic) NSString * launcherVersion;

@property (strong, nonatomic) NSURL * clientAppURL;
@property (strong, nonatomic) NSURL * launcherAppURL;

- (IBAction)openFileBroser:(NSButton *)sender;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    self.sharedOpenPanel = [NSOpenPanel openPanel];
    self.sharedOpenPanel.delegate = self;
    self.sharedOpenPanel.title = @"Select OP.GG file to Open";
    self.sharedOpenPanel.allowedFileTypes = @[ @"cmd" ];
    self.sharedOpenPanel.allowsMultipleSelection = YES;
    
    BOOL clientAndLauncherLocated = [self locatedClientAndLauncherVersionDirectories];
    
    if (clientAndLauncherLocated) {
        NSString *versionTitle = [NSString stringWithFormat:@"Client ver. %@ ---- Launcher ver. %@", self.clientVersion, self.launcherVersion];
        self.window.title = versionTitle;
    }
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)openFileBroser:(NSButton *)sender {
    
    [self.sharedOpenPanel beginWithCompletionHandler:^(NSInteger result) {
        
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *selectedDocuments = [self.sharedOpenPanel URLs];
            
            
        }
        
    }];

}

- (BOOL) locatedClientAndLauncherVersionDirectories{
    BOOL clientLocated = [self locateClientVersionDirectory];
    BOOL launcherLocated = [self locateLauncherVersionDirectory];
    
    return clientLocated && launcherLocated;
}

- (BOOL)locateClientVersionDirectory {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *fileLocationError = nil;
    self.clientAppURL = [NSURL fileURLWithPathComponents:[CLIENT_PATH pathComponents]];

    NSArray *clientVersions = [fileManager contentsOfDirectoryAtURL:self.clientAppURL
                                         includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey, NSURLPathKey ]
                                                            options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                              error:&fileLocationError];

    if (!fileLocationError) {
        NSURL *fileURL = [clientVersions firstObject]; // TODO: Handle Multiple objects
        self.clientVersion = [fileURL lastPathComponent];
        return YES;
    }
    else{
        NSLog(@"Error encountered locating client version directory: %@", fileLocationError);
    }
    
    return NO;
}

- (BOOL)locateLauncherVersionDirectory {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *fileLocationError = nil;
    self.launcherAppURL = [NSURL fileURLWithPathComponents:[LAUNCHER_PATH pathComponents]];

    NSArray *launcherVersions = [fileManager contentsOfDirectoryAtURL:self.launcherAppURL
                                           includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey, NSURLPathKey]
                                                              options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                error:&fileLocationError];
    
    if (!fileLocationError) {
        NSURL *fileURL = [launcherVersions firstObject]; // TODO: Handle multiple objects
        self.launcherVersion = [fileURL lastPathComponent];
        return YES;
    } else {
        NSLog(@"Error encountered locating launcher version directory: %@", fileLocationError);
    }
    
    return NO;
}


- (void) presentSelectedDirectory:(NSURL *)directory inTextField:(NSTextField *)textField{
    
    
}

@end
