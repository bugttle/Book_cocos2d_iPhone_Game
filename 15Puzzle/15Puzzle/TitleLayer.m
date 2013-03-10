//
//  TitleLayer.m
//  15Puzzle
//
//  Created by UQTimes on 13/03/11.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "TitleLayer.h"
#import "GameLayer.h"

@implementation TitleLayer

+ (CCScene *)scene
{
    CCScene *scene = [CCScene node];
    TitleLayer *layer = [TitleLayer node];
    [scene addChild:layer];
    
    return scene;
}

- (void)onEnter
{
    [super onEnter];
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    CCSprite *backImage = [CCSprite spriteWithFile:@"image.png"];
    backImage.position = ccp(winSize.width/2, winSize.height/2);
    backImage.color = ccc3(100, 100, 100);
    [self addChild:backImage z:0];
    
    [CCMenuItemFont setFontName:@"Helvetica-BoldOblique"];
    [CCMenuItemFont setFontSize:60];
    CCMenuItemFont *item = [CCMenuItemFont itemWithString:@"ゲームスタート" block:^(id sender) {
        // GameLayerを表示する
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0 scene:[GameLayer scene] withColor:ccWHITE]];
    }];
    CCMenu *menu = [CCMenu menuWithItems:item, nil];
    menu.position = ccp(winSize.width/2, 60);
    [self addChild:menu];
}

@end
