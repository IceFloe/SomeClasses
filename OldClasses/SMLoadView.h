//
//  SMLoadView.h
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
