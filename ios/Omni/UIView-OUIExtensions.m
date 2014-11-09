// Copyright 2010-2011 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "UIView-OUIExtensions.h"
#import "OUIDrawing.h"
#import "OUILoadedImage.h"
#import "OQDrawing.h"
#import <UIKit/UIView.h>

#if !defined(SWAP)
#define SWAP(A, B) do { __typeof__(A) __temp = (A); (A) = (B); (B) = __temp;} while(0)
#endif

@implementation UIView (OUIExtensions)

- (UIImage *)snapshotImage;
{
    UIImage *image;
    CGRect bounds = self.bounds;
    
    OUIGraphicsBeginImageContext(bounds.size);
    {
        [self drawRect:bounds];
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    OUIGraphicsEndImageContext();
    
    return image;
}

- (id)containingViewOfClass:(Class)cls; // can return self
{
    UIView *view = self;
    while (view) {
        if ([view isKindOfClass:cls])
            return view;
        view = view.superview;
    }
    return nil;
}

// Subclass to return YES if this view has no border or doesn't want to be in your border finding nonsense.
- (BOOL)skipWhenComputingBorderEdgeInsets;
{
    return self.hidden || self.alpha == 0;
}

// Subclass to return YES for background-y type views that are just for grouping/positioning. Often this will just be a UIView so this shouldn't be needed.
- (BOOL)recurseWhenComputingBorderEdgeInsets;
{
    return [self class] == [UIView class];
}

- (UIEdgeInsets)borderEdgeInsets;
{
    // Shouldn't have called this, then.

    CGRect unionBorderRect = CGRectNull;
    
    if ([self class] != [UIView class]) {
        // We are either a concrete view of some sort that should define our border insets directly (even if we have implementation defined subviews like UIButton does), or we are a background/placement view of some sort that should define -ignoreWhenComputingBorderEdgeInsets to return YES. Default to using the entire frame for the concrete view case (not recursing and looking at the implementation detail views).
        if (!self.recurseWhenComputingBorderEdgeInsets)
            return UIEdgeInsetsZero;
    }
    
    // Default to looking through our subviews, finding their effective border rects and unioning that.
    for (UIView *subview in self.subviews) {
        if (subview.skipWhenComputingBorderEdgeInsets)
            continue;
        
        UIEdgeInsets subviewInsets = subview.borderEdgeInsets;
        
        CGRect borderRect = [self convertRect:UIEdgeInsetsInsetRect(subview.bounds, subviewInsets) fromView:subview];
        if (CGRectEqualToRect(unionBorderRect, CGRectNull))
            unionBorderRect = borderRect;
        else
            unionBorderRect = CGRectUnion(unionBorderRect, borderRect);
    }

    // If no subviews have a border, this this is most likely a leaf view that wants default behavior of having its border go to the edge.
    if (CGRectEqualToRect(unionBorderRect, CGRectNull)) {
        // We also could someday support nested container UIViews that happen to currently have all their subviews hidden and so shouldn't count.
        // But having leaf "concrete" vews return OUINoBorderEdgeInsets here by default means that they will get cut off by default when grouped in a parent UIView.
        
        return UIEdgeInsetsZero;
    }
    
    // Now, calculate the effective inset from our bounds
    CGRect bounds = self.bounds;
    return (UIEdgeInsets){
        .top = CGRectGetMinY(unionBorderRect) - CGRectGetMinY(bounds),
        .left = CGRectGetMinX(unionBorderRect) - CGRectGetMinX(bounds),
        .right = CGRectGetMaxX(bounds) - CGRectGetMaxX(unionBorderRect),
        .bottom = CGRectGetMaxY(bounds) - CGRectGetMaxY(unionBorderRect),
    };
}

@end


#pragma mark -
#pragma mark Rectangular shadows

static struct {
    OUILoadedImage top;
    OUILoadedImage bottom;
    OUILoadedImage left;
    OUILoadedImage right;
} ShadowImages;

static void LoadShadowImages(void)
{
    if (ShadowImages.top.image)
        return;
    
#if 0 && defined(DEBUG)
    // Code to make the shadow image (which I'll then dice up by hand into pieces).
    {
        static const CGFloat kPreviewShadowOffset = 4;
        static const CGFloat kPreviewShadowRadius = 12;
        
        CGColorSpaceRef graySpace = CGColorSpaceCreateDeviceGray();
        CGFloat totalShadowSize = kPreviewShadowOffset + kPreviewShadowRadius; // worst case; less on sides and top.
        CGSize imageSize = CGSizeMake(8*totalShadowSize, 8*totalShadowSize);
        
        CGFloat shadowComponents[] = {0, 0.5};
        CGColorRef shadowColor = CGColorCreate(graySpace, shadowComponents);
        UIImage *shadowImage;
        
        OUIGraphicsBeginImageContext(imageSize);
        {
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            
            CGRect imageBounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
            OQFlipVerticallyInRect(ctx, imageBounds);
            
            CGRect boxRect = CGRectInset(imageBounds, totalShadowSize, totalShadowSize);
            
            CGContextSetShadowWithColor(ctx, CGSizeMake(0, kPreviewShadowOffset), kPreviewShadowRadius, shadowColor);
            
            CGFloat whiteComponents[] = {1.0, 1.0};
            CGColorRef white = CGColorCreate(graySpace, whiteComponents);
            CGContextSetFillColorWithColor(ctx, white);
            CGColorRelease(white);

            CGContextFillRect(ctx, boxRect);
            
            shadowImage = UIGraphicsGetImageFromCurrentImageContext();
        }
        OUIGraphicsEndImageContext();
        
        CGColorRelease(shadowColor);
        CFRelease(graySpace);

        NSData *shadowImagePNGData = UIImagePNGRepresentation(shadowImage);
        NSError *error = nil;
        NSString *path = [@"~/Documents/shadow.png" stringByExpandingTildeInPath];
        if (![shadowImagePNGData writeToFile:path options:0 error:&error])
            NSLog(@"Unable to write %@: %@", path, [error toPropertyList]);
        else
            NSLog(@"Wrote %@", path);
    }
#endif
    
    OUILoadImage(@"OUIShadowBorderBottom.png", &ShadowImages.bottom);
    OUILoadImage(@"OUIShadowBorderTop.png", &ShadowImages.top);
    OUILoadImage(@"OUIShadowBorderLeft.png", &ShadowImages.left);
    OUILoadImage(@"OUIShadowBorderRight.png", &ShadowImages.right);
    
}

static void _addShadowEdge(UIView *self, const OUILoadedImage *imageInfo, NSMutableArray *edges)
{
    UIView *edge = [[UIView alloc] init];
    edge.layer.needsDisplayOnBoundsChange = NO;
    [self addSubview:edge];
    
    edge.layer.contents = (id)[imageInfo->image CGImage];
    
    // Exactly one dimension should have an odd pixel count. This center column or row will get stretched via the contentsCenter property on the layer.
#ifdef OMNI_ASSERTIONS_ON
    CGSize imageSize = imageInfo->size;
#endif
    
    //edge.layer.magnificationFilter = kCAFilterNearest;
    //edge.layer.contentsGravity = kCAGravityResize;
    //edge.layer.contentsRect = CGRectMake(0, 0, 1.0, 1.0);
    
    /*
     contentsCenter is in normalized [0,1] coordinates, but the header also says:
     
     "As a special case, if the width or height is zero, it is implicitly adjusted to the width or height of a single source pixel centered at that position."
     
     */
    edge.layer.contentsCenter = CGRectMake(0.5, 0.5, 0, 0);
    
    [edges addObject:edge];
    [edge release];
}

//static void _addShadowEdge(UIView *self, const OUILoadedImage *imageInfo, NSMutableArray *edges)
//{
//    // Exactly one dimension should have an odd pixel count. This center column or row will get stretched via the contentsCenter property on the layer.
//#ifdef OMNI_ASSERTIONS_ON
//    CGSize imageSize = imageInfo->size;
//#endif
//    OBASSERT(imageSize.width == rint(imageSize.width));
//    OBASSERT(imageSize.height == rint(imageSize.height));
//    OBASSERT(((int)imageSize.width & 1) ^ ((int)imageSize.height & 1));
//    
//    UIImageView *edge = [[UIImageView alloc] initWithImage:imageInfo->image];
//    [self addSubview:edge];
//    
//    edge.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
//    
//    [edges addObject:edge];
//    [edge release];
//}

NSArray *OUIViewAddShadowEdges(UIView *self)
{
    NSMutableArray *edges = [NSMutableArray array];
    
    LoadShadowImages();
    
    _addShadowEdge(self, &ShadowImages.bottom, edges);
    _addShadowEdge(self, &ShadowImages.top, edges);
    _addShadowEdge(self, &ShadowImages.left, edges);
    _addShadowEdge(self, &ShadowImages.right, edges);
    
#if 0 && defined(DEBUG_robin)
    CGFloat hue = 0;
    for (UIView *edge in edges) {
        edge.backgroundColor = [UIColor colorWithHue:hue saturation:0 brightness:1 alpha:1];
        hue += 0.25;
    }
    
//    UIImageView *shadowTestView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OUIShadowBorderBottom.png"]];
//    shadowTestView.center = self.center;
//    shadowTestView.bounds = CGRectMake(0, 0, CGRectGetWidth(self.bounds), 16);
//    shadowTestView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
//    shadowTestView.backgroundColor = [UIColor whiteColor];
//    [self addSubview:shadowTestView];
//    [shadowTestView release];
#endif
    
    return edges;
}

void OUIViewLayoutShadowEdges(UIView *self, NSArray *shadowEdges, BOOL flipped)
{
    if ([shadowEdges count] != 4) {
        return;
    }
    
    struct {
        UIView *bottom;
        UIView *top;
        UIView *left;
        UIView *right;
    } edges;
    
    [shadowEdges getObjects:(id *)&edges];
    
    
    CGRect bounds = self.bounds;
    

    // TODO: We'll want one or more multi-part images that have the shadow pre rendered and offset.
    static const CGFloat kShadowSize = 16;
    
    CGRect topRect = CGRectMake(CGRectGetMinX(bounds) - kShadowSize, CGRectGetMaxY(bounds), CGRectGetWidth(bounds) + 2*kShadowSize, kShadowSize);
    CGRect bottomRect = CGRectMake(CGRectGetMinX(bounds) - kShadowSize, CGRectGetMinY(bounds) - kShadowSize, CGRectGetWidth(bounds) + 2*kShadowSize, kShadowSize);
    
    if (flipped)
        SWAP(topRect, bottomRect);
    
    // These cover the corners too.
    edges.bottom.frame = bottomRect;
    edges.top.frame = topRect;
    
    edges.left.frame = CGRectMake(CGRectGetMinX(bounds) - kShadowSize, CGRectGetMinY(bounds), kShadowSize, CGRectGetHeight(bounds));
    edges.right.frame = CGRectMake(CGRectGetMaxX(bounds), CGRectGetMinY(bounds), kShadowSize, CGRectGetHeight(bounds));
}

#ifdef NS_BLOCKS_AVAILABLE

// Allows the caller to conditionally leave animations as they were or disable them. Won't ever force animations on.
void OUIWithAnimationsDisabled(BOOL disabled, void (^actions)(void))
{
    if (disabled)
        OUIWithoutAnimating(actions);
    else
        actions();
}

void OUIWithoutAnimating(void (^actions)(void))
{
    BOOL wasAnimating = [UIView areAnimationsEnabled];
    @try {
        if (wasAnimating)
            [UIView setAnimationsEnabled:NO];
        actions();
    } @finally {
        if (wasAnimating)
            [UIView setAnimationsEnabled:YES];
    }
}

void OUIWithAppropriateLayerAnimations(void (^actions)(void))
{
    BOOL shouldAnimate = [UIView areAnimationsEnabled];
    
    [CATransaction begin];
    [CATransaction setValue:shouldAnimate ? (id)kCFBooleanFalse : (id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    actions();
    [CATransaction commit];
}

#endif

