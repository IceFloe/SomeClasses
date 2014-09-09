//
//  SMCardScanView.m
//  SendMoney
//
//  Created by Алексей on 09.09.14.
//  Copyright (c) 2014 ua.privatbank. All rights reserved.
//

#import "SMCardScanView.h"
#import "CardIO.h"
#import "UIImage+ImageEffects.h"


@interface SMCardScanView () <CardIOViewDelegate>

@property (strong, nonatomic) UIImageView* blurView;
@property (strong, nonatomic) CardIOView* scanCardView;
@property (strong, nonatomic) UIButton* cancel;

@property (copy) void(^cancelBlock)();
@property (copy) void(^successBlock)(NSString* cardNumber);

@end

@implementation SMCardScanView

-(instancetype)init{
    self = [super init];
    
    if(self){
        
    }
    
    return self;
}

+(instancetype)initCardScanViewWithSuccessBlock:(void (^)(NSString *))successBlock cancelBlock:(void (^)())cancelBlock fromView:(UIView *)superView{
    SMCardScanView* view = [[SMCardScanView alloc] init];
    view.cancelBlock = cancelBlock;
    view.successBlock = successBlock;
    
    [view addToView:superView];
    
    return view;
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self addSubviews];
        [self defaultInit];
    }
    
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    if(self){
        [self addSubviews];
        [self defaultInit];
    }
    
    return self;
}

-(void)defaultInit{
    self.hidden = YES;
    self.alpha = 0;
    self.translatesAutoresizingMaskIntoConstraints = NO;
}

-(IBAction)cancel:(id)sender{
    
    if (self.cancelBlock) {
        self.cancelBlock();
    }
    
    [self hide];
}

- (void)cardIOView:(CardIOView *)cardIOView didScanCard:(CardIOCreditCardInfo *)info {
    if (info) {
        // The full card number is available as info.cardNumber, but don't log that!
//        NSLog(@"Received card info. Number: %@, expiry: %02i/%i, cvv: %@.", info.redactedCardNumber, info.expiryMonth, info.expiryYear, info.cvv);
        
        if (self.successBlock) {
            self.successBlock(info.cardNumber);
        }
    }
    else {
        NSLog(@"User cancelled payment info");
        
    }
    
    [self hide];
}

-(void)addToView:(UIView *)superView{
    [superView addSubview:self];
    
    
    UIView* view = self;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    [superView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[view]-0-|" options:0 metrics:nil views:views]];
    [superView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:0 metrics:nil views:views]];
}

-(void)show{
    [self startAnimating:YES];
}

-(void)hide{
    [self stopAnimating:YES];
}

- (void)startAnimating:(BOOL)animated {

    self.hidden = NO;
    self.scanCardView.hidden = NO;
    
    if (!self.blurView.image) {
        UIGraphicsBeginImageContextWithOptions(self.superview.bounds.size, NO, self.window.screen.scale);
        [self.superview drawViewHierarchyInRect:self.superview.frame afterScreenUpdates:YES];
        UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIImage *blurredSnapshotImage;

        blurredSnapshotImage = [snapshotImage applyDarkEffect];

        UIGraphicsEndImageContext();
        
        self.blurView.image = blurredSnapshotImage;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 1;
        } completion:^(BOOL finished) {
            
        }];
    }else{
        self.alpha = 1;
    }
}

- (void)stopAnimating:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            self.hidden = YES;
            self.scanCardView.hidden = YES;
            self.blurView.image = nil;
        }];
    } else {
        self.alpha = 0;
        self.hidden = YES;
        self.scanCardView.hidden = YES;
        self.blurView.image = nil;
    }
}


-(void)addSubviews{
    
    ////////Blur
    self.blurView = [[UIImageView alloc] init];
    self.blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.blurView];
    
    UIView* blurView = self.blurView;
    NSDictionary *views = NSDictionaryOfVariableBindings(blurView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[blurView]-0-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[blurView]-0-|" options:0 metrics:nil views:views]];
    
    ////////Card
    
    self.scanCardView = [[CardIOView alloc] initWithFrame:CGRectZero];
    self.scanCardView.appToken = @"77a704abeaac483fafa6e5aa33a2ee4c";
    self.scanCardView.delegate = self;
    self.backgroundColor = [UIColor whiteColor];
    self.scanCardView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:self.scanCardView];
    
    UIView* scanCardView = self.scanCardView;
    UIView *superview = self;
    views = NSDictionaryOfVariableBindings(scanCardView, superview);
    NSArray *constraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[scanCardView]"
                                            options: NSLayoutFormatAlignAllCenterX
                                            metrics:nil
                                              views:views];
    [self addConstraints:constraints];
    
    constraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"H:[superview]-(<=1)-[scanCardView]"
                                            options: NSLayoutFormatAlignAllCenterY
                                            metrics:nil
                                              views:views];
    [self addConstraints:constraints];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[scanCardView]-0-|" options:0 metrics:nil views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.scanCardView
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.scanCardView
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:0.75f
                                                      constant:0]];
    
    ////////Button
    self.cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancel setTitle:@"Cancel" forState:UIControlStateNormal];
    self.cancel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:self.cancel];
    
    UIView* cancel = self.cancel;
    views = NSDictionaryOfVariableBindings(cancel);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-16-[cancel]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[cancel]" options:0 metrics:nil views:views]];

}


@end
