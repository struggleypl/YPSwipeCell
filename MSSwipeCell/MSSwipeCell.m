//
//  MSSwipeCell.m
//  MSSwipeCell
//
//  Created by ypl on 2018/9/3.
//  Copyright © 2018年 ypl. All rights reserved.
//

#import "MSSwipeCell.h"
#import "MSDefine.h"

#pragma mark - MSSwipeCellAction

@interface MSSwipeCellAction ()
@property (nonatomic, copy) void (^handler)(MSSwipeCellAction *action, NSIndexPath *indexPath);
@property (nonatomic, assign) MSSwipeCellActionStyle style;
@end
@implementation MSSwipeCellAction
+ (instancetype)rowActionWithStyle:(MSSwipeCellActionStyle)style title:(NSString *)title handler:(void (^)(MSSwipeCellAction *action, NSIndexPath *indexPath))handler {
    MSSwipeCellAction *action = [MSSwipeCellAction new];
    action.title = title;
    action.handler = handler;
    action.style = style;
    return action;
}

- (CGFloat)margin {
    return _margin == 0 ? 15 : _margin;
}

@end

#pragma mark - TMSwipeActionButton

@implementation TMSwipeActionButton

@end

#pragma mark - MSSwipeCell

typedef NS_ENUM(NSInteger, MSSwipeCellState) {
    MSSwipeCellStateNormal,
    MSSwipeCellStateAnimating,
    MSSwipeCellStateOpen
};

@interface MSSwipeCell () <UIGestureRecognizerDelegate>
@property (nonatomic, assign) BOOL sideslip;
@property (nonatomic, assign) MSSwipeCellState state;
@end

@implementation MSSwipeCell{
    UITableView *_tableView;
    NSArray <MSSwipeCellAction *>* _actions;
    UIPanGestureRecognizer *_panGesture;
    UIPanGestureRecognizer *_tableViewPan;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupSideslipCell];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupSideslipCell];
    }
    return self;
}

- (void)setupSideslipCell {
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(contentViewPan:)];
    _panGesture.delegate = self;
    [self.contentView addGestureRecognizer:_panGesture];
    self.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)layoutSubviews {
    CGFloat x = 0;
    if (_sideslip) x = self.contentView.frame.origin.x;
    
    [super layoutSubviews];
    CGFloat totalWidth = 0;
    for (TMSwipeActionButton *btn in _btnContainView.subviews) {
        btn.frame = CGRectMake(totalWidth, 0, btn.frame.size.width, self.frame.size.height);
        totalWidth += btn.frame.size.width;
    }
    _btnContainView.frame = CGRectMake(self.frame.size.width - totalWidth, 0, totalWidth, self.frame.size.height);
    
    // 侧滑状态旋转屏幕时, 保持侧滑
    if (_sideslip) [self setContentViewX:x];
    
    CGRect frame = self.contentView.frame;
    frame.size.width = self.bounds.size.width;
    self.contentView.frame = frame;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    if (_sideslip) [self hiddenSideslip:YES];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == _panGesture) {
        // 若 tableView 不能滚动时, 还触发手势, 则隐藏侧滑
        if (!self.tableView.scrollEnabled) {
            [self hiddenAllSideslip];
            return NO;
        }
        UIPanGestureRecognizer *gesture = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint translation = [gesture translationInView:gesture.view];
        
        // 如果手势相对于水平方向的角度大于45°, 则不触发侧滑
        BOOL shouldBegin = fabs(translation.y) <= fabs(translation.x);
        if (!shouldBegin) return NO;
        
        // 询问代理是否需要侧滑
        if ([_delegate respondsToSelector:@selector(swipeCell:canSwipeRowAtIndexPath:)]) {
            shouldBegin = [_delegate swipeCell:self canSwipeRowAtIndexPath:self.indexPath] || _sideslip;
        }
        
        if (shouldBegin) {
            // 向代理获取侧滑展示内容数组
            if ([_delegate respondsToSelector:@selector(swipeCell:editActionsForRowAtIndexPath:)]) {
                NSArray <MSSwipeCellAction*> *actions = [_delegate swipeCell:self editActionsForRowAtIndexPath:self.indexPath];
                if (!actions || actions.count == 0) return NO;
                [self setActions:actions];
            } else {
                return NO;
            }
        }
        return shouldBegin;
    } else if (gestureRecognizer == _tableViewPan) {
        if (self.tableView.scrollEnabled) {
            return NO;
        }
    }
    return YES;
}

