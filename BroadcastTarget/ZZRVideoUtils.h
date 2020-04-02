//
//  ZZRVideoUtils.h
//  BroadcastTarget
//
//  Created by 张忠瑞 on 2020/4/1.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMFormatDescription.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZZRVideoUtils : NSObject

+ (CMVideoDimensions)outputVideoDimens:(CMVideoDimensions)inputDimens
                                  crop:(float)ratio;

+ (CMVideoDimensions)calculateDiemnsDividedByTwo:(int)width andHeight:(int)height;

+ (CMVideoDimensions)outputVideoDimensEnhanced:(CMVideoDimensions)inputDimens crop:(float)ratio;

@end

NS_ASSUME_NONNULL_END
