//
//  GameLayer.m
//  15Puzzle
//
//  Created by UQTimes on 13/03/11.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"
#import "ClearLayer.h"

@interface GameLayer ()

// タイルを並べる
- (void)setTiles;
// タイルをシャッフル
- (void)shuffle;
// 指定の現在位置を持つタイルオブジェクトを返す
- (Tile *)getTileAtNow:(int)now;
// 通知センターからの通知イベント
- (void)NotifyFromNotificationCenter:(NSNotification *)notification;
// タイルのタップ処理
- (void)tapTile:(Tile *)tile;

@end

@implementation GameLayer

+ (CCScene *)scene
{
    CCScene *scene = [CCScene node];
    GameLayer *layer = [GameLayer node];
    [scene addChild:layer];
    
    return scene;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _tileCount = 16;  // 4x4の15パズル
        _tileList = nil;
        _actionCount = 0;
        _finishedActionCount = 0;
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), self);
    [_tileList release];
    [super dealloc];
}

- (void)onEnter
{
    [super onEnter];
    
    // 通知センターに登録
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NotifyFromNotificationCenter:) name:nil object:nil];
    
    CCTexture2D *tex = [[[CCTexture2D alloc] initWithCGImage:[UIImage imageNamed:@"image.png"].CGImage resolutionType:kCCResolutioniPhone] autorelease];
    
    // １辺のタイル枚数
    int sideTileCount =(int)sqrt((double)_tileCount);
    
    CGSize tileSize = CGSizeMake(tex.contentSize.width / sideTileCount, tex.contentSize.height / sideTileCount);
    
    _tileList = [[CCArray alloc] initWithCapacity:_tileCount];
    
    for (int i = 0; i < _tileCount; ++i) {
        Tile *tile = [Tile spriteWithTexture:tex
                                        rect:CGRectMake(tileSize.width * (i % sideTileCount), tileSize.height * (i / sideTileCount), tileSize.width, tileSize.height)];
        
        [_tileList addObject:tile];

        [self addChild:tile z:1];

        tile.Answer = i;

        [tile createFrame];
        
        if (i == _tileCount - 1) {
            tile.IsBlank = YES;
        }
    }
    
    // タイルを並べる
    [self setTiles];
    
    // タイルをシャッフル
    [self shuffle];
}

- (void)onExit
{
    // 通知センターから削除
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super onExit];
}

- (void)NotifyFromNotificationCenter:(NSNotification *)notification
{
    if ([notification.name isEqualToString:TILE_MSG_NOTIFY_TAP]) {
        // タイルがタップされた
        [self tapTile:notification.object];
    }
}

- (void)tapTile:(Tile *)tile
{
    // タイルの検索
    BOOL checkResult = NO;
    
    // 1辺のタイル枚数を計算
    int sideTileCount = (int)sqrt((double)_tileCount);
    
    CCArray *searchList = [CCArray arrayWithCapacity:sideTileCount];
    
    Tile *blankTile = [_tileList lastObject];
    
    // 上
    int checkPosition = blankTile.Now - sideTileCount;
    while (checkPosition > -1) {
        [searchList addObject:[self getTileAtNow:checkPosition]];
        if (tile.Now == checkPosition) {
            checkResult = YES;
            break;
        }
        checkPosition -= sideTileCount;
    }
    
    // 右 (上方向にタップしたタイルが見つかった場合はチェックしない
    if (!checkResult) {
        [searchList removeAllObjects];
        checkPosition = blankTile.Now + 1;
        while ((checkPosition % sideTileCount != 0) && checkPosition < _tileList.count) {
            [searchList addObject:[self getTileAtNow:checkPosition]];
            if (tile.Now == checkPosition) {
                checkResult = YES;
                break;
            }
            checkPosition++;
        }
    }
    if (!checkResult) {
        [searchList removeAllObjects];
        checkPosition = blankTile.Now + sideTileCount;
        while (checkPosition < _tileList.count) {
            [searchList addObject:[self getTileAtNow:checkPosition]];
            if (tile.Now == checkPosition) {
                checkResult = YES;
                break;
            }
            checkPosition += sideTileCount;
        }
    }
    if (!checkResult) {
        [searchList removeAllObjects];
        checkPosition = blankTile.Now - 1;
        while ((checkPosition % sideTileCount != sideTileCount -1) && (checkPosition > -1)) {
            [searchList addObject:[self getTileAtNow:checkPosition]];
            if (tile.Now == checkPosition) {
                checkResult = YES;
                break;
            }
            checkPosition--;
        }
    }
    
    if (checkResult) {
        CCArray *actionList = [CCArray arrayWithCapacity:searchList.count];
        _finishedActionCount = 0;  // アクションカウントを初期化
        for (Tile *tile in searchList) {
            int tempIndex = blankTile.Now;
            id move = [CCMoveTo actionWithDuration:0.1 position:blankTile.position];
            id moveEnd = [CCCallBlock actionWithBlock:^{
                _finishedActionCount++;
                if (_finishedActionCount == _actionCount) {
                    // すべてのアクションが完了したらクリア
                    BOOL isClear = YES;
                    for (Tile *tile in _tileList) {
                        if (tile.Answer != tile.Now) {
                            isClear = NO;
                            break;
                        }
                    }
                    if (isClear) {
                        [self addChild:[ClearLayer node] z:2];
                        // 空白タイルを表示して、完成絵を表示
                        ((Tile *)[_tileList lastObject]).IsBlank = NO;
                    }
                }
            }];
            
            id seq = [CCSequence actions:move, moveEnd, nil];
            blankTile.position = tile.position;
            blankTile.Now = tile.Now;
            tile.Now = tempIndex;
            
            [actionList addObject:seq];
        }
        
        _actionCount = actionList.count;
        
        for (int i = 0; i < searchList.count; ++i) {
            Tile *tile = [searchList objectAtIndex:i];
            id action = [actionList objectAtIndex:i];
            [tile runAction:action];
        }
    }
}

