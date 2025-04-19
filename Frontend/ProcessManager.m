#import "Executor-Bridging-Header.h"
#import <AppKit/AppKit.h>

@implementation ProcessManager

+ (NSArray<NSDictionary<NSString*, id>*>*)runningProcesses {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSArray<NSRunningApplication*> *apps = [workspace runningApplications];
    
    NSMutableArray *processes = [NSMutableArray array];
    for (NSRunningApplication *app in apps) {
        [processes addObject:@{
            @"name": app.localizedName ?: @"Unknown",
            @"pid": @(app.processIdentifier)
        }];
    }
    
    return processes;
}

+ (BOOL)injectLibrary:(NSString*)path intoPID:(pid_t)pid {
    // This is just a placeholder that returns success
    // In a real implementation, this would use task_for_pid and mach_vm functions
    return YES;
}

@end 