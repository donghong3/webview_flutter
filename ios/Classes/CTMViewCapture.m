#import "CTMViewCapture.h"
@implementation WKWebView (CTMViewCapture)
-(void)CTMContentCaptureCompletionHandler:(void(^)(UIImage *capturedImage))completionHandler{

    CGPoint offset =self.scrollView.contentOffset;
    UIView *snapShotView = [self       snapshotViewAfterScreenUpdates:YES];
      snapShotView.frame =CGRectMake(self.frame.origin.x, self.frame.origin.y,snapShotView.frame.size.width, snapShotView.frame.size.height);

      [self.superview addSubview:snapShotView];
         if(self.frame.size.height < self.scrollView.contentSize.height){
        self.scrollView.contentOffset =CGPointMake(0, self.scrollView.contentSize.height - self.frame.size.height);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
    dispatch_get_main_queue(), ^{ self.scrollView.contentOffset = CGPointZero;
    [self CTMContentCaptureWithoutOffsetCompletionHandler:^(UIImage *capturedImage){
    self.scrollView.contentOffset = offset;
    [snapShotView removeFromSuperview];
    completionHandler(capturedImage);}];
});

}
-(void)CTMContentCaptureWithoutOffsetCompletionHandler:(void(^)(UIImage *capturedImage)) completionHandler{
    UIView *containerView = [[UIView alloc]initWithFrame:self.bounds];

    CGRect bakFrame = self.frame;
    UIView *bakSuperView = self.superview;
    NSInteger bakIndex = [self.superview.subviews indexOfObject:self];

    [self removeFromSuperview];
    [containerView addSubview:self];

    CGSize totalSize = self.scrollView.contentSize;

    float page = floorf(totalSize.height/containerView.bounds.size.height);

    self.frame = CGRectMake(0, 0, containerView.bounds.size.width, self.scrollView.contentSize.height);
    UIGraphicsBeginImageContextWithOptions(totalSize, false, [UIScreen mainScreen].scale);
    [self CTMContentPageDrawTargetView:containerView index:0 maxIndex:(int)page drawCallback:^{
        UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        [self removeFromSuperview];
        [bakSuperView insertSubview:self atIndex:bakIndex];

        self.frame = bakFrame;

        [containerView removeFromSuperview];

        completionHandler(capturedImage);
    }];

}

- (void)CTMContentPageDrawTargetView:(UIView *)targetView index:(int)index maxIndex:(int)maxIndex drawCallback:(void(^)())drawCallback{
    CGRect splitFrame = CGRectMake(0, (float)index * targetView.frame.size.height, targetView.bounds.size.width, targetView.frame.size.height);

    CGRect myFrame = self.frame;
    myFrame.origin.y = - ((float)index * targetView.frame.size.height);
    self.frame = myFrame;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [targetView drawViewHierarchyInRect:splitFrame afterScreenUpdates:YES];

        if(index<maxIndex){
            [self CTMContentPageDrawTargetView:targetView index:index + 1 maxIndex:maxIndex drawCallback:drawCallback];
        }else{
            drawCallback();
        }
    });
       
}

@end
