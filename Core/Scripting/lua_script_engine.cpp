#include "ExecutorCore/lua_script_engine.h"
#include <string>
#include <vector>
#include <memory>
#include <thread>
#include <atomic>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

// IPC channel name for script communication
static const char* SCRIPT_PIPE_NAME = "/tmp/lua_script_pipe";

// Roblox-specific Lua functions
static const luaL_Reg robloxlib[] = {
    {"getfenv", NULL},
    {"setfenv", NULL},
    {"getrawmetatable", NULL},
    {"setrawmetatable", NULL},
    {"getnamecallmethod", NULL},
    {"setnamecallmethod", NULL},
    {"getrenv", NULL},
    {"getgenv", NULL},
    {"getreg", NULL},
    {"getgc", NULL},
    {"getinstances", NULL},
    {"getnilinstances", NULL},
    {"getscripts", NULL},
    {"getloadedmodules", NULL},
    {"getconnections", NULL},
    {"fireclickdetector", NULL},
    {"fireproximityprompt", NULL},
    {"firetouchinterest", NULL},
    {"firetouchtransmitter", NULL},
    {"fireclient", NULL},
    {"fireserver", NULL},
    {NULL, NULL}
};

class LuaScriptEngine {
private:
    lua_State* L;
    std::atomic<bool> isRunning;
    std::thread ipcThread;
    int scriptPipe;
    
    void setupRobloxEnvironment() {
        // Create a new table for Roblox functions
        lua_newtable(L);
        
        // Register Roblox functions
        for (const luaL_Reg* lib = robloxlib; lib->func; lib++) {
            lua_pushcfunction(L, lib->func);
            lua_setfield(L, -2, lib->name);
        }
        
        // Set the table as global
        lua_setglobal(L, "roblox");
        
        // Add Roblox-specific globals
        lua_pushboolean(L, 1);
        lua_setglobal(L, "isroblox");
    }
    
    void ipcListenerLoop() {
        scriptPipe = open(SCRIPT_PIPE_NAME, O_RDONLY);
        if (scriptPipe < 0) {
            fprintf(stderr, "Failed to open script pipe for reading\n");
            return;
        }
        
        while (isRunning) {
            uint32_t scriptSize;
            ssize_t bytesRead = read(scriptPipe, &scriptSize, sizeof(scriptSize));
            
            if (bytesRead != sizeof(scriptSize)) {
                if (bytesRead < 0) {
                    fprintf(stderr, "Error reading script size: %s\n", strerror(errno));
                }
                continue;
            }
            
            std::vector<char> scriptBuffer(scriptSize + 1);
            bytesRead = read(scriptPipe, scriptBuffer.data(), scriptSize);
            
            if (bytesRead != scriptSize) {
                fprintf(stderr, "Error reading script data\n");
                continue;
            }
            
            scriptBuffer[scriptSize] = '\0';
            executeScript(scriptBuffer.data());
        }
        
        close(scriptPipe);
    }
    
    bool executeScript(const char* script) {
        if (!L) return false;
        
        // Setup Roblox environment before executing script
        setupRobloxEnvironment();
        
        int status = luaL_loadstring(L, script);
        if (status != LUA_OK) {
            fprintf(stderr, "Failed to load script: %s\n", lua_tostring(L, -1));
            lua_pop(L, 1);
            return false;
        }
        
        status = lua_pcall(L, 0, 0, 0);
        if (status != LUA_OK) {
            fprintf(stderr, "Failed to execute script: %s\n", lua_tostring(L, -1));
            lua_pop(L, 1);
            return false;
        }
        
        return true;
    }
    
public:
    LuaScriptEngine() : L(nullptr), isRunning(false), scriptPipe(-1) {
        L = luaL_newstate();
        if (L) {
            luaL_openlibs(L);
            isRunning = true;
            ipcThread = std::thread(&LuaScriptEngine::ipcListenerLoop, this);
        }
    }
    
    ~LuaScriptEngine() {
        isRunning = false;
        
        // Write dummy data to unblock the read operation
        int tempPipe = open(SCRIPT_PIPE_NAME, O_WRONLY);
        if (tempPipe >= 0) {
            uint32_t dummy = 0;
            write(tempPipe, &dummy, sizeof(dummy));
            close(tempPipe);
        }
        
        if (ipcThread.joinable()) {
            ipcThread.join();
        }
        
        if (L) {
            lua_close(L);
            L = nullptr;
        }
    }
    
    bool isInitialized() const {
        return L != nullptr;
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
    
    bool isEngineInitialized(LuaScriptEngine* engine) {
        return engine && engine->isInitialized();
    }
} 