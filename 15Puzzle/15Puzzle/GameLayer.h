//
//  GameLayer.h
//  15Puzzle
//
//  Created by UQTimes on 13/03/11.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#import "Tile.h"

@interface GameLayer : CCLayer {
    int _tileCount;  // 総タイル枚数
    CCArray *_tileList;  // Tileオブジェクトを格納する配列
    int _actionCount;  // タイル移動アクションの総数
    int _finishedActionCount;  // 完了したタイル移動アクション数
}

+ (CCScene *)scene;

@end
