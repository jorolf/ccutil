# CCUtil

Utility modules for CC: Tweaked

- `id.lua`: Generate unique ids
- `readstone_state.lua`: Control different bundled cable colors independently
- `sync_client.lua`: Clientside of the sync protocol
- `sync_server.lua`: Serverside of the sync protocol
- `utilities.lua`: Utility functions used by the other modules

## Usage

Import the library by including it in the package path:

```lua
package.path = "path/to/lib/?.lua;" .. package.path
```