- (void)setTiles
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    CGSize tileSize = ((Tile *)[_tileList objectAtIndex:0]).contentSize;
    
    int sideTileCount = (int)sqrt((double)_tileCount);
    float blankX = (winSize.width - tileSize.width * sideTileCount) / 2;
    float blankY = (winSize.height - tileSize.height * sideTileCount) / 2;
    
    for (int i = 0; i < _tileList.count; ++i) {
        Tile *tile = [_tileList objectAtIndex:i];
        tile.position = CGPointMake(blankX + tileSize.width / 2 + tileSize.width * (i % sideTileCount), winSize.height - blankY - tileSize.height / 2 - tileSize.height * (i / sideTileCount));
        
        // タイルの現在位置を記憶
        tile.Now = i;
    }
}

- (void)shuffle
{
    // 空白タイルの取得
    Tile *blankTile = [_tileList lastObject];
    
    // 1辺のタイル枚数を計算
    int sideTileCount = (int)sqrt((double)_tileCount);
    
    // タイルの総数x100回、空白タイルを移動
    for (int i = 0; i < _tileCount * 100; ++i) {
        int checkPosition = -1;
        // 空白タイルの移動方向をランダムに決定
        int direction = arc4random() % 4;
        switch (direction) {
            case 0:  // 上
//                NSLog(@"上");
                checkPosition = blankTile.Now - sideTileCount;
                if (checkPosition > 0) {
                    
                } else {
                    // これ以上、上に動けない
                    checkPosition = -1;
                }
                break;
            case 1:  // 右
//                NSLog(@"右");
                checkPosition = blankTile.Now + 1;
                if (checkPosition % sideTileCount != 0) {
                    
                } else {
                    // これ以上、右に移動できない
                    checkPosition = -1;
                }
                break;
            case 2:  // 下
//                NSLog(@"下");
                checkPosition = blankTile.Now + sideTileCount;
                if (checkPosition < _tileList.count) {
                    
                } else {
                    // これ以上、下に移動できない
                    checkPosition = -1;
                }
                break;
            case 3:  // 左
//                NSLog(@"左");
                checkPosition = blankTile.Now - 1;
                if (checkPosition % sideTileCount != sideTileCount - 1) {
                    
                } else {
                    // これ以上、左に移動できない
                    checkPosition = -1;
                }
                break;
            default:
//                NSLog(@"異常");
                checkPosition = -1;
                break;
        }
        
        if (checkPosition > -1) {
            // 移動先のタイルを取得
            Tile *tile = [self getTileAtNow:checkPosition];
            // 移動先タイルと空白タイルの位置を入れ替え
            int tempIndex = blankTile.Now;
            CGPoint tempPosition = blankTile.position;
            blankTile.position = tile.position;
            blankTile.Now = tile.Now;
            tile.Now = tempIndex;
            tile.position = tempPosition;
        }
    }
}

// 指定の現在位置を持つタイルオブジェクトを返す
- (Tile *)getTileAtNow:(int)now
{
    Tile *result = nil;
    for (Tile *tile in _tileList) {
        if (tile.Now == now) {
            result = tile;
            break;
        }
    }
    
    return result;
}

@end
