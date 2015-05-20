//
//  AppDelegate.m
//  SROPGG-Viewer
//
//  Created by Louis Tur on 5/18/15.
//  Copyright (c) 2015 Louis Tur. All rights reserved.
//

#import "AppDelegate.h"

// LoL.app specific bundle locations
static NSString * const CLIENT_PATH = @"/Applications/League of Legends.app/Contents/LoL/RADS/projects/lol_air_client/releases/";
static NSString * const CLIENT_PATH_END = @"/deploy/bin/LolClient";
static NSString * const LAUNCHER_PATH = @"/Applications/League of Legends.app/Contents/LoL/RADS/solutions/lol_game_client_sln/releases/";
static NSString * const LAUNCHER_PATH_END  = @"/deploy/LeagueOfLegends.app/Contents/MacOS/LeagueofLegends";

// Used in forming the command from the OP.GG file
static NSString * const COMMAND_BRIDGE_ARG = @"8394 LoLLauncher";
static NSString * const COMMAND_LAUNCH_ARG = @"riot_launched=true";
static NSString * const OP_GG_ARG = @"spectator 20000.f.spectator.op.gg:80";

static NSString * const SRSummonerIDKey = @"summonerIDKey";
static NSString * const SROPGGUniqueKey = @"opggUniqueKey";
static NSString * const SRLoLRegionKey = @"regionKey";

@interface AppDelegate ()

// UI Outlets
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *fileBrowserWindow;
@property (weak) IBOutlet NSButton *openFileBtn;
@property (weak) IBOutlet NSTextField *fileLocationLabel;

// NSOpenPanel
@property (strong, nonatomic) NSOpenPanel *sharedOpenPanel;

// Instance Variables for file location
@property (strong, nonatomic) NSString * clientVersion;
@property (strong, nonatomic) NSString * launcherVersion;

@property (strong, nonatomic) NSURL * clientAppURL;
@property (strong, nonatomic) NSURL * launcherAppURL;

// IBActions
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

#pragma mark - Opening File Browser and Selecting Files

- (IBAction)openFileBroser:(NSButton *)sender {
    
    [self.sharedOpenPanel beginWithCompletionHandler:^(NSInteger result) {
        
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *selectedDocuments = [self.sharedOpenPanel URLs];
            
            [self parseOPGGDataFromFiles:selectedDocuments];
            
        }
        
    }];

}

#pragma mark - Running LoL Client with OP.GG files

- (void)launchReplayForFile:(NSURL *)filePath{
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];

    NSString *commandLauncherPath = [NSString stringWithFormat:@"%@%@%@", LAUNCHER_PATH, self.launcherVersion, LAUNCHER_PATH_END];
    NSString *commandClientPath = [NSString stringWithFormat:@"%@%@%@", CLIENT_PATH, self.clientVersion, CLIENT_PATH_END];
    // TODO: Implement the actual command call
    
}

#pragma mark - String parsing for OPGGKey, SummonerID and Region

// returns data needed to send request to riot API
- (void)matchReplayInfoFromFile:(NSURL *)fileURL completion:(void(^)(NSDictionary * matchInfo))completion {
    
    __block NSMutableDictionary *matchInfo = [[NSMutableDictionary alloc] init];
    NSString *fileContents = [NSString stringWithContentsOfURL:fileURL
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];
    
    [fileContents enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        
        NSString *whiteSpaceStripped = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // this effectively finds the last line in the file
        if([whiteSpaceStripped hasPrefix:COMMAND_LAUNCH_ARG]){
            
            NSArray *components = [whiteSpaceStripped componentsSeparatedByString:@" \""];
            NSString *cleanedString = [components.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
            
            [matchInfo setValue:[self uniqueOPGGKeyFromLine:cleanedString] forKey:SROPGGUniqueKey];
            [matchInfo setValue:[self summonerIDFromLine:cleanedString] forKey:SRSummonerIDKey];
            [matchInfo setValue:[self regionInformationFromLine:cleanedString] forKey:SRLoLRegionKey];
            
            completion(matchInfo);
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

- (NSString *)uniqueOPGGKeyFromLine:(NSString *)line {
    // line = spectator 20000.f.spectator.op.gg:80 D/xe0rQDLwXEsYsRbSiq0jHyM4gCxy3o 1827637831 NA1"
    NSArray *components = [line componentsSeparatedByString:@" "];
    
    return components[2];
}

- (NSString *)summonerIDFromLine:(NSString *)line {
    NSArray *components = [line componentsSeparatedByString:@" "];
    
    return components[3];
}

- (NSString *)regionInformationFromLine:(NSString *)line{
    NSArray *components = [line componentsSeparatedByString:@" "];
    NSString *region = [[components lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    
    return region;
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
