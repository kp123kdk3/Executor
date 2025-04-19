#ifndef EXECUTOR_CORE_H
#define EXECUTOR_CORE_H

#ifdef __cplusplus
extern "C" {
#endif

// Scripting
#include "lua_script_engine.h"

// Loading
#include "mac_dynamic_loader.h"

// Hooking
#include "lua_interaction.h"

// Security
#include "memory_integrity.h"

#ifdef __cplusplus
}
#endif

#endif // EXECUTOR_CORE_H 