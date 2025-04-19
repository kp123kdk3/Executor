#ifndef LUA_SCRIPT_ENGINE_H
#define LUA_SCRIPT_ENGINE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct LuaScriptEngine LuaScriptEngine;

LuaScriptEngine* createLuaEngine();
void destroyLuaEngine(LuaScriptEngine* engine);
bool initializeEngine(LuaScriptEngine* engine);
bool loadScript(LuaScriptEngine* engine, const char* script);
bool executeScript(LuaScriptEngine* engine);

#ifdef __cplusplus
}
#endif

#endif // LUA_SCRIPT_ENGINE_H 