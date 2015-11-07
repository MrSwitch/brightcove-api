//
// Delete videos
// http://docs.brightcove.com/en/video-cloud/cms-api/getting-started/overview-cms.html#deletevideo
//
// Call this function with `node delVideos.js --file path/to/videos.json`

var bc = require('../src/index');
var argv = require('yargs').argv;
var path = require('path');

// Initiate the brightcove account
bc.init({
	client_id : process.env.BC_CLIENT_ID,
	client_secret : process.env.BC_CLIENT_SECRET,
	account_id : process.env.BC_ACCOUNT_ID
});

var json = require( path.join(process.env.PWD, argv.file) );

console.log("Loaded \1", json.length);

var i=0;

(function run(i){

	var item = json[i];
	if(! item ){
		return;
	}

	var req = {
		method : 'DELETE',
		path : 'videos/'+item.id,
	};

	// console.log( JSON.stringify(req, null, 2) );

	// Make an API call
	bc.api( req )
	// Handle the response
	.then(function(resp){

		// Print out the message
		console.log( i, "DELETED", item.id );

		// Run the next
		run(++i);

	}, function(err){

		// Print out the message		
		console.error(err);
	});

})(1133);

