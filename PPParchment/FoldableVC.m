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
    UIImageView* _iv;
    
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
    
    _iv= [[UIImageView alloc] initWithFrame:self.view.bounds];
    _iv.image = [UIImage imageNamed:@"front.jpg"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.view.backgroundColor = [UIColor whiteColor];
    
    upperHalfShadowLayer = [CAShapeLayer layer];
    lowerHalfShadowLayer = [CAShapeLayer layer];

    
    upperHalfShadowLayer.anchorPoint = CGPointMake(0.5, 1.0);
    lowerHalfShadowLayer.anchorPoint = CGPointMake(0.5, 0.0);
    
    upperHalfShadowLayer.position = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    lowerHalfShadowLayer.position = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    
    upperHalfShadowLayer.bounds = CGRectMake(0, 0,
                                            self.view.bounds.size.width, self.view.bounds.size.height/2);
    lowerHalfShadowLayer.bounds = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height/2);

    // Shadows
    // TODO: remove unpleasant shadow from upper layer
    upperHalfShadowLayer.shadowPath = [UIBezierPath bezierPathWithRect:upperHalfShadowLayer.bounds].CGPath;
    lowerHalfShadowLayer.shadowPath = [UIBezierPath bezierPathWithRect:lowerHalfShadowLayer.bounds].CGPath;
    
    upperHalfShadowLayer.shadowColor = [UIColor blackColor].CGColor;
    upperHalfShadowLayer.shadowRadius = 10.0;
    upperHalfShadowLayer.shadowOpacity = 0.5;
    upperHalfShadowLayer.zPosition = 1;
    
    lowerHalfShadowLayer.shadowColor = [UIColor blackColor].CGColor;
    lowerHalfShadowLayer.shadowRadius = 10;
    lowerHalfShadowLayer.shadowOpacity = 0.5;
    lowerHalfShadowLayer.zPosition = 1;
    
    upperHalf = [CALayer layer];
    lowerHalf = [CALayer layer];
    upperHalf.frame = upperHalfShadowLayer.bounds;
    lowerHalf.frame = lowerHalfShadowLayer.bounds;

    upperHalf.transform = perspectiveIdentity();
    lowerHalf.transform = perspectiveIdentity();
    
    upperHalfShadowLayer.transform = perspectiveIdentity();
    lowerHalfShadowLayer.transform = perspectiveIdentity();
    
    
    _animatedView = [[UIView alloc] initWithFrame:self.view.bounds];
    
    [_animatedView.layer addSublayer:upperHalfShadowLayer];
    [_animatedView.layer addSublayer:lowerHalfShadowLayer];
    
    [upperHalfShadowLayer addSublayer:upperHalf];
    [lowerHalfShadowLayer addSublayer:lowerHalf];
    
    [self setupLayers];
    //curtainView.hidden = YES;
    [self.view addSubview:_animatedView];
    
    UITapGestureRecognizer *foldTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fold:)];
    [self.view addGestureRecognizer:foldTap];
}

- (void)setupLayers {
    CGImageRef imgRef = _iv.image.CGImage;
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
    //curtainView.hidden = NO;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:dur];
    {
        CATransform3D a = CATransform3DScale(upperHalfShadowLayer.transform, scale, scale, scale);
        CATransform3D b = CATransform3DScale(lowerHalfShadowLayer.transform, scale, scale, scale);
        
        
        // Left-right rotate
        /*
         leftPageShadowLayer.transform = CATransform3DRotate(leftPageShadowLayer.transform, RADIANS(7.5), 0.0, 1.0, 0.0);
         rightPageShadowLayer.transform = CATransform3DRotate(rightPageShadowLayer.transform, RADIANS(-7.5), 0.0, 1.0, 0.0);
         */
        
        //CATransform3D c = CATransform3DRotate(a, RADIANS(angle*2), 1.0, 0.0, 0.0);
        CATransform3D d = CATransform3DRotate(b, RADIANS(179.9), 1.0, 0.0, 0.0);
        
        upperHalfShadowLayer.transform = a;
        lowerHalfShadowLayer.transform = d;
    }
    [CATransaction commit];
    
    [self performSelector:@selector(moveAnimation)
               withObject:nil
               afterDelay:dur];
}

- (void)moveAnimation {
    CGFloat dist = self.view.bounds.size.width;
    
    CATransform3D a = CATransform3DInvert(upperHalfShadowLayer.transform);
    CATransform3D b = CATransform3DInvert(lowerHalfShadowLayer.transform);
    
    a = CATransform3DConcat(CATransform3DMakeTranslation(dist, 0, 0), a);
    b = CATransform3DConcat(CATransform3DMakeTranslation(dist, 0, 0), b);
    
    a = CATransform3DConcat(upperHalfShadowLayer.transform, a);
    b = CATransform3DConcat(lowerHalfShadowLayer.transform, b);
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:dur];
    {
        upperHalfShadowLayer.transform = a;
        lowerHalfShadowLayer.transform = b;
    }
    [CATransaction commit];
    
    [self performSelector:@selector(unfold)
               withObject:nil
               afterDelay:dur];
}

- (void)unfold
{
    //curtainView.hidden = YES;
    
    upperHalfShadowLayer.transform = perspectiveIdentity();
    lowerHalfShadowLayer.transform = perspectiveIdentity();
}

CATransform3D perspectiveIdentity()
{
    // Almost identity matrix (except for m34 which adds perspective)
    // DISCUSSION: http://www.songho.ca/opengl/gl_projectionmatrix.html
    
    return (CATransform3D) {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, -0.003, 0, 0, 0, 1};
}

@end
