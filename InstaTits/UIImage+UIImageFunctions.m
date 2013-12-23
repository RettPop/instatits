//
//  UIImage+UIImageFunctions.m
//  InstaTits
//
//  Created by Rett Pop on 22.12.13.
//  Copyright (c) 2013 SapiSoft. All rights reserved.
//

#import "UIImage+UIImageFunctions.h"

@implementation UIImage (UIImageFunctions)
- (UIImage*)scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), self.CGImage);

    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return scaledImage;
}

@end
