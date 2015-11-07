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

	var limit = 10;

	offset = ~~offset;

	// Make an API call
	bc.api({
		path : 'videos',
		qs : {
			// q : 'tags:'+["AUlifestyle_AUWDTV","AUgrazia_AUgraziatv","AU_CLEO","AU_cosmopolitan_AU_cosmopolitan","AUlifestyle_bazaar","AUlifestyle_elle","AU_Elle","AU_dolly","AU_aww"].join(' tags:'),
			// sort: "updated_at",
			limit: limit,
			offset: offset
		}
	})

	// Go get the video source files
	.then(function(resp){
		var i=0;

		var a = resp.map( getVideoSource );

		return Promise.all(a)
		.then(function(){
			return resp;
		});
	})

	// Output the results
	.then(function(resp){

		// Print the response to screen
		resp.forEach( output );

		return resp.length;
	})
	.then(function(count){

		if( count ){
			// Run the next one
			run( count + offset );
		}
	})
	.then(null,
		// Throw error
		console.error.bind(console)
	);

})(0);


function getVideoSource(n){
	return bc.api({
		path : 'videos/'+n.id+'/sources'
	})
	.then(function(v){
		n.source = v;
	}, function(){
		console.error('videos/'+n.id+'/sources');
	});
}


function output(n){
	console.log( ',' + JSON.stringify(n) );
}