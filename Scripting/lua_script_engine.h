#ifndef lua_script_engine_h
#define lua_script_engine_h

#ifdef __cplusplus
extern "C" {
#endif

// Initialize the Lua script engine
bool initialize_lua_engine(void);

// Check if the Lua engine is initialized
bool is_lua_engine_initialized(void);

// Execute a Lua script
// Returns true if successful, false if there was an error
bool execute_lua_script(const char* script);

// Get the last error message if any
const char* get_last_error(void);

#ifdef __cplusplus
}
#endif

#endif /* lua_script_engine_h */