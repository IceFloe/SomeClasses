//
//  SMCardScanView.h
//

#import <UIKit/UIKit.h>

@interface SMCardScanView : UIView

+(instancetype)initCardScanViewWithSuccessBlock:(void (^)(NSString* cardNumber))successBlock cancelBlock:(void (^)())cancelBlock fromView:(UIView*)superView;

-(void)addToView:(UIView*)superView;
-(void)show;
-(void)hide;

@end
