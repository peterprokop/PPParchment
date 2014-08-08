//
//  FoldableVC.m
//  NavigationControllerTransparencyTest
//
//  Created by Peter Prokop on 08/08/14.
//  Copyright (c) 2014 CandyCan. All rights reserved.
//

#import "FoldableVC.h"

const double degToRadRatio = M_PI/180.0;
#define RADIANS(x) ((x) * degToRadRatio)

@interface FoldableVC () {
    CALayer* upperHalf;
    CALayer* lowerHalf;
    UIView* _animatedView;
    
    CAShapeLayer* upperHalfShadowLayer;
    CAShapeLayer* lowerHalfShadowLayer;
}

@end

@implementation FoldableVC


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.view.backgroundColor = [UIColor whiteColor];

    
    upperHalf = [CALayer layer];
    lowerHalf = [CALayer layer];
    
    upperHalf.transform = perspectiveIdentity();
    lowerHalf.transform = perspectiveIdentity();
    
    
    upperHalf.anchorPoint = CGPointMake(0.5, 1.0);
    lowerHalf.anchorPoint = CGPointMake(0.5, 0.0);
    
    upperHalf.position = CGPointMake(self.view.bounds.size.width/2,
                                     self.view.bounds.size.height/2);
    lowerHalf.position = CGPointMake(self.view.bounds.size.width/2,
                                     self.view.bounds.size.height/2);
    
    upperHalf.bounds = CGRectMake(0,
                                  0,
                                  self.view.bounds.size.width,
                                  self.view.bounds.size.height/2);
    lowerHalf.bounds = CGRectMake(0,
                                  0,
                                  self.view.bounds.size.width,
                                  self.view.bounds.size.height/2);
    
    _animatedView = [[UIView alloc] initWithFrame:self.view.bounds];
    
    [_animatedView.layer addSublayer:upperHalf];
    [_animatedView.layer addSublayer:lowerHalf];

    [self setupLayers];
    _animatedView.hidden = YES;
    
    // All views have a superview, right?
    [self.view.superview addSubview:_animatedView];
    
    UITapGestureRecognizer *foldTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fold:)];
    [self.view addGestureRecognizer:foldTap];
}

- (void)setupLayers {
    CGImageRef imgRef = [self captureView]; //_iv.image.CGImage;
    upperHalf.contents = (__bridge id)imgRef;
    lowerHalf.contents = (__bridge id)imgRef;

    // Top
    upperHalf.contentsRect = CGRectMake(0.0, 0.0, 1.0, 0.5);
    
    
    // Bottom
    lowerHalf.contentsRect = CGRectMake(0.0, 0.5, 1.0, 0.5);
    
    // Left-right
    /*
     // Left
     leftPage.contentsRect = CGRectMake(0.0, 0.0, 0.5, 1.0);
     
     // Right
     rightPage.contentsRect = CGRectMake(0.5, 0.0, 0.5, 1.0);
     */
}

const CGFloat scale = 0.5;
const CGFloat angle = 90;
const NSTimeInterval dur = 1;

- (void)fold:(UITapGestureRecognizer *)gr
{
    [self setupLayers];
    _animatedView.hidden = NO;
    self.view.hidden = YES;
    
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:dur];
    {
        CATransform3D a = CATransform3DScale(upperHalf.transform, scale, scale, scale);
        CATransform3D b = CATransform3DScale(lowerHalf.transform, scale, scale, scale);
        
        
        // Left-right rotate
        /*
         leftPageShadowLayer.transform = CATransform3DRotate(leftPageShadowLayer.transform, RADIANS(7.5), 0.0, 1.0, 0.0);
         rightPageShadowLayer.transform = CATransform3DRotate(rightPageShadowLayer.transform, RADIANS(-7.5), 0.0, 1.0, 0.0);
         */
        
        //CATransform3D c = CATransform3DRotate(a, RADIANS(angle*2), 1.0, 0.0, 0.0);
        CATransform3D d = CATransform3DRotate(b, RADIANS(179.9), 1.0, 0.0, 0.0);
        
        upperHalf.transform = a;
        lowerHalf.transform = d;
    }
    [CATransaction commit];
    
    [self performSelector:@selector(moveAnimation)
               withObject:nil
               afterDelay:dur];
}

- (void)moveAnimation {
    CGFloat dist = self.view.bounds.size.width;
    
    CATransform3D a = CATransform3DInvert(upperHalf.transform);
    CATransform3D b = CATransform3DInvert(lowerHalf.transform);
    
    a = CATransform3DConcat(CATransform3DMakeTranslation(dist, 0, 0), a);
    b = CATransform3DConcat(CATransform3DMakeTranslation(dist, 0, 0), b);
    
    a = CATransform3DConcat(upperHalf.transform, a);
    b = CATransform3DConcat(lowerHalf.transform, b);
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:dur];
    {
        upperHalf.transform = a;
        lowerHalf.transform = b;
    }
    [CATransaction commit];
    
    [self performSelector:@selector(unfold)
               withObject:nil
               afterDelay:dur];
}

- (void)unfold
{
    [CATransaction begin];
    [CATransaction setAnimationDuration:dur];
    {
        upperHalf.transform = perspectiveIdentity();
        lowerHalf.transform = perspectiveIdentity();
    }
    [CATransaction commit];
    
    [self performSelector:@selector(finalize)
               withObject:nil
               afterDelay:dur];
}

- (void)finalize
{
    _animatedView.hidden = YES;
    self.view.hidden = NO;
}

CATransform3D perspectiveIdentity()
{
    // Almost identity matrix (except for m34 which adds perspective)
    // DISCUSSION: http://www.songho.ca/opengl/gl_projectionmatrix.html
    
    return (CATransform3D) {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, -0.003, 0, 0, 0, 1};
}

- (CGImageRef)captureView {
    CGRect screenRect = self.view.bounds;
    
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] set];
    CGContextFillRect(ctx, screenRect);
    
    [self.view.layer renderInContext:ctx];
    
    CGImageRef result = CGBitmapContextCreateImage(UIGraphicsGetCurrentContext());
    //CGImageRef result = UIGraphicsGetImageFromCurrentImageContext().CGImage;
    
    UIGraphicsEndImageContext();
    
    return result;
}

@end
