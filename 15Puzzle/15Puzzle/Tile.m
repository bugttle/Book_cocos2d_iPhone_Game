//
//  Tile.m
//  15Puzzle
//
//  Created by UQTimes on 13/03/11.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "Tile.h"

@interface Tile ()

- (UIImage *)shapingImageNamed:(NSString *)imageNamed;
- (void)NotifyFromNotificationCenter:(NSNotification *)notification;
- (BOOL)containsTouchLocation:(UITouch *)touch;
- (void)showGuidNumByTouch:(UITouch *)touch;
- (void)scheduleEventTouchHold:(ccTime)delta;
- (void)blinkFrame;

@end


@implementation Tile

@dynamic Answer;
- (int)Answer
{
    return _answer;
}

- (void)setAnswer:(int)Answer
{
    _answer = Answer;
    
    if (!_lblAnswer) {
        _lblAnswer = [CCLabelTTF labelWithString:@"99" fontName:@"Arial-BoldMT" fontSize:40];
        _lblAnswer.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
        _lblAnswer.color = ccc3(255, 100, 40);
        [self addChild:_lblAnswer z:2];
//        _lblAnswer.visible = NO;
        _lblAnswer.visible = YES;
        
        _lblAnswer.scale = MIN((self.contentSize.width*0.8) / _lblAnswer.contentSize.width, (self.contentSize.height * 0.8) / _lblAnswer.contentSize.height);
        if (_lblAnswer.scale > 1.0) {
            _lblAnswer.scale = 1.0;
        }
    }
    
    [_lblAnswer setString:[NSString stringWithFormat:@"%d", Answer + 1]];
}

@dynamic IsBlank;
- (BOOL)IsBlank
{
    return _isBlank;
}

- (void)setIsBlank:(BOOL)IsBlank
{
    _isBlank = IsBlank;
    if (_isBlank) {
        self.opacity = 0;
    } else {
        self.opacity = 255;
    }
}

@synthesize Now = _now;
@synthesize IsTouchHold = _isTouchHold;

- (id)init
{
    self = [super init];
    if (self) {
        _imgFrame = nil;
        _imgBlinkFrame = nil;
        _lblAnswer = nil;
        _answer = 0;
        _now = 0;
        _isTouchBegin = NO;
        _isTouchHold = NO;
        _touchLocation = CGPointZero;
        _deltaTime = 0.0;
        _isBlank = NO;
    }
    return self;
}

- (void)onEnter
{
    [super onEnter];
    
    [[CCDirector sharedDirector].touchDispatcher addTargetedDelegate:self priority:-9 swallowsTouches:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NotifyFromNotificationCenter:) name:nil object:nil];
}

