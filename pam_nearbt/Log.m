//  Log.m
//  pam_nearbt
//
//  Created by guoc on 29/03/2016.
//  Copyright © 2016 guoc. All rights reserved.
//

#import "Log.h"

void Log(BOOL output, NSString *format, ...)
{
    if (!output) {
        return;
    }
    va_list args;
    va_start(args, format);
    format = [@"pam_nearbt log: " stringByAppendingString:format];
    NSLogv(format, args);
    va_end(args);
}
