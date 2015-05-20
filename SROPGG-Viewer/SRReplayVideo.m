//
//  SRReplayVideo.m
//  SROPGG-Viewer
//
//  Created by Louis Tur on 5/20/15.
//  Copyright (c) 2015 Louis Tur. All rights reserved.
//

#import "SRReplayVideo.h"

@implementation SRReplayVideo

-(instancetype)initReplayVideoWithName:(NSString *)name replayID:(NSString *)replayID forSummonerID:(NSString *)summonerID inRegion:(NSString *)regionID{
    
    self = [super init];
    if (self) {
        _replayName = name;
        _replayID = replayID;
        _replaySummoner = summonerID;
        _replaySummonerRegion = regionID;
    }
    return self;
}

@end
