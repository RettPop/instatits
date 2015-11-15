//
//  ITViewController.m
//  InstaTits
//
//  Created by Rett Pop on 22.12.13.
//  Copyright (c) 2013 SapiSoft. All rights reserved.
//

#import "ITViewController.h"
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>
#import "UIImage+UIImageFunctions.h"

#define LOGRect(x) NSLog(@"Logging Rect %s: %@", (#x), NSStringFromCGRect(x))

#ifdef DEBUG
#define DLog( s, ... ) NSLog( @"%@%s:(%d)> %@", [[self class] description], __PRETTY_FUNCTION__ , __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#define DAssert(A, B, ...) NSAssert(A, B, ##__VA_ARGS__);
#define DLogv( var ) NSLog( @"%@%s:(%d)> "# var "=%@", [[self class] description], __PRETTY_FUNCTION__ , __LINE__, var ] )
#elif DEBUG_PROD
#define DLog( s, ... ) NSLog( @"%@%s:(%d)> %@", [[self class] description], __PRETTY_FUNCTION__ , __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#define DLogv( var ) NSLog( @"%@%s:(%d)> "# var "=%@", [[self class] description], __PRETTY_FUNCTION__ , __LINE__, var ] )
#define DAssert(A, B, ...) NSAssert(A, B, ##__VA_ARGS__);
#else
#define DLog( s, ... )
#define DAssert(...)
#define DLogv(...)
#endif
#define LOGLINE DLog(@"")

// return true if the device has a retina display, false otherwise
#define IS_RETINA_DISPLAY() [[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0f

// return the scale value based on device's display (2 retina, 1 other)
#define DISPLAY_SCALE IS_RETINA_DISPLAY() ? 2.0f : 1.0f

// if the device has a retina display return the real scaled pixel size, otherwise the same size will be returned
#define PIXEL_SIZE(size) IS_RETINA_DISPLAY() ? CGSizeMake(size.width/2.0f, size.height/2.0f) : size
static inline double radians (double degrees) {return degrees * M_PI/180;}


@interface ITViewController ()
{
    BOOL _drawBeard;
}
@property(nonatomic, strong) UIButton *btnTakePhoto;
@property(nonatomic, strong) UIButton *btnTakePhotoBeard;
@property(nonatomic, strong) UIImageView *imgView;

@end

