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
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    _activityIndicator.hidesWhenStopped = YES;
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
    if (tile) {
        [queuedTilesForIdentifier removeLastObject];
    }
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
            //TODO: (note:) this code doesn't appear to execute in AllRecipes
            if (self.contentSize.width < rect.origin.x + (rect.size.width * 2)) {
                self.contentSize = CGSizeMake(rect.origin.x + (rect.size.width * 2), self.contentSize.height);
            }
            break;
        case GridViewOrientationVertical:
            if (self.contentSize.height < rect.origin.y + (rect.size.height * 2)) {
                self.contentSize = CGSizeMake(self.contentSize.width, rect.origin.y + rect.size.height + _verticalSpacing);
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
            NSUInteger numTiles = [_dataSource numberOfTilesForGridView];
            while ((self.lastVisibleIndex > _lastIndex) && (_lastIndex +1 < numTiles)) {
                UIView *tile = [_dataSource gridView:self viewForItemAtIndex:_lastIndex + 1];
                _lastIndex++;
                [_tiles addObject:tile];
                tile.frame = [self frameForTileAtIndex:_lastIndex];
                [self ensureContentSizeForRect:tile.frame];
                [self addSubview:tile];
            }
            while (self.firstVisibleIndex < _firstIndex) {
                UIView *tile = [_dataSource gridView:self viewForItemAtIndex:_firstIndex - 1];
                _firstIndex--;
                [_tiles insertObject:tile atIndex:0];
                tile.frame = [self frameForTileAtIndex:_firstIndex];
                [self addSubview:tile];
            }
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
            _loadingTiles = NO;
            if (_loadRequested) {
                _loadRequested = NO;
                [self loadItems];
            }
        }
    }
}

-(void)clearTiles {
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
            break;
        }
        case GridViewOrientationVertical:
        default: {
            CGFloat tileWidth = (self.bounds.size.width - ((_rowCount + 1) * _horizontalSpacing)) / _rowCount;
            _tileSize = CGSizeMake(tileWidth, tileWidth / _tileAspectRatio);
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
