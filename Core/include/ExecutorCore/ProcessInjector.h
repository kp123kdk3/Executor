#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProcessInjector : NSObject

// Find a process by name and return its PID
- (pid_t)findProcessByName:(NSString *)processName;

// Inject a dynamic library into the target process
- (BOOL)injectLibrary:(NSString *)libraryPath intoProcess:(pid_t)pid;

// Clean up resources after injection
- (void)cleanupInjection:(pid_t)pid;

@end

NS_ASSUME_NONNULL_END 