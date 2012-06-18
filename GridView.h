//
//  GridView.h
//
//  Created by Jeremy Olmsted-Thompson on 3/5/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum  {
    GridViewOrientationHorizontal,
    GridViewOrientationVertical
} GridViewOrientation;

@class GridView;

@protocol GridViewCell

@optional
-(NSString*)reuseIdentifier;

@end

@protocol GridViewDataSource

-(UIView*)gridView:(GridView*)gridView viewForItemAtIndex:(NSInteger)index;

@optional
-(BOOL)gridViewShouldReload:(GridView*)gridView;

@end

@interface GridView : UIScrollView

@property (nonatomic) NSInteger rowCount;
@property (nonatomic) CGFloat horizontalSpacing;
@property (nonatomic) CGFloat verticalSpacing;
@property (nonatomic) CGFloat tileAspectRatio;
@property (nonatomic) GridViewOrientation orientation;
@property (nonatomic,readonly) CGSize tileSize;
@property (nonatomic,assign) IBOutlet NSObject<GridViewDataSource> *dataSource;
@property (nonatomic,readonly) BOOL loadingTiles;
@property (nonatomic,assign) NSUInteger bufferedScreenCount;

-(void)loadItems;
-(void)reloadData;
-(id)dequeueReusableTileWithIdentifier:(NSString*)identifier;

@end
