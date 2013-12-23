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

// return true if the device has a retina display, false otherwise
#define IS_RETINA_DISPLAY() [[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0f

// return the scale value based on device's display (2 retina, 1 other)
#define DISPLAY_SCALE IS_RETINA_DISPLAY() ? 2.0f : 1.0f

// if the device has a retina display return the real scaled pixel size, otherwise the same size will be returned
#define PIXEL_SIZE(size) IS_RETINA_DISPLAY() ? CGSizeMake(size.width/2.0f, size.height/2.0f) : size
static inline double radians (double degrees) {return degrees * M_PI/180;}


@interface ITViewController ()
@property(nonatomic, strong) UIButton *btnTakePhoto;
@property(nonatomic, strong) UIImageView *imgView;

@end

@implementation ITViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _btnTakePhoto = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_btnTakePhoto setTitle:@"Take photo" forState:UIControlStateNormal];
    [_btnTakePhoto setFrame:CGRectMake(0, 0, 200, 44)];
    [_btnTakePhoto setCenter:CGPointMake(CGRectGetMidX([[self view] bounds]), CGRectGetMaxY([[self view] bounds]) - CGRectGetHeight([_btnTakePhoto frame]))];
    [[self view] addSubview:_btnTakePhoto];
    [_btnTakePhoto addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
    
//    UIBarButtonItem *btnTakePhoto = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePhoto)];
//    [[self navigationItem] setRightBarButtonItem:btnTakePhoto];
    
    _imgView = [[UIImageView alloc] initWithFrame:[[self view] bounds]];
    [_imgView setBackgroundColor:[UIColor greenColor]];
    [[self view] addSubview:_imgView];
    [[self view] sendSubviewToBack:_imgView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)takePhoto
{
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
    UIImage *imgTaken = [info objectForKey:UIImagePickerControllerOriginalImage];
    CGFloat horizAspect = 320.f / imgTaken.size.width;
//    UIImage *img = [self resizeImage:imgTaken newSize:CGSizeMake(imgTaken.size.width * horizAspect, imgTaken.size.height * horizAspect)];
//    UIImage *img = [UIImage imageWithCGImage:imgTaken.CGImage scale:horizAspect orientation:UIImageOrientationUp];
    UIImage *rotateimg = nil;
//    if( [imgTaken imageOrientation] != UIImageOrientationLeft && [imgTaken imageOrientation] != UIImageOrientationRight )
//    {
//        rotateimg = [UIImage imageWithCGImage:imgTaken.CGImage scale:1.f orientation:[imgTaken imageOrientation]];
//    }
//    else{
        rotateimg = rotate(imgTaken, UIImageOrientationDown);
//    }
    UIImage *scaleImg = [rotateimg scaleToSize:CGSizeMake(imgTaken.size.width * horizAspect, imgTaken.size.height * horizAspect)];
    [_imgView setContentMode:UIViewContentModeTopLeft];
    [_imgView setClipsToBounds:YES];
    [_imgView setImage:scaleImg];
    [_imgView setFrame:CGRectMake(0, 0, scaleImg.size.width, scaleImg.size.height)];
    _imgView.layer.borderColor = [UIColor redColor].CGColor;
    _imgView.layer.borderWidth = .5f;
    [self dismissViewControllerAnimated:YES completion:^(void){
        [self faceDetect];
    }];
}

UIImage* rotate(UIImage* src, UIImageOrientation orientation)
{
    UIGraphicsBeginImageContext(src.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, radians(90));
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, radians(-90));
    } else if (orientation == UIImageOrientationDown) {
        // NOTHING
    } else if (orientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, radians(90));
    }
    
    [src drawAtPoint:CGPointMake(0, 0)];
    
    return UIGraphicsGetImageFromCurrentImageContext();
}

-(void)faceDetect
{
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
}

-(BOOL)markFaces:(UIImageView *)facePicture targetView:(UIImageView *)targetView
{
    // draw a CI image with the previously loaded face detection picture
    CIImage* image = [CIImage imageWithCGImage:facePicture.image.CGImage];
    // create a face detector - since speed is not an issue we'll use a high accuracy
    // detector
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    // create an array containing all the detected faces from the detector
    NSArray* features = [detector featuresInImage:image];
    // we'll iterate through every detected face. CIFaceFeature provides us
    // with the width for the entire face, and the coordinates of each eye
    // and the mouth if detected. Also provided are BOOL's for the eye's and
    // mouth so we can check if they already exist.
    if( [features count] ==  0 ) {
        return NO;
    }
    
    for(CIFaceFeature* faceFeature in features)
    {
        // get the width of the face
        CGFloat faceWidth = faceFeature.bounds.size.width;
        
        // create a UIView using the bounds of the face
        UIView* faceView = [[UIView alloc] initWithFrame:faceFeature.bounds];
        
        // add a border around the newly created UIView
//        faceView.layer.borderWidth = 1;
//        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        
        // add the new view to create a box around the face
        [targetView addSubview:faceView];
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
        
        if(faceFeature.hasMouthPosition)
        {
            NSLog(@"Have mouth at position %@ and it is %@ smiling", NSStringFromCGPoint(faceFeature.mouthPosition), faceFeature.hasSmile ? @"":@"NOT");
            // create a UIView with a size based on the width of the face
//            UIView* mouth = [[UIView alloc] initWithFrame:CGRectMake(faceFeature.mouthPosition.x-faceWidth*0.2, faceFeature.mouthPosition.y-faceWidth*0.2, faceWidth*0.4, faceWidth*0.4)];
//            // change the background color for the mouth to green
//            [mouth setBackgroundColor:[[UIColor greenColor] colorWithAlphaComponent:0.3]];
//            // set the position of the mouthView based on the face
//            [mouth setCenter:faceFeature.mouthPosition];
//            // round the corners
//            mouth.layer.cornerRadius = faceWidth*0.2;
//            // add the new view to the window
//            [targetView addSubview:mouth];
            UIImageView *beard = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"beard"]];
            [beard setFrame:CGRectMake(0, 0, faceWidth, faceWidth)];
            [beard setContentMode:UIViewContentModeScaleAspectFit];
            beard.center = CGPointMake(faceFeature.mouthPosition.x, faceFeature.mouthPosition.y - faceWidth * .2f);
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
            UIImageView *chestView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([faceView bounds]) * 1.5f, CGRectGetHeight([faceView bounds]) * 0.9f )];
            chestView.center = CGPointMake(CGRectGetMidX([faceView frame]),
                                           CGRectGetMaxY([faceView frame]) - CGRectGetHeight([faceView bounds]) * 2.2f);
            [chestView setBackgroundColor:[UIColor blueColor]];
            [targetView addSubview:chestView];
            NSLog(@"%@", chestView);
            chestView = nil;
        }
    }
    [targetView setContentMode:UIViewContentModeScaleToFill];
    NSLog(@"=======================================");
    return YES;
}

@end
