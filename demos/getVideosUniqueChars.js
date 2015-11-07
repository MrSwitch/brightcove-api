//
// Access all the videos
//
// Save the results with `node getVideos.js > path/to/videos.json`
//

var bc = require('../src/index');


// Initiate the brightcove account
bc.init({
	client_id : process.env.BC_CLIENT_ID,
	client_secret : process.env.BC_CLIENT_SECRET,
	account_id : process.env.BC_ACCOUNT_ID
});


(function run( offset ){

	var limit = 100;

	offset = ~~offset;

	// Make an API call
	bc.api({
		path : 'videos',
		qs : {
			limit: limit,
			offset: offset
		}
	})

	.then(
		loopExtractChars
	)

	.then(
		iterateOrEnd.bind(null, offset, run)
	)
	.then(
		null,
		// Throw formatting error
		console.error.bind(console)
	);

})(0);


var chars = [];

function extractChars(n){
	// Get all characters in the response
	var s = JSON.stringify(n);
	for(var i=0;i<s.length;i++){
		var char = s.charAt(i);
		if( chars.indexOf( char ) === -1 ){
			chars.push( char );
		}
	}
}


function loopExtractChars(resp){
	resp.forEach( extractChars );
	return resp;
}


function iterateOrEnd(offset, next, resp){

	if( resp.length ){
		next( resp.length + offset );
		return;
	}

	chars.sort();

	console.log("# Searched items: "+ offset );
	console.log("# Characters found: "+ chars.length );
	console.log("\n");
	console.log(chars.join(''));

	console.log("\n\n");
	chars.forEach( function(n,i){
		console.log( n.charAt(0), n.charCodeAt(0), "\\u"+("0000"+n.charCodeAt(0).toString(16)).slice(-4) );
	});
}