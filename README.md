This project has been discontinued, you can continue to use it but I wont provide support for it.

# sniffer.lua
### Proxy Tables made easy.

Sniffer is a free, open-source library that allows you to proxy other tables and functions, so that they print whenever they're indexed/called.

The proxy table is viral, which means anything that's a table or function that's returned from the proxy table, will also be proxied.

The intention of this script is to aid in the reverse engineering of obfuscated scripts so you can see what they're doing.

# Basic Usage

This will inject the proxy table over the entire environment
```lua
setfenv(1, require(script.Sniffer){script = script}._ENV)
```

# Installation

You can download the Lua script and import it into your code straight away, make sure to use it as a module script.

# API

Sniffer returns a set of functions which may be useful when setting up your tracker.

When you require Sniffer, it returns a function that lets you change anything in the environment, you must call this before attempting to get the environment.

## Properties
### Sniffer._ENV
A reference to the environment wrapped in a proxy table.

## Functions
### Sniffer.functionproxy(f)
Creates a function that will proxy wrap any returns from the function

### Sniffer.mute(name)
Allows you to mute an output. Example: datatype: name
```lua
Sniffer.mute("function: sub") --this mutes any call to sub
```

### Sniffer.setFunctionOverride(name, f)
Allows you to overwrite a function's behaviour. This must follow the format "function: name" and the function must be tracked with a name.
```lua
sniffer.setFunctionOverride("function: IsStudio", function() --forces IsStudio to always return false
  return false
end)
```

### Sniffer.tableproxy(table)
Creates a table proxy, accepts both ``table`` and ``userdata``

# Known Issues

``table.insert`` has wack behaviour.
