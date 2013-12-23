//
//  UIImage+UIImageFunctions.m
//  InstaTits
//
//  Created by Rett Pop on 22.12.13.
//  Copyright (c) 2013 SapiSoft. All rights reserved.
//

#import "UIImage+UIImageFunctions.h"

#ifndef DLog
#ifdef DEBUG
#define DLog(_format_, ...) NSLog([NSString stringWithFormat:@"%s: %@", __PRETTY_FUNCTION__, (_format_)], ## __VA_ARGS__)
#else
#define DLog(_format_, ...)
#endif
#endif

@implementation UIImage (UIImageFunctions)
- (UIImage*)scaleToSize:(CGSize)size
{
    DLog(@"Start");
    UIGraphicsBeginImageContext(size);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), self.CGImage);

    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return scaledImage;
    DLog(@"Start");
}

@end