/* Response Events */
- (void)tableViewPan:(UIPanGestureRecognizer *)pan {
    if (!self.tableView.scrollEnabled && pan.state == UIGestureRecognizerStateBegan) {
        [self hiddenAllSideslip];
    }
}

- (void)contentViewPan:(UIPanGestureRecognizer *)pan {
    CGPoint point = [pan translationInView:pan.view];
    UIGestureRecognizerState state = pan.state;
    [pan setTranslation:CGPointZero inView:pan.view];
    
    if (state == UIGestureRecognizerStateChanged) {
        CGRect frame = self.contentView.frame;
        frame.origin.x += point.x;
        if (frame.origin.x > 0) {
            frame.origin.x = 0;
        } else if (frame.origin.x < -30 - _btnContainView.frame.size.width) {
            frame.origin.x = -30 - _btnContainView.frame.size.width;
        }
        self.contentView.frame = frame;
        
    } else if (state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [pan velocityInView:pan.view];
        if (self.contentView.frame.origin.x == 0) {
            return;
        } else if (self.contentView.frame.origin.x > 5) {
            [self hiddenWithBounceAnimation];
        } else if (fabs(self.contentView.frame.origin.x) >= 40 && velocity.x <= 0) {
            [self showSideslip];
        } else {
            [self hiddenSideslip:YES];
        }
        
    } else if (state == UIGestureRecognizerStateCancelled) {
        [self hiddenAllSideslip];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        if (self.state == MSSwipeCellStateAnimating) {
            return NO;
        }
        //向左滑动
        if (self.contentView.frame.origin.x <= 0) {
            if ([otherGestureRecognizer.delegate isKindOfClass:NSClassFromString(@"_FDFullscreenPopGestureRecognizerDelegate")]) {
                return YES;
            }
        }
    }
    
    return NO;
}

/* 触发事件 */
- (void)actionBtnDidClicked:(TMSwipeActionButton *)btn {
    
    MSSwipeCellAction *action = _actions[btn.tag];
    if (btn.animationStyle == MSSwipeCellActionAnimationStyleAnimation) {
        if (btn.logStyle == TMSwipeActionButtonStyleSelected) {
            [self actionBtnDidClickToDule:btn.tag];
            return;
        }
        
        if (action.confirmTitle || action.confirmIcon) {
            [btn setTitle:action.confirmTitle forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:action.confirmIcon] forState:UIControlStateNormal];
        }else{
            [btn setTitle:@"确认删除" forState:UIControlStateNormal];
        }
        if (_actions.count == 1) {
            
            //            CGFloat width = [btn.currentTitle boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : btn.titleLabel.font} context:nil].size.width;
            CGFloat width = 80;
            btn.frame = CGRectMake(0, 0, width + action.margin * 2, self.frame.size.height);
            btn.logStyle = TMSwipeActionButtonStyleSelected;
            [self layoutSubviews];
            [self showSideslip];
        }else{
            
            CGFloat width = _btnContainView.frame.size.width;
            btn.frame = CGRectMake(0, 0, width, self.frame.size.height);
            for (TMSwipeActionButton *button in _btnContainView.subviews) {
                if (button.tag != btn.tag) {
                    [button removeFromSuperview];
                }
            }
            btn.logStyle = TMSwipeActionButtonStyleSelected;
            [self layoutSubviews];
            [self showSideslip];
        }
    }else{
        [self actionBtnDidClickToDule:btn.tag];
    }
}

- (void)actionBtnDidClickToDule:(NSInteger)tag {
    if ([self.delegate respondsToSelector:@selector(swipeCell:atIndexPath:didSelectedAtIndex:)]) {
        [self.delegate swipeCell:self atIndexPath:self.indexPath didSelectedAtIndex:tag];
    }
    if (tag < _actions.count) {
        MSSwipeCellAction *action = _actions[tag];
        if (action.handler) action.handler(action, self.indexPath);
    }
    [self hiddenAllSideslip];
    self.state = MSSwipeCellStateNormal;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (_sideslip) {
        [self hiddenAllSideslip];
    }
}

#pragma mark - Methods
- (void)hiddenWithBounceAnimation {
    self.state = MSSwipeCellStateAnimating;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self setContentViewX:-10];
    } completion:^(BOOL finished) {
        [self hiddenSideslip:YES];
    }];
}

- (void)hiddenAllSideslip {
    [self.tableView hiddenAllSideslip];
}

