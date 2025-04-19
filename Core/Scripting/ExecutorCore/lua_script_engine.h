#ifndef LUA_SCRIPT_ENGINE_H
#define LUA_SCRIPT_ENGINE_H

#ifdef __cplusplus
extern "C" {
#endif

// Opaque pointer to LuaScriptEngine class
typedef struct LuaScriptEngine LuaScriptEngine;

// Create a new Lua script engine instance
LuaScriptEngine* createLuaEngine(void);

// Destroy a Lua script engine instance
void destroyLuaEngine(LuaScriptEngine* engine);

// Check if the engine is properly initialized
bool isEngineInitialized(LuaScriptEngine* engine);

#ifdef __cplusplus
}
#endif

#endif // LUA_SCRIPT_ENGINE_H 