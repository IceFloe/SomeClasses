//
//  SMCardScanView.h
//  SendMoney
//
//  Created by Алексей on 09.09.14.
//  Copyright (c) 2014 ua.privatbank. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMCardScanView : UIView

+(instancetype)initCardScanViewWithSuccessBlock:(void (^)(NSString* cardNumber))successBlock cancelBlock:(void (^)())cancelBlock fromView:(UIView*)superView;

-(void)addToView:(UIView*)superView;
-(void)show;
-(void)hide;

@end
