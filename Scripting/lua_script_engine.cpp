#include "lua_script_engine.h"
#include <string>
#include <vector>

extern "C" {
    #include "lua.h"
    #include "lualib.h"
    #include "lauxlib.h"
}

class LuaScriptEngine {
private:
    lua_State* L;
    bool isInitialized;
    
public:
    LuaScriptEngine() : L(nullptr), isInitialized(false) {}
    
    ~LuaScriptEngine() {
        cleanup();
    }
    
    bool initialize() {
        if (isInitialized) return true;
        
        L = luaL_newstate();
        if (!L) return false;
        
        luaL_openlibs(L);
        isInitialized = true;
        return true;
    }
    
    void cleanup() {
        if (L) {
            lua_close(L);
            L = nullptr;
        }
        isInitialized = false;
    }
    
    bool loadScript(const std::string& script) {
        if (!isInitialized) return false;
        
        int status = luaL_loadstring(L, script.c_str());
        if (status != LUA_OK) {
            const char* error = lua_tostring(L, -1);
            lua_pop(L, 1);
            return false;
        }
        
        return true;
    }
    
    bool executeScript() {
        if (!isInitialized) return false;
        
        int status = lua_pcall(L, 0, LUA_MULTRET, 0);
        if (status != LUA_OK) {
            const char* error = lua_tostring(L, -1);
            lua_pop(L, 1);
            return false;
        }
        
        return true;
    }
    
    bool compileToBytecode(const std::string& script, std::vector<uint8_t>& bytecode) {
        if (!isInitialized) return false;
        
        // In a real implementation, you would:
        // 1. Load the script
        // 2. Use lua_dump to get the bytecode
        // 3. Store it in the bytecode vector
        
        return false;
    }
};

// C interface for Objective-C/Swift
extern "C" {
    LuaScriptEngine* createLuaEngine() {
        return new LuaScriptEngine();
    }
    
    void destroyLuaEngine(LuaScriptEngine* engine) {
        delete engine;
    }
    
    bool initializeEngine(LuaScriptEngine* engine) {
        return engine->initialize();
    }
    
    bool loadScript(LuaScriptEngine* engine, const char* script) {
        return engine->loadScript(script);
    }
    
    bool executeScript(LuaScriptEngine* engine) {
        return engine->executeScript();
    }
} 