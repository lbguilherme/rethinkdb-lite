var express = require('express');
var proxyServer = require('http-route-proxy');

rethinkdbWeb = process.argv[2] || 'localhost:8080';

var app = express();

app.use(express.static('dist'));

app.use(proxyServer.connect({
    to: rethinkdbWeb,
    route: ['/ajax']
}));

app.listen(3000, function () {
    console.log('Listening on port 3000!');
});
