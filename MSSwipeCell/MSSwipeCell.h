//
//  MSSwipeCell.h
//  MSSwipeCell
//
//  Created by ypl on 2018/9/3.
//  Copyright © 2018年 ypl. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark -

typedef NS_ENUM(NSInteger, MSSwipeCellActionStyle) {
    MSSwipeCellActionStyleDefault = 0,
    MSSwipeCellActionStyleDestructive = MSSwipeCellActionStyleDefault,  // 删除 红底
    MSSwipeCellActionStyleNormal                                        // 正常 灰底
};

typedef NS_ENUM(NSInteger, MSSwipeCellActionAnimationStyle) {
    MSSwipeCellActionAnimationStyleDefault = 0,    // 正常 点击就执行
    MSSwipeCellActionAnimationStyleAnimation = 1,  // 动画 点击就执行动画，寻求再次确认 : 注意 Destructive|Default 属性默认执行动画
};

@interface MSSwipeCellAction : NSObject

+ (instancetype)rowActionWithStyle:(MSSwipeCellActionStyle)style title:(NSString *)title handler:(void (^)(MSSwipeCellAction *action, NSIndexPath *indexPath))handler;

@property (nonatomic, readonly) MSSwipeCellActionStyle style;
@property (nonatomic, assign) MSSwipeCellActionAnimationStyle animationStyle;   //是否需要执行确认动画. 默认Default
                                                                                //style == MSSwipeCellActionStyleDestructive ||
                                                                                //animationStyle == MSSwipeCellActionAnimationStyleAnimation 执行动画
@property (nonatomic, strong) NSString *title;            // 文字内容
@property (nonatomic, strong) UIImage *image;             // 按钮图片. 默认无图
@property (nonatomic, strong) UIColor *titleColor;        // 文字颜色. 默认白色
@property (nonatomic, strong) UIColor *backgroundColor;   // 背景颜色. 默认透明 : 级别优先于 style
@property (nonatomic, assign) CGFloat margin;             // 内容左右间距. 默认15
@property (nonatomic, strong) UIFont *font;               // 字体大小. 默认17

/* 设置需要显示confirm的text和icon */
@property (nonatomic, strong)NSString *confirmTitle;      //再次确认的文字描述. 默认空
@property (nonatomic, strong)NSString *confirmIcon;       //再次确认的图片icon. 默认空

@end

#pragma mark -

typedef NS_ENUM(NSInteger, TMSwipeActionButtonStyle) {
    TMSwipeActionButtonStyleNormal = 0,     //正常状态：动画前
    TMSwipeActionButtonStyleSelected = 1,   //选中状态：动画后
};

@interface TMSwipeActionButton : UIButton

/* 属性赋值来自[MSSwipeCellAction class]实例 */
@property (nonatomic, assign)MSSwipeCellActionAnimationStyle animationStyle;

/* 记录当前动画状态,仅仅在有动画效果下生效 */
@property (nonatomic, assign)TMSwipeActionButtonStyle logStyle;

@end

#pragma mark -

@class MSSwipeCell;
@protocol MSSwipeCellDelegate <NSObject>
@optional;

/**
 选中了侧滑按钮

 @param swipeCell 当前响应的cell
 @param indexPath cell在tableView中的位置
 @param index 选中的是第几个action
 */
- (void)swipeCell:(MSSwipeCell *)swipeCell atIndexPath:(NSIndexPath *)indexPath didSelectedAtIndex:(NSInteger)index;

/**
 告知当前位置的cell是否需要侧滑按钮

 @param swipeCell 当前响应的cell
 @param indexPath cell在tableView中的位置
 @return YES 表示当前cell可以侧滑, NO 不可以
 */
- (BOOL)swipeCell:(MSSwipeCell *)swipeCell canSwipeRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 返回侧滑事件

 @param swipeCell 当前响应的cell
 @param indexPath cell在tableView中的位置
 @return 数组为空, 则没有侧滑事件
 */
- (NSArray<MSSwipeCellAction *> *)swipeCell:(MSSwipeCell *)swipeCell editActionsForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface MSSwipeCell : UITableViewCell

@property (nonatomic, weak) id<MSSwipeCellDelegate> delegate;

/**
 *  按钮容器
 */
@property (nonatomic, strong) UIView *btnContainView;

/**
 *  隐藏侧滑按钮
 */
- (void)hiddenAllSideslip;
- (void)hiddenSideslip:(BOOL)animate;

@end

#pragma mark -

@interface UITableView (MSSwipeCell)

- (void)hiddenAllSideslip;

@end
