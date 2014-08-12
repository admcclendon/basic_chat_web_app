This server application relies on the polymer_fun being in the same directory as basic_chat_web_app.

You will also need to build polymer_fun for basic_chat_web_app to work properly.

Currently the basic_chat_web_app handles WebSocket connections on port 9223, the command structure is as follows:

```javascript
{ 'action': action [, params...] }
```

This object must be encoded with JSON.

The following actions are available

|Action	|	Additional Params  |
|:------|:----------------   | 
|login	|	String username    |
|message|	String message     |
|logout |                    |

The server will respond with a 'notify' action for messages from server.
The server will broadcast 'message' actions to all connected users who also logged in.

Javascript Example:

```javascript
// Create your WebSocket
WebSocket ws = new WebSocket('ws://localhost:9223/ws');
ws.onmessage = function() { /* handle messages from server */ };

// Send the login command
ws.send(JSON.stringify({action: 'login', username: 'bob'}));

// Send messages to other users
ws.send(JSON.stringify({action: 'message', message: 'hello!'}));
```