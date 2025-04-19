#ifndef Executor_Bridging_Header_h
#define Executor_Bridging_Header_h

#import <Foundation/Foundation.h>

@interface ProcessManager : NSObject

+ (NSArray<NSDictionary<NSString*, id>*>*)runningProcesses;
+ (BOOL)injectLibrary:(NSString*)path intoPID:(pid_t)pid;

@end

#endif /* Executor_Bridging_Header_h */ 