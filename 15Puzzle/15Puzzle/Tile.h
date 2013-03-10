//
//  Tile.h
//  15Puzzle
//
//  Created by UQTimes on 13/03/11.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#define TILE_MSG_NOTIFY_TOUCH_HOLD @"TileMsgNotifyTouchHold"
#define TILE_MSG_NOTIFY_TOUCH_END  @"TileMsgNotifyTouchEnd"
#define TILE_MSG_NOTIFY_TOUCH_MOVE @"TileMsgNotifyTouchMove"
#define TILE_MSG_NOTIFY_SHOW_NUMBER @"TileMsgNotifyShowNumber"
#define TILE_MSG_NOTIFY_HIDE_NUMBER @"TileMsgNotifyHideNumber"
#define TILE_MSG_NOTIFY_TAP @"TileMsgNotifyTap"

@interface Tile : CCSprite <CCTargetedTouchDelegate> {
    CCSprite *_imgFrame;  // 不正解用
    CCSprite *_imgBlinkFrame;  // 正解用の枠
    CCLabelTTF *_lblAnswer;  // 正解位置の表示用
    int _answer;  // 正解位置
    int _now;  // 現在位置
    BOOL _isTouchBegin;  // 自分の領域内でタッチイベントが発生したか
    CGPoint _touchLocation;  // タッチ開始した座標
    ccTime _deltaTime;  // タッチ開始からの経過時間
    BOOL _isBlank;  // ブランクタイルか
}

@property (nonatomic, readwrite) int Answer;
@property (nonatomic, readwrite) int Now;
@property (nonatomic, readonly) BOOL IsTouchHold;
@property (nonatomic, readwrite) BOOL IsBlank;

// 枠を作成する
- (void)createFrame;

@end
