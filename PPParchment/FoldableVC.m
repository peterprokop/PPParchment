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
#define NUM_FOLDS 8

const NSTimeInterval dur = 1;

@interface FoldableVC () {
    CALayer* firstHalf;
    CALayer* secondHalf;

    UIView* _animatedView;
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
    
    // Create a view and add sublayers to it's layer
    _animatedView = [[UIView alloc] initWithFrame:self.view.bounds];
    
    [self createSublayersForLayer:_animatedView.layer];
    
    _animatedView.hidden = YES;
    
    // All views have a superview, right?
    [self.view.superview addSubview:_animatedView];
    
    UITapGestureRecognizer *r = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(fold)];
    [self.view addGestureRecognizer:r];
}

- (void)repositionSublayersForDepth:(NSUInteger)depth {
    NSUInteger d1 = ceil(depth/2.);
    NSUInteger d2 = floor(depth/2.);
    
    CGFloat height = self.view.bounds.size.height * pow(0.5, d1);
    CGFloat width = self.view.bounds.size.width * pow(0.5, d2);
    
    CGSize layerSize = CGSizeMake(width, height);
    CGRect frame = CGRectMake((self.view.bounds.size.width - width)/2,
                              (self.view.bounds.size.height - height)/2,
                              width,
                              height);

    BOOL isLayerVertical =
        (layerSize.height > layerSize.width);
    
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    {
        firstHalf.transform = perspectiveIdentity();
        secondHalf.transform = perspectiveIdentity();

        CGRect bounds = CGRectMake(0,
                                   0,
                                   layerSize.width,
                                   layerSize.height/2);
        
        if(!isLayerVertical) {
            bounds = CGRectMake(0,
                                0,
                                layerSize.width/2,
                                layerSize.height);
        }
        
        firstHalf.bounds = bounds;
        secondHalf.bounds = bounds;
        
        
        if(isLayerVertical) {
            firstHalf.anchorPoint = CGPointMake(0.5, 1.0);
            secondHalf.anchorPoint = CGPointMake(0.5, 0.0);
        } else {
            firstHalf.anchorPoint = CGPointMake(1.0, 0.5);
            secondHalf.anchorPoint = CGPointMake(0.0, 0.5);
        }
        
        // Position of the anchor point in superlayer
        CGPoint pos = CGPointMake(frame.origin.x + layerSize.width/2,
                                  frame.origin.y + layerSize.height/2);
        firstHalf.position = pos;
        secondHalf.position = pos;
        
        // Shadows
        // TODO: remove unpleasant shadow from upper layer
        firstHalf.shadowPath = [UIBezierPath bezierPathWithRect:firstHalf.bounds].CGPath;
        secondHalf.shadowPath = [UIBezierPath bezierPathWithRect:secondHalf.bounds].CGPath;
        
        firstHalf.shadowColor = [UIColor blackColor].CGColor;
        firstHalf.shadowRadius = 10;
        firstHalf.shadowOpacity = 0.9;
        firstHalf.zPosition = 1;
        
        secondHalf.shadowColor = [UIColor blackColor].CGColor;
        secondHalf.shadowRadius = 10;
        secondHalf.shadowOpacity = 0.9;
        secondHalf.zPosition = 1;
        
        firstHalf.transform = CATransform3DScale(firstHalf.transform, pow(-1, d2), pow(-1, d1), 1);
        secondHalf.transform = CATransform3DScale(secondHalf.transform, pow(-1, d2), pow(-1, d1), 1);
    }
    [CATransaction commit];
}

- (void)createSublayersForLayer:(CALayer*)layer {
    firstHalf = [CALayer layer];
    secondHalf = [CALayer layer];
    
    [self repositionSublayersForDepth:0];
    
    [layer addSublayer:firstHalf];
    [layer addSublayer:secondHalf];
}

- (void)setupLayerContentsAtDepth:(NSUInteger)depth
                    captureScreen:(BOOL)captureScreen {
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    
    static CGImageRef imgRef;
    
    if(captureScreen)
        imgRef = [self captureView];
    
    firstHalf.contents = (__bridge id)imgRef;
    secondHalf.contents = (__bridge id)imgRef;

    // I still don't understand how it works =)
    NSUInteger d1 = ceil(depth/2.);
    NSUInteger d2 = floor(depth/2.);
    
    CGFloat h = pow(0.5, d1);
    CGFloat w = pow(0.5, d2);
    CGFloat x = 1 - w;
    CGFloat y = 1 - h;
    
    secondHalf.contentsRect = CGRectMake(x, y, w, h);
    
    if(depth % 2)
        firstHalf.contentsRect = CGRectMake(x, y - h, w, h);
    else
        firstHalf.contentsRect = CGRectMake(x - w, y, w, h);
    
    [CATransaction commit];
}

