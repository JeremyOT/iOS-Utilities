//
//  GridView.m
//
//  Created by Jeremy Olmsted-Thompson on 3/5/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import "GridView.h"

@interface GridView ()

@property (nonatomic) NSInteger firstIndex;
@property (nonatomic) NSInteger lastIndex;
@property (nonatomic, retain) NSMutableArray *tiles;
@property (nonatomic) dispatch_queue_t tileLoadingQueue;
@property (nonatomic) BOOL loadRequested;
@property (nonatomic) BOOL reloadRequested;
@property (nonatomic,retain) UIView *loadingView;
@property (nonatomic,retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) BOOL viewsLocked;
@property (nonatomic, readonly) NSInteger lastVisibleIndex;
@property (nonatomic, readonly) NSInteger firstVisibleIndex;
@property (nonatomic, retain) NSMutableDictionary *queuedTiles;

-(void)clearTiles;

@end

@implementation GridView

@synthesize rowCount = _rowCount;
@synthesize horizontalSpacing = _horizontalSpacing;
@synthesize verticalSpacing = _verticalSpacing;
@synthesize dataSource = _dataSource;
@synthesize loadingView = _loadingView;
@synthesize activityIndicator = _activityIndicator;
@synthesize firstIndex = _firstIndex;
@synthesize lastIndex = _lastIndex;
@synthesize tiles = _tiles;
@synthesize tileLoadingQueue = _tileLoadingQueue;
@synthesize loadingTiles = _loadingTiles;
@synthesize bufferedScreenCount = _bufferedScreenCount;
@synthesize loadRequested = _loadRequested;
@synthesize reloadRequested = _reloadRequested;
@synthesize viewsLocked = _viewsLocked;
@synthesize tileSize = _tileSize;
@synthesize orientation = _orientation;
@synthesize tileAspectRatio = _tileAspectRatio;
@synthesize queuedTiles = _queuedTiles;

#pragma mark - Lifecycle

-(void)initializeDefaults {
    _tileLoadingQueue = dispatch_queue_create("TileLoader", 0);
    _verticalSpacing = 4;
    _horizontalSpacing = 4;
    _bufferedScreenCount = 1;
    _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, self.bounds.size.width)];
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _loadingView.backgroundColor = [UIColor clearColor];
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicator.frame = CGRectMake((_loadingView.bounds.size.width - _activityIndicator.bounds.size.width) / 2,
                                          (_loadingView.bounds.size.height - _activityIndicator.bounds.size.height) / 2,
                                          _activityIndicator.bounds.size.width,
                                          _activityIndicator.bounds.size.height);
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    _activityIndicator.hidesWhenStopped = YES;
    [_loadingView addSubview:_activityIndicator];
    _loadingView.hidden = NO;
    _loadingView.alpha = 1;
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:_loadingView];
    _rowCount = 3;
    _tileAspectRatio = 1.0;
    _orientation = GridViewOrientationVertical;
    _queuedTiles = [[NSMutableDictionary alloc] init];
}

-(id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self initializeDefaults];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initializeDefaults];
    }
    return self;
}

-(void)dealloc {
    dispatch_release(_tileLoadingQueue);
    [_tiles release];
    [_queuedTiles release];
    [super dealloc];
}

#pragma mark - Tile Setup

-(NSInteger)lastVisibleIndex {
    switch (_orientation) {
        case GridViewOrientationHorizontal:
            return (NSInteger)ceil((self.contentOffset.x + ((1 + _bufferedScreenCount) * self.bounds.size.width)) / (_tileSize.width + _horizontalSpacing)) * _rowCount;
        case GridViewOrientationVertical:
        default: 
            return (NSInteger)ceil((self.contentOffset.y + ((1 + _bufferedScreenCount) * self.bounds.size.height)) / (_tileSize.height + _verticalSpacing)) * _rowCount;
    }
}

-(NSInteger)firstVisibleIndex {
    switch (_orientation) {
        case GridViewOrientationHorizontal:
            return (NSInteger)MAX(floor((self.contentOffset.x - (_bufferedScreenCount * self.bounds.size.width)) / (_tileSize.width + _horizontalSpacing)) * _rowCount, 0);
        case GridViewOrientationVertical:
        default: 
            return (NSInteger)MAX(floor((self.contentOffset.y - (_bufferedScreenCount * self.bounds.size.height)) / (_tileSize.height + _verticalSpacing)) * _rowCount, 0);
    }
}

-(CGRect)frameForTileAtIndex:(NSInteger)index {
    switch (_orientation) {
        case GridViewOrientationHorizontal:
            return CGRectMake((index / _rowCount) * (_horizontalSpacing + _tileSize.width) + _horizontalSpacing, (index % _rowCount) * (_verticalSpacing + _tileSize.height) + _verticalSpacing, _tileSize.width, _tileSize.height);
        case GridViewOrientationVertical:
        default:
            return CGRectMake((index % _rowCount) * (_horizontalSpacing + _tileSize.width) + _horizontalSpacing, (index / _rowCount) * (_verticalSpacing + _tileSize.height) + _verticalSpacing, _tileSize.width, _tileSize.height);
    }
}

#pragma mark - Tile Reuse

-(id)dequeueReusableTileWithIdentifier:(NSString *)identifier {
    NSMutableArray *queuedTilesForIdentifier = [_queuedTiles objectForKey:identifier];
    id tile = [[queuedTilesForIdentifier lastObject] retain];
    [queuedTilesForIdentifier removeLastObject];
    return [tile autorelease];
}

