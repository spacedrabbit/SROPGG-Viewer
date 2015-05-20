//
//  AppDelegate.m
//  SROPGG-Viewer
//
//  Created by Louis Tur on 5/18/15.
//  Copyright (c) 2015 Louis Tur. All rights reserved.
//

#import "AppDelegate.h"
#import "SRReplayVideo.h"

// LoL.app specific bundle locations
static NSString * const CLIENT_PATH = @"/Applications/League of Legends.app/Contents/LoL/RADS/projects/lol_air_client/releases/";
static NSString * const CLIENT_PATH_END = @"/deploy/bin/LolClient";
static NSString * const LAUNCHER_PATH = @"/Applications/League of Legends.app/Contents/LoL/RADS/solutions/lol_game_client_sln/releases/";
static NSString * const LAUNCHER_PATH_END  = @"/deploy/LeagueOfLegends.app/Contents/MacOS/LeagueofLegends";
static NSString * const EXECUTABLE_COMMAND_END = @"/deploy/LeagueOfLegends.app/Contents/MacOS";

// Used in forming the command from the OP.GG file
static NSString * const COMMAND_BRIDGE_ARG = @"8394 LoLLauncher";
static NSString * const COMMAND_LAUNCH_ARG = @"riot_launched=true";
static NSString * const OP_GG_ARG = @"spectator 20000.f.spectator.op.gg:80";

static NSString * const SRSummonerIDKey = @"summonerIDKey";
static NSString * const SROPGGUniqueKey = @"opggUniqueKey";
static NSString * const SRLoLRegionKey = @"regionKey";

static NSString * const SRTableViewCellIdentifier = @"tableCell";
static NSString * const SRTableViewCellSummonerIdentifier = @"tableCellSummoner";
static NSString * const SRTableViewNameColumnIdentifier = @"nameColumn";
static NSString * const SRTableViewSummonerColumnIdentifier = @"summonerColumn";

@interface AppDelegate ()

// UI Outlets
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *fileBrowserWindow;
@property (weak) IBOutlet NSButton *openFileBtn;
@property (weak) IBOutlet NSTextField *fileLocationLabel;
@property (weak) IBOutlet NSTableView *fileListTableView;
@property (weak) IBOutlet NSButton *launchReplayBtn;

// NSOpenPanel
@property (strong, nonatomic) NSOpenPanel *sharedOpenPanel;

// Instance Variables for file location
@property (strong, nonatomic) NSString * clientVersion;
@property (strong, nonatomic) NSString * launcherVersion;

@property (strong, nonatomic) NSURL * clientAppURL;
@property (strong, nonatomic) NSURL * launcherAppURL;
@property (strong, nonatomic) NSString * opGGCommandArgument;

@property (strong, nonatomic, readwrite) NSMutableArray *locatedFiles;

// IBActions
- (IBAction)openFileBroser:(NSButton *)sender;
- (IBAction)launchReplayBtn:(NSButton *)sender;

@end



@implementation AppDelegate

@synthesize locatedFiles = _locatedFiles;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    self.locatedFiles = [[NSMutableArray alloc] init];
    self.launchReplayBtn.enabled = NO;
    
    // TODO: Have column expand to fit the text
    [self setupTableView];
    [self setupOpenPanel];
    [self setupLoLDirectoriesAndBegin];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - Setup

- (void)setupTableView{
    self.fileListTableView.delegate = self;
    self.fileListTableView.dataSource = self;
    self.fileListTableView.columnAutoresizingStyle = NSTableViewFirstColumnOnlyAutoresizingStyle;
    self.fileListTableView.allowsColumnSelection = NO;
    self.fileListTableView.allowsColumnResizing = YES;
}

- (void)setupOpenPanel{
    self.sharedOpenPanel = [NSOpenPanel openPanel];
    self.sharedOpenPanel.delegate = self;
    self.sharedOpenPanel.title = @"Select OP.GG file to Open";
    self.sharedOpenPanel.allowedFileTypes = @[ @"cmd" ];
    self.sharedOpenPanel.allowsMultipleSelection = YES;
}

