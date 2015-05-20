//
//  SRReplayVideo.h
//  SROPGG-Viewer
//
//  Created by Louis Tur on 5/20/15.
//  Copyright (c) 2015 Louis Tur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRReplayVideo : NSObject

@property (strong, nonatomic) NSString *replayName;
@property (strong, nonatomic) NSString *replayID;
@property (strong, nonatomic) NSString *replaySummoner;
@property (strong, nonatomic) NSString *replaySummonerRegion;

-(instancetype)initReplayVideoWithName:(NSString *)name
                              replayID:(NSString *)replayID
                         forSummonerID:(NSString *)summonerID
                              inRegion:(NSString *)regionID NS_DESIGNATED_INITIALIZER;

@end
