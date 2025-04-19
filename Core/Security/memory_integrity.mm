#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach/mach_vm.h>
#import <CommonCrypto/CommonCrypto.h>

@interface MemoryProtector : NSObject

// Encrypt a memory region
- (NSData *)encryptMemory:(const void *)data length:(size_t)length;

// Decrypt a memory region
- (NSData *)decryptMemory:(const void *)data length:(size_t)length;

// Obfuscate a memory address
- (uintptr_t)obfuscateAddress:(uintptr_t)address;

// Deobfuscate a memory address
- (uintptr_t)deobfuscateAddress:(uintptr_t)address;

// Protect a memory region
- (BOOL)protectMemoryRegion:(mach_vm_address_t)address size:(mach_vm_size_t)size;

@end

@interface MemoryIntegrityChecker : NSObject

+ (instancetype)sharedInstance;
- (BOOL)verifyMemoryRegion:(vm_address_t)address length:(vm_size_t)length;
- (BOOL)protectMemoryRegion:(vm_address_t)address length:(vm_size_t)length;
- (NSString *)getLastError;

@end

@implementation MemoryProtector {
    mach_port_t _task;
    NSData *_encryptionKey;
    uintptr_t _obfuscationKey;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _task = MACH_PORT_NULL;
        
        // Generate encryption key
        uint8_t key[kCCKeySizeAES256];
        arc4random_buf(key, sizeof(key));
        _encryptionKey = [NSData dataWithBytes:key length:sizeof(key)];
        
        // Generate obfuscation key
        _obfuscationKey = arc4random();
    }
    return self;
}

- (NSData *)encryptMemory:(const void *)data length:(size_t)length {
    if (!data || length == 0) {
        return nil;
    }
    
    size_t bufferSize = length + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    if (!buffer) {
        return nil;
    }
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus status = CCCrypt(kCCEncrypt,
                                    kCCAlgorithmAES,
                                    kCCOptionPKCS7Padding,
                                    _encryptionKey.bytes,
                                    _encryptionKey.length,
                                    NULL,
                                    data,
                                    length,
                                    buffer,
                                    bufferSize,
                                    &numBytesEncrypted);
    
    if (status != kCCSuccess) {
        free(buffer);
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
}

- (NSData *)decryptMemory:(const void *)data length:(size_t)length {
    if (!data || length == 0) {
        return nil;
    }
    
    size_t bufferSize = length + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    if (!buffer) {
        return nil;
    }
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus status = CCCrypt(kCCDecrypt,
                                    kCCAlgorithmAES,
                                    kCCOptionPKCS7Padding,
                                    _encryptionKey.bytes,
                                    _encryptionKey.length,
                                    NULL,
                                    data,
                                    length,
                                    buffer,
                                    bufferSize,
                                    &numBytesDecrypted);
    
    if (status != kCCSuccess) {
        free(buffer);
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
}

- (uintptr_t)obfuscateAddress:(uintptr_t)address {
    return address ^ _obfuscationKey;
}

- (uintptr_t)deobfuscateAddress:(uintptr_t)address {
    return address ^ _obfuscationKey;
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

- (void)cleanup {
    if (_task != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), _task);
        _task = MACH_PORT_NULL;
    }
}

@end

@implementation MemoryIntegrityChecker {
    NSString *_lastError;
}

+ (instancetype)sharedInstance {
    static MemoryIntegrityChecker *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _lastError = nil;
    }
    return self;
}

- (BOOL)verifyMemoryRegion:(vm_address_t)address length:(vm_size_t)length {
    vm_address_t region = address;
    vm_size_t region_size = length;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name;
    
    kern_return_t kr = vm_region_64(mach_task_self(),
                                  &region,
                                  &region_size,
                                  VM_REGION_BASIC_INFO_64,
                                  (vm_region_info_t)&info,
                                  &info_count,
                                  &object_name);
    
    if (kr != KERN_SUCCESS) {
        _lastError = [NSString stringWithFormat:@"Failed to verify memory region: %s", mach_error_string(kr)];
        return NO;
    }
    
    return YES;
}

- (BOOL)protectMemoryRegion:(vm_address_t)address length:(vm_size_t)length {
    kern_return_t kr = vm_protect(mach_task_self(),
                                address,
                                length,
                                TRUE,
                                VM_PROT_READ | VM_PROT_EXECUTE);
    
    if (kr != KERN_SUCCESS) {
        _lastError = [NSString stringWithFormat:@"Failed to protect memory region: %s", mach_error_string(kr)];
        return NO;
    }
    
    return YES;
}

- (NSString *)getLastError {
    return _lastError;
}

@end 