- (void)setupLoLDirectoriesAndBegin{
    BOOL clientAndLauncherLocated = [self locatedClientAndLauncherVersionDirectories];
    
    if (clientAndLauncherLocated) {
        NSString *versionTitle = [NSString stringWithFormat:@"Client ver. %@ ---- Launcher ver. %@", self.clientVersion, self.launcherVersion];
        self.window.title = versionTitle;
    }
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

- (IBAction)launchReplayBtn:(NSButton *)sender {
    [self launchReplayForFile:nil];
}

#pragma mark - Running LoL Client with OP.GG files

// see: http://stackoverflow.com/questions/17976289/executing-shell-commands-with-nstask-objective-c-cocoa
// and: http://stackoverflow.com/questions/412562/execute-a-terminal-command-from-a-cocoa-app
- (void)launchReplayForFile:(NSURL *)filePath{

    NSString *commandLauncherPath = [NSString stringWithFormat:@"%@%@%@", LAUNCHER_PATH, self.launcherVersion, LAUNCHER_PATH_END];
    NSString *commandClientPath = [NSString stringWithFormat:@"%@%@%@", CLIENT_PATH, self.clientVersion, CLIENT_PATH_END];
    
    NSString *pathToExecuteCommandFrom = [NSString stringWithFormat:@"%@%@%@", LAUNCHER_PATH, self.launcherVersion, EXECUTABLE_COMMAND_END];

    NSTask *replayLaunchTask = [[NSTask alloc] init];
    [replayLaunchTask setLaunchPath:@"/bin/sh"];
    [replayLaunchTask setCurrentDirectoryPath:pathToExecuteCommandFrom];
    
    NSString *argumentString = [NSString stringWithFormat:@"%@ \"%@\" %@ \"%@\" \"%@\"", COMMAND_LAUNCH_ARG, commandLauncherPath, COMMAND_BRIDGE_ARG, commandClientPath, self.opGGCommandArgument];

    replayLaunchTask.arguments = [NSArray arrayWithObjects:@"-c", argumentString, nil];

    [replayLaunchTask launch];
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
            
            self.opGGCommandArgument = cleanedString;
            
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
            
            NSString *uniqueKey = [matchInfo valueForKey:SROPGGUniqueKey];
            NSString *summonerID = [matchInfo valueForKey:SRSummonerIDKey];
            NSString *regionID = [matchInfo valueForKey:SRLoLRegionKey];
            
            SRReplayVideo *replayVideo = [[SRReplayVideo alloc] initReplayVideoWithName:fileName replayID:uniqueKey forSummonerID:summonerID inRegion:regionID];
            [self.locatedFiles addObject:replayVideo];
           
            [self.fileListTableView reloadData];
        }];
    }
}

- (NSString *)uniqueOPGGKeyFromLine:(NSString *)line {
    // line = spectator 20000.f.spectator.op.gg:80 D/xe0rQDLwXEsYsRbSiq0jHyM4gCxy3o 1827637831 NA1
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

#pragma mark - NSTableViewDelegate/DataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.locatedFiles ? self.locatedFiles.count : 0;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:SRTableViewCellIdentifier owner:self];
    
    if (self.locatedFiles.count > 0) {
        
        SRReplayVideo *replayVideo = (SRReplayVideo *)self.locatedFiles[row];
        
        if ([tableColumn.identifier isEqualToString:SRTableViewNameColumnIdentifier]) {
            cell.textField.stringValue = replayVideo.replayName;
            tableColumn.title = @"Replay Name";
        }
        
        if ([tableColumn.identifier isEqualToString:SRTableViewSummonerColumnIdentifier]) {
            cell.textField.stringValue = replayVideo.replaySummoner;
            tableColumn.title = @"Summoner ID";
        }
        
    }else{
        cell.textField.stringValue = @"Nothing found";
    }
    
    return cell;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    
    if ([notification.name isEqualToString:NSTableViewSelectionDidChangeNotification]) {
        NSInteger selectedCell = self.fileListTableView.selectedRow;
        SRReplayVideo *selectedVideo = self.locatedFiles[selectedCell];
        
        self.fileLocationLabel.stringValue = selectedVideo.replayName;
        self.launchReplayBtn.enabled = YES;
        
        [self updateMatchDetailsViewForSelectedReplayVideo:selectedVideo];
    }
}

-(BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return YES;
}

#pragma mark - NSCollectionView

- (void)updateMatchDetailsViewForSelectedReplayVideo:(SRReplayVideo *)replayVideo{
    
}

@end
