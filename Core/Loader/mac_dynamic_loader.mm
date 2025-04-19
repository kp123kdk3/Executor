#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <mach/mach.h>
#import <mach/mach_vm.h>
#import <mach/vm_map.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <dlfcn.h>
#import <pthread.h>
#import <sys/stat.h>
#import <fcntl.h>
#import <unistd.h>
#import "ExecutorCore/mac_dynamic_loader.h"

// IPC channel name for script communication
static const char* SCRIPT_PIPE_NAME = "/tmp/lua_script_pipe";

// Structure to hold dynamic loader state
struct DynamicLoader {
    void* handle;
    char lastError[1024];
    mach_header_64* header;
    size_t imageSize;
};

extern "C" {

DynamicLoader* createDynamicLoader() {
    DynamicLoader* loader = new DynamicLoader();
    loader->handle = nullptr;
    loader->header = nullptr;
    loader->imageSize = 0;
    loader->lastError[0] = '\0';
    return loader;
}

void destroyDynamicLoader(DynamicLoader* loader) {
    if (loader) {
        if (loader->handle) {
            dlclose(loader->handle);
        }
        delete loader;
    }
}

bool loadLibrary(DynamicLoader* loader, const char* path) {
    if (!loader) return false;
    
    // Clear any previous error
    dlerror();
    
    // Attempt to load the library
    loader->handle = dlopen(path, RTLD_NOW);
    
    if (!loader->handle) {
        const char* error = dlerror();
        if (error) {
            strncpy(loader->lastError, error, sizeof(loader->lastError) - 1);
            loader->lastError[sizeof(loader->lastError) - 1] = '\0';
        }
        return false;
    }
    
    // Find the loaded image
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const char* imageName = _dyld_get_image_name(i);
        if (strcmp(imageName, path) == 0) {
            loader->header = (mach_header_64*)_dyld_get_image_header(i);
            
            // Calculate image size by iterating through load commands
            if (loader->header) {
                uint8_t* ptr = (uint8_t*)loader->header + sizeof(mach_header_64);
                for (uint32_t j = 0; j < loader->header->ncmds; j++) {
                    load_command* cmd = (load_command*)ptr;
                    if (cmd->cmd == LC_SEGMENT_64) {
                        segment_command_64* seg = (segment_command_64*)cmd;
                        loader->imageSize = std::max(loader->imageSize, 
                                                   (size_t)(seg->vmaddr + seg->vmsize));
                    }
                    ptr += cmd->cmdsize;
                }
            }
            break;
        }
    }
    
    return true;
}

void* getSymbol(DynamicLoader* loader, const char* symbolName) {
    if (!loader || !loader->handle) return nullptr;
    
    // Clear any previous error
    dlerror();
    
    void* symbol = dlsym(loader->handle, symbolName);
    
    if (!symbol) {
        const char* error = dlerror();
        if (error) {
            strncpy(loader->lastError, error, sizeof(loader->lastError) - 1);
            loader->lastError[sizeof(loader->lastError) - 1] = '\0';
        }
    }
    
    return symbol;
}

bool unloadLibrary(DynamicLoader* loader) {
    if (!loader || !loader->handle) return false;
    
    // Clear any previous error
    dlerror();
    
    if (dlclose(loader->handle) != 0) {
        const char* error = dlerror();
        if (error) {
            strncpy(loader->lastError, error, sizeof(loader->lastError) - 1);
            loader->lastError[sizeof(loader->lastError) - 1] = '\0';
        }
        return false;
    }
    
    loader->handle = nullptr;
    loader->header = nullptr;
    loader->imageSize = 0;
    
    return true;
}

const char* getLastError(DynamicLoader* loader) {
    return loader ? loader->lastError : "";
}

void* getLibraryBaseAddress(DynamicLoader* loader) {
    return loader ? (void*)loader->header : nullptr;
}

size_t getLibrarySize(DynamicLoader* loader) {
    return loader ? loader->imageSize : 0;
}

}

@interface ProcessInjector : NSObject

// Find a process by name and return its PID
- (pid_t)findProcessByName:(NSString *)processName;

// Inject a dynamic library into the target process
- (BOOL)injectLibrary:(NSString *)libraryPath intoProcess:(pid_t)pid;

// Clean up resources after injection
- (void)cleanupInjection:(pid_t)pid;

// Send a Lua script to the injected process
- (BOOL)sendScript:(NSString *)script toPID:(pid_t)pid;

@end

@implementation ProcessInjector {
    mach_port_t _task;
    mach_vm_address_t _remoteLibrary;
    mach_vm_address_t _remotePath;
    int _scriptPipe;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _task = MACH_PORT_NULL;
        _remoteLibrary = 0;
        _remotePath = 0;
        _scriptPipe = -1;
        
        // Create the named pipe for IPC if it doesn't exist
        if (mkfifo(SCRIPT_PIPE_NAME, 0666) != 0 && errno != EEXIST) {
            NSLog(@"Failed to create script pipe: %s", strerror(errno));
        }
    }
    return self;
}

