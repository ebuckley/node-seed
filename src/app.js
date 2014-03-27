
/**
 * Module dependencies.
 */

var express = require('express'),
	http = require('http'),
	path = require('path'),
	cfg = require('./package.json');

var a = express();

// all environments
a.set('port', process.env.PORT || 3000);
a.set('views', __dirname + '/views');
a.engine('html', require('ejs').renderFile);
a.use(express.favicon());
a.use(express.logger('dev'));
a.use(express.bodyParser());
a.use(express.methodOverride());
a.use(express.static(path.join(__dirname, 'public')));

// development only
if ('development' == a.get('env')) {
  a.use(express.errorHandler());
}


a.get('/', function(req, res) {

	res.render('index.html',{
		name: cfg.name,
		description: cfg.description,
		steps: [
			'install grunt-cli and grunt "npm install -g grunt-cli grunt"',
			'change package.json to have the name of your app and a description'
		]
	});
});

http.createServer(a).listen(a.get('port'), function(){
  console.log('Express server listening on port ' + a.get('port'));
});