@implementation ITViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _btnTakePhoto = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_btnTakePhoto setTitle:@"Take photo" forState:UIControlStateNormal];
    [_btnTakePhoto setFrame:CGRectMake(0, 0, 100, 44)];
    [_btnTakePhoto setCenter:CGPointMake(CGRectGetMidX([[self view] bounds]) - CGRectGetWidth([_btnTakePhoto bounds]),
                                         CGRectGetMaxY([[self view] bounds]) - CGRectGetHeight([_btnTakePhoto frame]))];
    [[self view] addSubview:_btnTakePhoto];
    [_btnTakePhoto addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [_btnTakePhoto setBackgroundColor:[UIColor purpleColor]];
    
    
    _btnTakePhotoBeard = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_btnTakePhotoBeard setTitle:@"with Beard" forState:UIControlStateNormal];
    [_btnTakePhotoBeard setFrame:CGRectMake(0, 0, 100, 44)];
    [_btnTakePhotoBeard setCenter:CGPointMake(CGRectGetMidX([[self view] bounds]) + CGRectGetWidth([_btnTakePhoto bounds]),
                                         CGRectGetMaxY([[self view] bounds]) - CGRectGetHeight([_btnTakePhoto frame]))];
    [[self view] addSubview:_btnTakePhotoBeard];
    [_btnTakePhotoBeard addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [_btnTakePhotoBeard setBackgroundColor:[UIColor yellowColor]];
    
    
//    UIBarButtonItem *btnTakePhoto = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePhoto)];
//    [[self navigationItem] setRightBarButtonItem:btnTakePhoto];
    
    _imgView = [[UIImageView alloc] initWithFrame:[[self view] bounds]];
    [_imgView setBackgroundColor:[UIColor whiteColor]];
    [[self view] addSubview:_imgView];
    [[self view] sendSubviewToBack:_imgView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)takePhoto:(UIButton *)sender
{
    _drawBeard = (sender == _btnTakePhotoBeard);
    
    [_imgView setImage:nil];
    [[_imgView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UIImagePickerController *imgPic = [[UIImagePickerController alloc] init];
    if( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] )
    {
        [imgPic setSourceType:UIImagePickerControllerSourceTypeCamera];
    }
    else
    {
        [imgPic setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    [imgPic setDelegate:self];
    [self presentViewController:imgPic animated:YES completion:nil];
    imgPic = nil;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    DLog(@"Start");
    UIImage *imgTaken = [info objectForKey:UIImagePickerControllerOriginalImage];
    CGFloat horizAspect = 320.f / imgTaken.size.width;
    UIImage *rotateimg = nil;
    rotateimg = rotate(imgTaken, UIImageOrientationDown);
    UIImage *scaleImg = [rotateimg scaleToSize:CGSizeMake(imgTaken.size.width * horizAspect, imgTaken.size.height * horizAspect)];
    [_imgView setContentMode:UIViewContentModeTopLeft];
    [_imgView setClipsToBounds:YES];
    [_imgView setImage:scaleImg];
    [_imgView setFrame:CGRectMake(0, 0, scaleImg.size.width, scaleImg.size.height)];
//    _imgView.layer.borderColor = [UIColor redColor].CGColor;
//    _imgView.layer.borderWidth = .5f;
    [self faceDetect];
    [self dismissViewControllerAnimated:YES completion:^(void){
    }];
//    [self performSelectorInBackground:@selector(faceDetect) withObject:nil];
    DLog(@"Finish");
}

UIImage* rotate(UIImage* src, UIImageOrientation orientation)
{
    NSLog(@"Start");
    UIGraphicsBeginImageContext(src.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orientation == UIImageOrientationRight)
    {
        CGContextRotateCTM (context, radians(90));
    }
    else if (orientation == UIImageOrientationLeft)
    {
        CGContextRotateCTM (context, radians(-90));
    }
    else if (orientation == UIImageOrientationDown)
    {
        // NOTHING
    }
    else if (orientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, radians(90));
    }
    
    [src drawAtPoint:CGPointMake(0, 0)];
    
    NSLog(@"Finish");
    return UIGraphicsGetImageFromCurrentImageContext();
}

-(void)faceDetect
{
    DLog(@"Start");
    // Execute the method used to markFaces in background
    UIImageView * newImg = [[UIImageView alloc] initWithFrame:[_imgView frame]];
    BOOL res = [self markFaces:_imgView targetView:newImg];

    if( res )
    {
        // flip the entire window to make everything right side up
        [newImg setTransform:CGAffineTransformMakeScale(1, -1)];
        [_imgView addSubview:newImg];
    }
    else
    {
//        [self takePhoto];
    }
    newImg = nil;
    DLog(@"Finish");
}

-(BOOL)markFaces:(UIImageView *)facePicture targetView:(UIImageView *)targetView
{
    LOGLINE;
    // draw a CI image with the previously loaded face detection picture
    CIImage* image = [CIImage imageWithCGImage:facePicture.image.CGImage];
    // create a face detector - since speed is not an issue we'll use a high accuracy
    // detector
    LOGLINE;
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    // create an array containing all the detected faces from the detector
    LOGLINE;
    NSArray* features = [detector featuresInImage:image];
    // we'll iterate through every detected face. CIFaceFeature provides us
    // with the width for the entire face, and the coordinates of each eye
    // and the mouth if detected. Also provided are BOOL's for the eye's and
    // mouth so we can check if they already exist.
    if( [features count] ==  0 ) {
        return NO;
    }
    
    LOGLINE;
    for(CIFaceFeature* faceFeature in features)
    {
        LOGLINE;
        // get the width of the face
        CGFloat faceWidth = faceFeature.bounds.size.width;
        
        // create a UIView using the bounds of the face
        UIView* faceView = [[UIView alloc] initWithFrame:faceFeature.bounds];
        
        // add a border around the newly created UIView
//        faceView.layer.borderWidth = 1;
//        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        
        // add the new view to create a box around the face
        [targetView addSubview:faceView];
        LOGLINE;
        if(faceFeature.hasLeftEyePosition)
        {
            NSLog(@"Have left eye at %@ and is %@ closed", NSStringFromCGPoint(faceFeature.leftEyePosition), faceFeature.leftEyeClosed ? @"":@"NOT");
            // create a UIView with a size based on the width of the face
//            UIView* leftEyeView = [[UIView alloc] initWithFrame:CGRectMake(faceFeature.leftEyePosition.x-faceWidth*0.15, faceFeature.leftEyePosition.y-faceWidth*0.15, faceWidth*0.3, faceWidth*0.3)];
//            // change the background color of the eye view
//            [leftEyeView setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
//            // set the position of the leftEyeView based on the face
//            [leftEyeView setCenter:faceFeature.leftEyePosition];
//            // round the corners
//            leftEyeView.layer.cornerRadius = faceWidth*0.15;
//            // add the view to the window
//            [targetView addSubview:leftEyeView];
        }
        
        if(faceFeature.hasRightEyePosition)
        {
            NSLog(@"Have right eye at %@ and is %@ closed", NSStringFromCGPoint(faceFeature.rightEyePosition), faceFeature.rightEyeClosed ? @"":@"NOT");
            // create a UIView with a size based on the width of the face
//            UIView* leftEye = [[UIView alloc] initWithFrame:CGRectMake(faceFeature.rightEyePosition.x-faceWidth*0.15, faceFeature.rightEyePosition.y-faceWidth*0.15, faceWidth*0.3, faceWidth*0.3)];
//            // change the background color of the eye view
//            [leftEye setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
//            // set the position of the rightEyeView based on the face
//            [leftEye setCenter:faceFeature.rightEyePosition];
//            // round the corners
//            leftEye.layer.cornerRadius = faceWidth*0.15;
//            // add the new view to the window
//            [targetView addSubview:leftEye];
        }
        
        if(faceFeature.hasMouthPosition && _drawBeard)
        {
            NSLog(@"Have mouth at position %@ and it is %@ smiling", NSStringFromCGPoint(faceFeature.mouthPosition), faceFeature.hasSmile ? @"":@"NOT");

            CGFloat faceAngle = .0f;
            if( faceFeature.hasLeftEyePosition && faceFeature.hasRightEyePosition )
            {
                CGFloat eyesDistanceX = faceFeature.leftEyePosition.x - faceFeature.rightEyePosition.x;
                CGFloat eyesDistanceY = faceFeature.leftEyePosition.y - faceFeature.rightEyePosition.y;
                faceAngle = (eyesDistanceY / eyesDistanceX);
                DLog(@"eyesDistanceX: %f, eyesDistanceY: %f, faceAngle: %f", eyesDistanceX, eyesDistanceY, faceAngle);
            }
            
            UIImageView *beard = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"beard"]];
            [beard setFrame:CGRectMake(0, 0, faceWidth, faceWidth)];
            [beard setContentMode:UIViewContentModeScaleAspectFit];
            beard.center = CGPointMake(faceFeature.mouthPosition.x, faceFeature.mouthPosition.y - faceWidth * .2f);
            CGAffineTransform transform = CGAffineTransformMakeRotationAt( faceAngle, CGPointMake(.5f, 1.f) );
            
            beard.transform = transform;
//            beard.layer.borderColor = [UIColor redColor].CGColor;
//            beard.layer.borderWidth = .5f;

            [targetView addSubview:beard];
            beard = nil;
        }
        
        if( faceFeature.hasFaceAngle )
        {
            NSLog(@"Have face angle: %f", faceFeature.faceAngle);
        }
        
        if( CGRectGetHeight([faceView bounds]) * 2 < CGRectGetHeight([facePicture bounds]) )
        {
            NSLog(@"Will draw chest cover");
            UIImageView *chestView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, CGRectGetWidth([faceView bounds]) * 1.8f, CGRectGetHeight([faceView bounds]) * 0.9f )];
            chestView.center = CGPointMake(CGRectGetMidX([faceView frame]),
                                           CGRectGetMaxY([faceView frame]) - CGRectGetHeight([faceView bounds]) * 2.3f);
            [chestView setImage:[UIImage imageNamed:@"chest"]];
            [chestView setBackgroundColor:[UIColor clearColor]];
            [chestView setContentMode:UIViewContentModeScaleAspectFit];
            [targetView addSubview:chestView];
            NSLog(@"%@", chestView);
            chestView = nil;
        }
    }
    [targetView setContentMode:UIViewContentModeScaleToFill];
    DLog(@"Finish");
    return YES;
}

CGAffineTransform CGAffineTransformMakeRotationAt(CGFloat angle, CGPoint pt)
{
    const CGFloat fx = pt.x;
    const CGFloat fy = pt.y;
    const CGFloat fcos = cos(angle);
    const CGFloat fsin = sin(angle);
    return CGAffineTransformMake(fcos, fsin, -fsin, fcos, fx - fx * fcos + fy * fsin, fy - fx * fsin - fy * fcos);
}

@end