- (void)fold
{
    [self foldAtDepth:@1];
}


- (void)foldAtDepth:(NSNumber*)depthWrapper {
    NSUInteger depth = depthWrapper.intValue;
    CGFloat localDur = dur * pow(0.5, MIN(2, depth-1));
    
    [self setupLayerContentsAtDepth:depth
                      captureScreen:depth == 1];
    
    if(depth == 1) {
        _animatedView.hidden = NO;
        self.view.hidden = YES;
    } else {
        [self repositionSublayersForDepth:depth-1];
    }

    NSString* rotationKP = @"transform.rotation.x";
    NSString* translationKP = @"transform.translation.y";
    if(depth % 2 == 0) {
        rotationKP = @"transform.rotation.y";
        translationKP = @"transform.translation.x";
    }
    
    // Rotation
    CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:rotationKP];
    rotate.toValue = @(M_PI);
    rotate.duration = localDur;
    rotate.removedOnCompletion = NO;
    rotate.fillMode = kCAFillModeBoth;
    
    
    // Transaltion
    CGFloat distance = self.view.bounds.size.height/2 - (firstHalf.frame.origin.y + firstHalf.frame.size.height/2);
    
    if(depth % 2 == 0) {
        distance = self.view.bounds.size.width/2 - (firstHalf.frame.origin.x + firstHalf.frame.size.width/2);
    }
    
    CABasicAnimation* translation;
    translation = [CABasicAnimation animationWithKeyPath:translationKP];
    translation.toValue = [NSNumber numberWithFloat:distance];
    translation.duration = localDur;
    translation.removedOnCompletion = NO;
    translation.fillMode = kCAFillModeBoth;
    
    // Group
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = [NSArray arrayWithObjects:rotate, translation, nil];
    group.duration = localDur;
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeBoth;

    [secondHalf addAnimation:group forKey:@"myAnim"];
    [firstHalf addAnimation:translation forKey:@"transAnim"];
    
    if(depth == NUM_FOLDS) {
        [self performSelector:@selector(moveAnimation)
                   withObject:nil
                   afterDelay:localDur];
    } else {
        [self performSelector:@selector(foldAtDepth:)
                   withObject:@(depth + 1)
                   afterDelay:localDur];
    }
}

- (void)moveAnimation {
    CGFloat dist = self.view.bounds.size.width;
    
    CABasicAnimation* translation;
    translation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    translation.toValue = [NSNumber numberWithFloat:dist];
    translation.duration = dur;
    translation.removedOnCompletion = NO;
    translation.fillMode = kCAFillModeBoth;
    
    [firstHalf addAnimation:translation forKey:@"lastTrans"];
    [secondHalf addAnimation:translation forKey:@"lastTrans"];
    
    
    [self performSelector:@selector(unfold)
               withObject:nil
               afterDelay:dur];
}

- (void)unfold {
    [firstHalf removeAllAnimations];
    [secondHalf removeAllAnimations];
    
    [self repositionSublayersForDepth:0];
    [self setupLayerContentsAtDepth:1
                      captureScreen:NO];
    
    [self performSelector:@selector(finalize)
               withObject:nil
               afterDelay:dur];
}

- (void)finalize
{
    _animatedView.hidden = YES;
    self.view.hidden = NO;
}

CATransform3D perspectiveIdentity() {
    // Almost identity matrix (except for m34 which adds perspective)
    // DISCUSSION: http://www.songho.ca/opengl/gl_projectionmatrix.html
    
    return (CATransform3D) {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, -0.003, 0, 0, 0, 1};
}

void printTransform(CATransform3D t ) {
    NSLog(@"\nTransform: \n %f %f %f %f \n %f %f %f %f \n %f %f %f %f \n %f %f %f %f \n",
          t.m11, t.m12, t.m13, t.m14,
          t.m21, t.m22, t.m23, t.m24,
          t.m31, t.m32, t.m33, t.m34,
          t.m41, t.m42, t.m43, t.m44);
}

- (CGImageRef)captureView {
    CGRect screenRect = self.view.bounds;
    
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] set];
    CGContextFillRect(ctx, screenRect);
    
    [self.view.layer renderInContext:ctx];
    
    CGImageRef result = CGBitmapContextCreateImage(UIGraphicsGetCurrentContext());
    
    UIGraphicsEndImageContext();
    
    return result;
}

@end
