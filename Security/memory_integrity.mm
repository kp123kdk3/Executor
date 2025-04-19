#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach/mach_vm.h>
#import <CommonCrypto/CommonCrypto.h>

@interface MemoryIntegrity : NSObject

- (BOOL)protectMemoryRegion:(mach_vm_address_t)address size:(mach_vm_size_t)size;
- (BOOL)verifyMemoryIntegrity:(mach_vm_address_t)address size:(mach_vm_size_t)size;
- (NSData *)calculateMemoryHash:(mach_vm_address_t)address size:(mach_vm_size_t)size;

@end

@implementation MemoryIntegrity {
    mach_port_t _task;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _task = MACH_PORT_NULL;
    }
    return self;
}

- (BOOL)protectMemoryRegion:(mach_vm_address_t)address size:(mach_vm_size_t)size {
    kern_return_t kr;
    
    // Set memory protection to read-only
    kr = mach_vm_protect(_task, address, size, FALSE, VM_PROT_READ);
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to protect memory: %d", kr);
        return NO;
    }
    
    return YES;
}

- (BOOL)verifyMemoryIntegrity:(mach_vm_address_t)address size:(mach_vm_size_t)size {
    NSData *currentHash = [self calculateMemoryHash:address size:size];
    if (!currentHash) {
        return NO;
    }
    
    // In a real implementation, you would:
    // 1. Store the original hash when the memory is first protected
    // 2. Compare the current hash with the original hash
    // 3. Return YES only if they match
    
    return YES;
}

- (NSData *)calculateMemoryHash:(mach_vm_address_t)address size:(mach_vm_size_t)size {
    // Allocate buffer for reading memory
    NSMutableData *memoryData = [NSMutableData dataWithLength:size];
    if (!memoryData) {
        return nil;
    }
    
    // Read memory from the target process
    mach_vm_size_t bytesRead = 0;
    kern_return_t kr = mach_vm_read_overwrite(_task, address, size,
                                             (mach_vm_address_t)memoryData.mutableBytes,
                                             &bytesRead);
    if (kr != KERN_SUCCESS || bytesRead != size) {
        NSLog(@"Failed to read memory: %d", kr);
        return nil;
    }
    
    // Calculate SHA-256 hash
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(memoryData.bytes, (CC_LONG)memoryData.length, hash);
    
    return [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
}

- (void)cleanup {
    if (_task != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), _task);
        _task = MACH_PORT_NULL;
    }
}

@end 