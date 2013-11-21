//
//  ViewController.m
//  VideoFromImage
//
//  Created by Lockerios on 11/21/13.
//  Copyright (c) 2013 Lockerios. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@end

@implementation ViewController

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image  size:(CGSize)imageSize
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    //    CGContextConcatCTM(context, frameTransform);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

-(void)writeImageAsMovie:(NSArray *)array toPath:(NSString*)path size:(CGSize)size duration:(int)duration
{
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeMPEG4
                                                              error:&error];
    NSParameterAssert(videoWriter);
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                          outputSettings:videoSettings] retain];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    CVPixelBufferRef buffer = NULL;
    buffer = [self pixelBufferFromCGImage:[[array objectAtIndex:0] CGImage] size:CGSizeMake(640, 1136)];
    CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    
    int i = 1;
    while (1)
    {
		if(writerInput.readyForMoreMediaData){
			CMTime frameTime = CMTimeMake(1, 10);
			CMTime lastTime=CMTimeMake(i, 10);
			CMTime presentTime=CMTimeAdd(lastTime, frameTime);
			if (i >= [array count])
			{
				buffer = NULL;
			}
			else
			{
				buffer = [self pixelBufferFromCGImage:[[array objectAtIndex:i] CGImage] size:CGSizeMake(640, 1136)];
			}
			if (buffer)
			{
				// append buffer
				[adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
				i++;
			}
			else
			{
				//Finish the session:
				[writerInput markAsFinished];
                //If change to fininshWritingWith... Cause Zero bytes file. I'm Trying to fix.
				[videoWriter finishWriting];
				CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
				[videoWriter release];
				[writerInput release];
				NSLog (@"Done");
				break;
			}
		}
    }
}

- (void)saveMovieToLibrary
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/movie.mp4"]];
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
    for (NSString *tString in dirContents) {
        if ([tString isEqualToString:@"movie.mp4"])
        {
            //Remove File existed.
            [[NSFileManager defaultManager]removeItemAtPath:[NSString stringWithFormat:@"%@/%@",documentsDirectoryPath,tString] error:nil];
        }
    }
    NSArray* testImageArray = [[NSArray alloc] initWithObjects:
                      [UIImage imageNamed:@"case_1.jpg"],
                      [UIImage imageNamed:@"case_2.jpg"],
                      [UIImage imageNamed:@"case_3.jpg"],
                      [UIImage imageNamed:@"case_4.jpg"],
                      [UIImage imageNamed:@"case_5.jpg"],
                      [UIImage imageNamed:@"case_1.jpg"],
                      [UIImage imageNamed:@"case_2.jpg"],
                      [UIImage imageNamed:@"case_3.jpg"],
                      [UIImage imageNamed:@"case_4.jpg"], nil];
    
    [self writeImageAsMovie:testImageArray toPath:path size:CGSizeMake(640, 1136) duration:1];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self saveMovieToLibrary];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
