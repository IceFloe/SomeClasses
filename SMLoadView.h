//
//  SMLoadView.h
//  SendMoney
//
//  Created by Алексей on 15.08.14.
//  Copyright (c) 2014 ua.privatbank. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    SMLoadViewLightStyle,
    SMLoadViewDarkStyle,
} SMLoadViewStyle;

@interface SMLoadView : UIView

@property (copy) void(^refreshBlock)();
@property (assign, nonatomic) BOOL isShowAlertView;
@property (assign, nonatomic) BOOL isShowErrorView;
@property (assign, nonatomic) SMLoadViewStyle style;
@property (strong, nonatomic) NSString* errorMessage;

-(void)addToView:(UIView*)superView;
-(void)setTask:(NSURLSessionDataTask*)task animated:(BOOL)animated;
-(void)show;
-(void)hide;

@end
