#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach/mach_vm.h>
#import <mach/thread_act.h>
#import <dlfcn.h>

@interface MacDynamicLoader : NSObject

- (BOOL)injectLibrary:(NSString *)libraryPath intoProcess:(pid_t)pid;
- (void)cleanupInjection:(pid_t)pid;

@end

@implementation MacDynamicLoader {
    mach_port_t _task;
    mach_vm_address_t _remoteLibrary;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _task = MACH_PORT_NULL;
        _remoteLibrary = 0;
    }
    return self;
}

- (BOOL)injectLibrary:(NSString *)libraryPath intoProcess:(pid_t)pid {
    kern_return_t kr;
    
    // Get task port for the target process
    kr = task_for_pid(mach_task_self(), pid, &_task);
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to get task port: %d", kr);
        return NO;
    }
    
    // Allocate memory in the target process
    mach_vm_size_t size = 0x1000; // 4KB initial allocation
    kr = mach_vm_allocate(_task, &_remoteLibrary, size, VM_FLAGS_ANYWHERE);
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to allocate memory: %d", kr);
        return NO;
    }
    
    // Read the library file
    NSData *libraryData = [NSData dataWithContentsOfFile:libraryPath];
    if (!libraryData) {
        NSLog(@"Failed to read library file");
        return NO;
    }
    
    // Write the library to the target process
    kr = mach_vm_write(_task, _remoteLibrary, (vm_offset_t)libraryData.bytes, libraryData.length);
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to write library: %d", kr);
        return NO;
    }
    
    // Create a new thread to load the library
    thread_act_t thread;
    kr = thread_create(_task, &thread);
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to create thread: %d", kr);
        return NO;
    }
    
    return YES;
}

- (void)cleanupInjection:(pid_t)pid {
    if (_remoteLibrary != 0) {
        mach_vm_deallocate(_task, _remoteLibrary, 0x1000);
        _remoteLibrary = 0;
    }
    
    if (_task != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), _task);
        _task = MACH_PORT_NULL;
    }
}

@end 