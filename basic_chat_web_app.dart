import 'dart:core';
import 'dart:io';
import 'dart:convert';
import 'package:route/server.dart';
import 'package:http_server/http_server.dart';
//import 'package:sqljocky/sqljocky.dart';

final num port = 9223;
List<ConnectedUser> connectedUsers;

VirtualDirectory vd;

void main() {
  connectedUsers = [];
  
  String root_path = Platform.script.resolve("../polymer_fun/build/web").toFilePath();
//  String root_path = "C:/Users/Alex/Documents/GitHub/polymer_fun/build/web";
  vd = new VirtualDirectory(root_path)
    ..allowDirectoryListing = true
    ..directoryHandler = handleVirtualDirectory;

  // Bind the http server to serve up polymer_fun
//  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080).then((server) {
//    server.listen((request){
//      vd.serveRequest(request);
//    });
//  });
  
  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port).then((server) {
    var router = new Router(server);
    router.serve('/ws').transform(new WebSocketTransformer()).listen(handleWebSocket);
  });
}

void handleVirtualDirectory(dir, request)
{
  var indexUri = new Uri.file(dir.path).resolve("index.html");
  vd.serveFile(new File(indexUri.toFilePath()), request);
}

void handleWebSocket(WebSocket ws)
{
  ws.map((string) => JSON.decode(string))
    .listen((json) {
      var act = json['action'];
      switch (act)
      {
        case 'login':
          ConnectedUser newUser = new ConnectedUser(ws, json['username']);
          if (userLogin(json['username']))
          {
            newUser.Login(true);
            connectedUsers.add(newUser);
            connectedUsers.forEach((ConnectedUser u) { u.Notify("User " + json['username'] + " has joined!"); });
          }
          else
          {
            newUser.Login(false);
          }
          break;
        case 'logout':
          break;
        case 'message':
          ConnectedUser user;
          if ((user = findUser(ws)) != null)
            connectedUsers.forEach((ConnectedUser u) { u.SendMessage(user.username, json['message']); });
          else { /* user logged off? TODO: Send error response. */ }
          break;
      }
  }, onDone: () { 
    for (num i = 0; i < connectedUsers.length; i++)
    {
      if (connectedUsers[i].ws == ws)
      {
        String userLeaving = connectedUsers[i].username;
        connectedUsers.removeAt(i);
        connectedUsers.forEach((ConnectedUser u) { u.Notify("User " + userLeaving + " has left."); });
        break;
      }
    }
  });
}

ConnectedUser findUser(WebSocket ws)
{
  for (num i = 0; i < connectedUsers.length; i++)
  {
    if (connectedUsers[i].ws == ws)
    {
      return connectedUsers[i];
    }
  }
  return null;
}

bool userLogin(String username)
{
  for (num i = 0; i < connectedUsers.length; i++)
  {
    if (connectedUsers[i].username == username)
      return false;
  }
  return true;
}

class ConnectedUser
{
  String username;
  WebSocket ws;
  bool isLoggedIn = false;
  
  ConnectedUser(this.ws, this.username);
  
  void Login(bool success)
  {
    isLoggedIn = success;
    this.ws.add(JSON.encode({'action': 'login', 'result': success, 'username': username}));
  }
  
  void Logout()
  {
    isLoggedIn = false;
  }
  
  void SendMessage(String from, String message)
  {
    this.ws.add(JSON.encode({'action': 'message', 'from': from, 'message': message}));
  }
  
  void Notify(String message)
  {
    this.ws.add(JSON.encode({'action': 'notify', 'message': message}));
  }
}