- (void)dealloc {
    [self cleanupInjection:0];
    if (_scriptPipe >= 0) {
        close(_scriptPipe);
    }
}

- (pid_t)findProcessByName:(NSString *)processName {
    // Get list of all running processes
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    size_t size = 0;
    
    if (sysctl(mib, 4, NULL, &size, NULL, 0) == -1) {
        NSLog(@"Failed to get process list size");
        return 0;
    }
    
    struct kinfo_proc *processes = (struct kinfo_proc *)malloc(size);
    if (!processes) {
        NSLog(@"Failed to allocate memory for process list");
        return 0;
    }
    
    if (sysctl(mib, 4, processes, &size, NULL, 0) == -1) {
        free(processes);
        NSLog(@"Failed to get process list");
        return 0;
    }
    
    // Search for the target process
    pid_t foundPID = 0;
    int count = (int)(size / sizeof(struct kinfo_proc));
    for (int i = 0; i < count; i++) {
        NSString *name = [NSString stringWithUTF8String:processes[i].kp_proc.p_comm];
        if ([name isEqualToString:processName]) {
            foundPID = processes[i].kp_proc.p_pid;
            break;
        }
    }
    
    free(processes);
    return foundPID;
}

- (BOOL)injectLibrary:(NSString *)libraryPath intoProcess:(pid_t)pid {
    kern_return_t kr;
    
    // Get task port for the target process
    kr = task_for_pid(mach_task_self(), pid, &_task);
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to get task port: %d", kr);
        return NO;
    }
    
    // Allocate memory for the library path
    mach_vm_size_t pathSize = [libraryPath lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
    kr = mach_vm_allocate(_task, &_remotePath, pathSize, VM_FLAGS_ANYWHERE);
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to allocate memory for path: %d", kr);
        return NO;
    }
    
    // Write the library path
    const char *pathCString = [libraryPath UTF8String];
    kr = mach_vm_write(_task, _remotePath, (vm_offset_t)pathCString, (mach_msg_type_number_t)pathSize);
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to write path: %d", kr);
        return NO;
    }
    
    // Find dlopen in the target process
    void *dlopen_addr = dlsym(RTLD_DEFAULT, "dlopen");
    if (!dlopen_addr) {
        NSLog(@"Failed to find dlopen");
        return NO;
    }
    
    // Create remote thread to call dlopen
    thread_act_t thread;
    arm_thread_state64_t thread_state = {0};
    thread_state.__x[0] = _remotePath;  // First argument (path)
    thread_state.__x[1] = RTLD_NOW;     // Second argument (mode)
    thread_state.__pc = (uint64_t)dlopen_addr;  // Program counter
    thread_state.__sp = (uint64_t)0;    // Stack pointer will be set up by the kernel
    
    kr = thread_create_running(_task, ARM_THREAD_STATE64,
                             (thread_state_t)&thread_state,
                             ARM_THREAD_STATE64_COUNT,
                             &thread);
    
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to create thread: %d", kr);
        return NO;
    }
    
    // Wait for thread completion
    thread_basic_info_data_t info;
    mach_msg_type_number_t info_count = THREAD_BASIC_INFO_COUNT;
    kr = thread_info(thread, THREAD_BASIC_INFO,
                    (thread_info_t)&info,
                    &info_count);
    
    if (kr == KERN_SUCCESS) {
        // Clean up thread
        mach_port_deallocate(mach_task_self(), thread);
    }
    
    return YES;
}

- (BOOL)sendScript:(NSString *)script toPID:(pid_t)pid {
    if (_scriptPipe < 0) {
        _scriptPipe = open(SCRIPT_PIPE_NAME, O_WRONLY);
        if (_scriptPipe < 0) {
            NSLog(@"Failed to open script pipe: %s", strerror(errno));
            return NO;
        }
    }
    
    // Prepare script data with size prefix
    NSData *scriptData = [script dataUsingEncoding:NSUTF8StringEncoding];
    uint32_t size = (uint32_t)scriptData.length;
    
    // Write size
    if (write(_scriptPipe, &size, sizeof(size)) != sizeof(size)) {
        NSLog(@"Failed to write script size: %s", strerror(errno));
        return NO;
    }
    
    // Write script
    if (write(_scriptPipe, scriptData.bytes, size) != size) {
        NSLog(@"Failed to write script data: %s", strerror(errno));
        return NO;
    }
    
    return YES;
}

- (void)cleanupInjection:(pid_t)pid {
    if (_remoteLibrary != 0) {
        mach_vm_deallocate(_task, _remoteLibrary, 0x1000);
        _remoteLibrary = 0;
    }
    
    if (_remotePath != 0) {
        mach_vm_deallocate(_task, _remotePath, 0x1000);
        _remotePath = 0;
    }
    
    if (_task != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), _task);
        _task = MACH_PORT_NULL;
    }
}

@end 