//
//  AppDelegate.m
//  SROPGG-Viewer
//
//  Created by Louis Tur on 5/18/15.
//  Copyright (c) 2015 Louis Tur. All rights reserved.
//

#import "AppDelegate.h"

static NSString * const CLIENT_PATH = @"/Applications/League of Legends.app/Contents/LoL/RADS/projects/lol_air_client/releases/";
static NSString * const CLIENT_PATH_END = @"/deploy/bin/LolClient";
static NSString * const LAUNCHER_PATH = @"/Applications/League of Legends.app/Contents/LoL/RADS/solutions/lol_game_client_sln/releases/";
static NSString * const LAUNCHER_PATH_END  = @"/deploy/LeagueOfLegends.app/Contents/MacOS/LeagueofLegends";

static NSString * const COMMAND_BRIDGE_ARG = @"8394 LoLLauncher";
static NSString * const COMMAND_LAUNCH_ARG = @"riot_launched=true";

static NSString * const OP_GG_ARG = @"spectator 20000.f.spectator.op.gg:80";

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
        
        [self launchReplayForFile:nil];
    }
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)openFileBroser:(NSButton *)sender {
    
    [self.sharedOpenPanel beginWithCompletionHandler:^(NSInteger result) {
        
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *selectedDocuments = [self.sharedOpenPanel URLs];
            [self parseOPGGDataFromFiles:selectedDocuments];
            
        }
        
    }];

}

- (void)parseOPGGDataFromFiles:(NSArray *)fileURLs{
    
    for (NSURL *fileURL in fileURLs) {
        
        NSString *fileName = fileURL.lastPathComponent;
        [self matchReplayInfoFromFile:fileURL completion:^(NSDictionary *matchInfo) {
            
        }];
        
    }
}

#pragma mark - Running LoL Client with OP.GG files

- (void)launchReplayForFile:(NSURL *)filePath{
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];

    NSString *commandLauncherPath = [NSString stringWithFormat:@"%@%@%@", LAUNCHER_PATH, self.launcherVersion, LAUNCHER_PATH_END];
    NSString *commandClientPath = [NSString stringWithFormat:@"%@%@%@", CLIENT_PATH, self.clientVersion, CLIENT_PATH_END];
    // TODO: Implement the actual command call
    
}

- (void)matchReplayInfoFromFile:(NSURL *)fileURL completion:(void(^)(NSDictionary * matchInfo))completion {
    
    NSString *fileContents = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
    __block NSMutableDictionary *matchInfo = [[NSMutableDictionary alloc] init];
    
    [fileContents enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        
        NSString *whiteSpaceStripped = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // this effectively finds the last line in the file
        if([whiteSpaceStripped hasPrefix:COMMAND_LAUNCH_ARG]){
            NSArray *components = [whiteSpaceStripped componentsSeparatedByString:@" \""];
            
            [matchInfo setValue:[self uniqueOPGGKeyFromLine:components.lastObject] forKey:@"uniqueKey"];
            [matchInfo setValue:[self summonerIDFromLine:components.lastObject] forKey:@"summonerID"];
            [matchInfo setValue:[self regionInformationFromLine:components.lastObject] forKey:@"region"];
        }
        
    }];
    
}

// TODO: Write out these methods to return appropriate strings
- (NSString *)uniqueOPGGKeyFromLine:(NSString *)line {
    // line = spectator 20000.f.spectator.op.gg:80 D/xe0rQDLwXEsYsRbSiq0jHyM4gCxy3o 1827637831 NA1"
    
    return nil;
}

- (NSString *)summonerIDFromLine:(NSString *)line {
    
    return nil;
}

- (NSString *)regionInformationFromLine:(NSString *)line{
    
    return nil;
}

#pragma mark - Locating LoL Client Directories

- (BOOL)locatedClientAndLauncherVersionDirectories{
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



@end
