//
//  ClearLayer.m
//  15Puzzle
//
//  Created by UQTimes on 13/03/11.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "ClearLayer.h"
#import "TitleLayer.h"

@implementation ClearLayer

- (void)onEnter
{
    [super onEnter];
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CCLayerColor *layer = [CCLayerColor layerWithColor:ccc4(100, 100, 100, 100)];
    [self addChild:layer];
    
    CCLabelTTF *label = [CCLabelTTF labelWithString:@"Congratulationns!!" fontName:@"Chalkduster" fontSize:40];
    label.color = ccc3(30, 30, 255);
    label.scaleY = 1.5;
    label.position = CGPointMake(winSize.width / 2, winSize.height - winSize.height / 4);
    [self addChild:label];
    
    // タイトルへ戻るメニュー
    [CCMenuItemFont setFontName:@"Helvetica-BoldOblique"];
    [CCMenuItemFont setFontSize:30];
    CCMenuItemFont *item = [CCMenuItemFont itemWithString:@"タイトルに戻る" block:^(id sender) {
        // タイトルの表示
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0 scene:[TitleLayer scene] withColor:ccWHITE]];
    }];
    
    CCMenu *menu = [CCMenu menuWithItems:item, nil];
    menu.position = CGPointMake(winSize.width / 2, 60);
    [self addChild:menu];
}

@end
