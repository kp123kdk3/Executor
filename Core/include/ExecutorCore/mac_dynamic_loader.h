#ifndef MAC_DYNAMIC_LOADER_H
#define MAC_DYNAMIC_LOADER_H

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque type for the dynamic loader
typedef struct DynamicLoader DynamicLoader;

// Creates a new dynamic loader instance
DynamicLoader* createDynamicLoader(void);

// Destroys a dynamic loader instance
void destroyDynamicLoader(DynamicLoader* loader);

// Loads a dynamic library at the specified path
bool loadLibrary(DynamicLoader* loader, const char* path);

// Gets a symbol (function or variable) from the loaded library
void* getSymbol(DynamicLoader* loader, const char* symbolName);

// Unloads the currently loaded library
bool unloadLibrary(DynamicLoader* loader);

// Gets the last error message
const char* getLastError(DynamicLoader* loader);

// Gets the base address of the loaded library
void* getLibraryBaseAddress(DynamicLoader* loader);

// Gets the size of the loaded library
size_t getLibrarySize(DynamicLoader* loader);

#ifdef __cplusplus
}
#endif

#endif // MAC_DYNAMIC_LOADER_H 