- (void)onExit
{
    [super onExit];
    
    [[CCDirector sharedDirector].touchDispatcher removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL bResult = NO;
    _isTouchHold = NO;
    if ([self containsTouchLocation:touch]) {
        CGPoint touchLocation = [touch locationInView:[touch view]];
        _touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        
        // 長押し判定
        _deltaTime = 0;
        [self schedule:@selector(scheduleEventTouchHold:)];
        
        // タッチ開始
        _isTouchBegin = YES;
        bResult = YES;
    }
    return bResult;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // タッチ座標をcocos2dの座標に変換する
    CGPoint touchLocation = [touch locationInView:[touch view]];
    CGPoint currentTouchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    
    // タッチ開始位置からの移動
    CGPoint difference = ccpSub(_touchLocation, currentTouchLocation);
    float factor = 20;
    if ((abs(difference.x) > factor) || (abs(difference.y) > factor)) {
        NSDictionary *dic = [NSDictionary dictionaryWithObject:touch forKey:TILE_MSG_NOTIFY_TOUCH_MOVE];
        [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_TOUCH_MOVE object:self userInfo:dic];
        _touchLocation = currentTouchLocation;
    }
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // 長押しスケジュールの停止
    [self unschedule:@selector(scheduleEventTouchHold:)];
    if (_isTouchBegin) {
        if ([self containsTouchLocation:touch]) {
            if (!_isTouchHold) {
                // タップ通知
                [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_TAP object:self];
            }
        }
    }
    
    // タッチ終了イベントの通知
    [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_TOUCH_END object:self];
    
    _isTouchBegin = NO;
}

- (BOOL)containsTouchLocation:(UITouch *)touch
{
    // タッチ座標をcocos2dの座標に変換する
    CGPoint touchLocation = [touch locationInView:[touch view]];
    CGPoint location = [[CCDirector sharedDirector] convertToGL:touchLocation];
    
    // 親ノードの座標が移動している場合のため、boundingBoxプロパティを取得
    CGRect boundingBox = self.boundingBox;
    
    // CCLayerを継承するクラスまで親ノードをさかのぼって探索
    CCNode *parent = self.parent;
    while (parent) {
        if ([parent isKindOfClass:[CCLayer class]]) {
            break;
        } else {
            parent = parent.parent;
        }
    }
    if (parent) {
        // 親ノードの座標と自ノードの座標を加算
        boundingBox.origin = ccpAdd(boundingBox.origin, parent.position);
    }
    
    return CGRectContainsPoint(boundingBox, location);
}

- (void)blinkFrame
{
    float maxOpacity = 127;
    _imgBlinkFrame.opacity = maxOpacity;
    _imgBlinkFrame.visible = YES;
    
    id fadeOut = [CCFadeTo actionWithDuration:0.3 opacity:0];
    id fadeIn = [CCFadeTo actionWithDuration:0.8 opacity:maxOpacity];
    id seq = [CCSequence actions:fadeOut, fadeIn, nil];
    id rep = [CCRepeatForever actionWithAction:seq];
    
    [_imgBlinkFrame runAction:rep];
}

- (void)NotifyFromNotificationCenter:(NSNotification *)notification
{
    if ([notification.name isEqualToString:TILE_MSG_NOTIFY_TOUCH_HOLD]) {
        // いずれかのタイルを長押し
        if (!_isBlank) {
            if (_answer == _now) {
                [self blinkFrame];
            } else {
                // 不正解の場合、ガイドナンバーと不正解用の枠を表示
                _lblAnswer.visible = YES;
                _imgFrame.visible = YES;
            }
        } else {
            _imgFrame.visible = YES;
        }
    } else if ([notification.name isEqualToString:TILE_MSG_NOTIFY_TOUCH_END]) {
//        _lblAnswer.visible = NO;
//        _imgFrame.visible = NO;
        [_imgBlinkFrame stopAllActions];
        _imgBlinkFrame.visible = NO;
    } else if ([notification.name isEqualToString:TILE_MSG_NOTIFY_TOUCH_MOVE]) {
        if (((Tile *)notification.object).IsTouchHold) {
            // 長押し中
            [self showGuidNumByTouch:[notification.userInfo objectForKey:TILE_MSG_NOTIFY_TOUCH_MOVE]];
        }
    } else if ([notification.name isEqualToString:TILE_MSG_NOTIFY_SHOW_NUMBER]) {
        if ((_answer == _now) && (!_isBlank)) {
            _lblAnswer.visible = YES;
        } else if (_isBlank && notification.object != self) {
//            _lblAnswer.visible = NO;
        }
    } else if ([notification.name isEqualToString:TILE_MSG_NOTIFY_HIDE_NUMBER]) {
        // ガイドナンバー非表示
        if (_isBlank || (_answer == _now)) {
//            _lblAnswer.visible = NO;
        }
    }
}

// タッチ地点移動によるガイドナンバー表示
- (void)showGuidNumByTouch:(UITouch *)touch
{
    if ([self containsTouchLocation:touch]) {
        if ((_answer == _now) || _isBlank) {
            // 自体るが正解値にあるか、空白タイルである場合、ガイドナンバーを表示
            _lblAnswer.visible = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_SHOW_NUMBER object:self];
        } else if (_answer != _now) {
            // 不正解タイルの場合、ガイドナンバー非表示通知
            [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_HIDE_NUMBER object:self];
        }
    }
}

// スケジュールイベント: 画面長押し
- (void)scheduleEventTouchHold:(ccTime)delta
{
    if (!_isTouchBegin) {
        return;  // 自タイルのタッチイベントではない場合、長押し判定はしない
    }
    
    _deltaTime += delta;
    
    if (_deltaTime > 1.0) {
        // 経過時間が1秒を超えた場合、長押しとする
        _isTouchHold = YES;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_TOUCH_HOLD object:self];
        
        // 長押しスケジュールの解除
        [self unschedule:_cmd];
        
        if ((_answer == _now) || _isBlank) {
            // 正解タイルあるいは空白タイルの場合、ガイドナンバーを表示
            _lblAnswer.visible = YES;
            
            // ガイドナンバー表示通知
            [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_SHOW_NUMBER object:self];
        }
    }
}
- (UIImage *)shapingImageNamed:(NSString *)imageNamed
{
    UIImage *resultImage = [UIImage imageNamed:imageNamed];
    
    UIGraphicsBeginImageContext(CGSizeMake(self.contentSize.width, self.contentSize.height));
    [resultImage drawInRect:CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)];
    resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

- (void)createFrame
{
    if (_imgFrame) {
        // すでに存在すれば開放
        [_imgFrame removeFromParentAndCleanup:YES];
        _imgFrame = nil;
    }
    if (_imgBlinkFrame) {
        [_imgBlinkFrame removeFromParentAndCleanup:YES];
        _imgBlinkFrame = nil;
    }
    
    // 自分と同じ大きさのフレームを作成
    _imgFrame = [CCSprite spriteWithCGImage:[self shapingImageNamed:@"Frame.png"].CGImage key:@"Frame"];
    _imgFrame.position = CGPointMake(self.contentSize.width / 2, self.contentSize.height / 2);
    _imgFrame.opacity = 127;
    [self addChild:_imgFrame z:1];
    _imgFrame.visible = NO;
    
    _imgBlinkFrame = [CCSprite spriteWithCGImage:[self shapingImageNamed:@"BlinkFrame.png"].CGImage key:@"BlankFrame"];
    _imgBlinkFrame.position = CGPointMake(self.contentSize.width / 2, self.contentSize.height / 2);
    _imgBlinkFrame.opacity = 127;
    [self addChild:_imgBlinkFrame z:1];
    _imgBlinkFrame.visible = NO;
}

@end
