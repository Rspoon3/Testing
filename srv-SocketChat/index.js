var app = require("express")();
var http = require("http").Server(app);
var io = require("socket.io")(http, {
    allowEIO3: true
});
var PORT = process.env.PORT || 3000;

app.get("/", function (req, res) {
  res.send("<h1>AppCoda - SocketChat Server</h1>");
});

http.listen(PORT, function () {
  console.log("Listening on *:3000");
});

io.on("connection", function (clientSocket) {
  console.log("A user connected.");

  clientSocket.on("locationUpdate", function (latValue, longValue) {
    let location = {
      lat: latValue,
      long: longValue,
    };

    console.log(location);

    io.emit("locationUpdate", location);
  });
});