-(void)enqueueReusableTile:(id)tile {
    if (![tile respondsToSelector:@selector(reuseIdentifier)]) {
        return;
    }
    NSString *identifier = [tile reuseIdentifier];
    if (!identifier) {
        return;
    }
    NSMutableArray *queuedTilesForIdentifier = [_queuedTiles objectForKey:identifier];
    if (!queuedTilesForIdentifier) {
        queuedTilesForIdentifier = [NSMutableArray arrayWithCapacity:1];
        [_queuedTiles setObject:queuedTilesForIdentifier forKey:identifier];
    }
    [queuedTilesForIdentifier addObject:tile];
}

#pragma mark - Scrolling

-(void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    [super setContentOffset:CGPointMake(contentOffset.x, contentOffset.y) animated:animated];
}

-(void)setContentOffset:(CGPoint)contentOffset {
    [super setContentOffset:contentOffset];
    [self loadItems];
}

-(void)ensureContentSizeForRect:(CGRect)rect {
    switch (_orientation) {
        case GridViewOrientationHorizontal:
            if (self.contentSize.width < rect.origin.x + (rect.size.width * 2)) {
                self.contentSize = CGSizeMake(rect.origin.x + (rect.size.width * 2), self.contentSize.height);
                self.loadingView.frame = CGRectMake(self.contentSize.width - self.loadingView.frame.size.width, 0, self.loadingView.frame.size.width, self.bounds.size.height);
            }
            break;
        case GridViewOrientationVertical:
            if (self.contentSize.height < rect.origin.y + (rect.size.height * 2)) {
                self.contentSize = CGSizeMake(self.contentSize.width, rect.origin.y + (rect.size.height * 2));
                self.loadingView.frame = CGRectMake(0, self.contentSize.height - self.loadingView.frame.size.height, self.bounds.size.width, self.loadingView.frame.size.height);
            }
        default:
            break;
    }
}

#pragma mark - Layout and Data

-(void)loadItems {
    if (!_tiles || _viewsLocked) {
        // Prevent load on init
        return;
    }
    @synchronized (self) {
        if (_loadingTiles) {
            _loadRequested = YES;
            return;
        }
        if (_reloadRequested) {
            [self reloadData];
        } else {
            _loadingTiles = YES;
            dispatch_async(_tileLoadingQueue, ^{
                while (self.lastVisibleIndex > _lastIndex) {
                    UIView *tile = [_dataSource gridView:self viewForItemAtIndex:_lastIndex + 1];
                    if (tile) {
                        _lastIndex++;
                        [_tiles addObject:tile];
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            tile.frame = [self frameForTileAtIndex:_lastIndex];
                            [self ensureContentSizeForRect:tile.frame];
                            [self addSubview:tile];
                        });
                    } else {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            _loadingView.hidden = YES;
                        });
                        break;
                    }
                }
                while (self.firstVisibleIndex < _firstIndex) {
                    UIView *tile = [_dataSource gridView:self viewForItemAtIndex:_firstIndex - 1];
                    if (tile) {
                        _firstIndex--;
                        [_tiles insertObject:tile atIndex:0];
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            tile.frame = [self frameForTileAtIndex:_firstIndex];
                            [self addSubview:tile];
                        });
                    } else {
                        break;
                    }
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    while (_lastIndex > self.lastVisibleIndex) {
                        id tile = [_tiles lastObject];
                        [self enqueueReusableTile:tile];
                        [tile removeFromSuperview];
                        [_tiles removeLastObject];
                        _lastIndex --;
                    }
                    while (_firstIndex < self.firstVisibleIndex) {
                        id tile = [_tiles objectAtIndex:0];
                        [self enqueueReusableTile:tile];
                        [tile removeFromSuperview];
                        [_tiles removeObjectAtIndex:0];
                        _firstIndex ++;
                    }
                });
                _loadingTiles = NO;
                if (_loadRequested) {
                    _loadRequested = NO;
                    [self loadItems];
                }
            });
        }
    }
}

-(void)clearTiles {
    _loadingView.alpha = 1;
    [_activityIndicator startAnimating];
    _lastIndex = -1;
    _firstIndex = 0;
    for (UIView *tile in self.tiles) {
        [tile removeFromSuperview];
    }
    self.tiles = [[[NSMutableArray alloc] initWithCapacity:_rowCount] autorelease];
    self.contentOffset = CGPointMake(0, 0);
    self.contentSize = self.bounds.size;
    switch (_orientation) {
        case GridViewOrientationHorizontal: {
            CGFloat tileHeight = (self.bounds.size.height - ((_rowCount + 1) * _verticalSpacing)) / _rowCount;
            _tileSize = CGSizeMake(tileHeight * _tileAspectRatio, tileHeight);
            _loadingView.frame = CGRectMake(self.contentSize.width - 44, 0, 44, self.bounds.size.height);
            _loadingView.hidden = NO;
            break;
        }
        case GridViewOrientationVertical:
        default: {
            CGFloat tileWidth = (self.bounds.size.width - ((_rowCount + 1) * _horizontalSpacing)) / _rowCount;
            _tileSize = CGSizeMake(tileWidth, tileWidth / _tileAspectRatio);
            _loadingView.frame = CGRectMake(0, self.contentSize.height - 44, self.bounds.size.width, 44);
            _loadingView.hidden = NO;
        }
    }
}

-(void)reloadData {
    @synchronized (self) {
        if (_loadingTiles) {
            _reloadRequested = YES;
            return;
        }
        _reloadRequested = NO;
        if ([_dataSource respondsToSelector:@selector(gridViewShouldReload:)] && ![_dataSource gridViewShouldReload:self]) {
            [self loadItems];
            return;
        }
        _loadingTiles = YES;
    }
    [self clearTiles];
    @synchronized (self) {
        _loadingTiles = NO;
        self.contentOffset = CGPointZero;
        [self loadItems];
    }
}

@end