- (void)hiddenSideslip:(BOOL)animate {
    if (self.contentView.frame.origin.x == 0){
        self.sideslip = NO;
        self.state = MSSwipeCellStateNormal;
        return;
    }
    
    self.state = MSSwipeCellStateAnimating;
    __weak __typeof(&*self)weakSelf = self;
    [UIView animateWithDuration:(0.2) delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self setContentViewX:0];
    } completion:^(BOOL finished) {
        [weakSelf.btnContainView removeFromSuperview];
        weakSelf.btnContainView = nil;
        self.state = MSSwipeCellStateNormal;
    }];
}

- (void)showSideslip {
    self.state = MSSwipeCellStateAnimating;
    __weak __typeof(&*self)weakSelf = self;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self setContentViewX:-weakSelf.btnContainView.frame.size.width];
    } completion:^(BOOL finished) {
        self.state = MSSwipeCellStateOpen;
    }];
}

#pragma mark - Setter
- (void)setContentViewX:(CGFloat)x {
    CGRect frame = self.contentView.frame;
    frame.origin.x = x;
    self.contentView.frame = frame;
}

- (void)setActions:(NSArray <MSSwipeCellAction *>*)actions {
    _actions = actions;
    
    if (_btnContainView) {
        [_btnContainView removeFromSuperview];
        _btnContainView = nil;
    }
    _btnContainView = [UIView new];
    [self insertSubview:_btnContainView belowSubview:self.contentView];
    
    for (int i = 0; i < actions.count; i++) {
        MSSwipeCellAction *action = actions[i];
        TMSwipeActionButton *btn = [TMSwipeActionButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.adjustsImageWhenHighlighted = NO;
        [btn setTitle:action.title?action.title:@"" forState:UIControlStateNormal];
        btn.titleLabel.font = action.font ? action.font : [UIFont systemFontOfSize:17];
        [btn addTarget:self action:@selector(actionBtnDidClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        if (action.backgroundColor) {
            btn.backgroundColor = action.backgroundColor;
        } else {
            btn.backgroundColor = action.style == MSSwipeCellActionStyleNormal?[UIColor colorWithRed:200/255.0 green:199/255.0 blue:205/255.0 alpha:1] : UIColorFromRGB(0xFF5B4C);
        }
        
        if (action.image) {
            [btn setImage:action.image forState:UIControlStateNormal];
        }
        
        if (action.titleColor) {
            [btn setTitleColor:action.titleColor forState:UIControlStateNormal];
        }
        
        //        CGFloat width = [action.title boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : btn.titleLabel.font} context:nil].size.width;
        CGFloat width = 80;//固定宽度
        width += (action.image ? action.image.size.width : 0);
        btn.frame = CGRectMake(0, 0, width + action.margin*2, self.frame.size.height);
        
        //记录需要扩展动画的条件
        if (action.style == MSSwipeCellActionStyleDefault ||
            action.animationStyle == MSSwipeCellActionAnimationStyleAnimation) {
            btn.animationStyle = MSSwipeCellActionAnimationStyleAnimation;
        }
        
        [_btnContainView addSubview:btn];
    }
}

- (void)setState:(MSSwipeCellState)state {
    _state = state;
    
    if (state == MSSwipeCellStateNormal) {
        self.tableView.scrollEnabled = YES;
        self.tableView.allowsSelection = YES;
        for (MSSwipeCell *cell in self.tableView.visibleCells) {
            if ([cell isKindOfClass:MSSwipeCell.class]) {
                cell.sideslip = NO;
            }
        }
        
    } else if (state == MSSwipeCellStateAnimating) {
        
    } else if (state == MSSwipeCellStateOpen) {
        self.tableView.scrollEnabled = NO;
        self.tableView.allowsSelection = NO;
        for (MSSwipeCell *cell in self.tableView.visibleCells) {
            if ([cell isKindOfClass:MSSwipeCell.class]) {
                cell.sideslip = YES;
            }
        }
    }
}

- (UITableView *)tableView {
    if (!_tableView) {
        id view = self.superview;
        while (view && [view isKindOfClass:[UITableView class]] == NO) {
            view = [view superview];
        }
        _tableView = (UITableView *)view;
        _tableViewPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewPan:)];
        _tableViewPan.delegate = self;
        [_tableView addGestureRecognizer:_tableViewPan];
    }
    return _tableView;
}

- (NSIndexPath *)indexPath {
    return [self.tableView indexPathForCell:self];
}
@end

#pragma mark - UITableView (MSSwipeCell)

@implementation UITableView (MSSwipeCell)
- (void)hiddenAllSideslip {
    for (MSSwipeCell *cell in self.visibleCells) {
        if ([cell isKindOfClass:MSSwipeCell.class]) {
            [cell hiddenSideslip:NO];
        }
    }
}
@end
