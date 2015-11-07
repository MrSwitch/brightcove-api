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
			// q : 'tags:'+["AUlifestyle_AUWDTV","AUgrazia_AUgraziatv","AU_CLEO","AU_cosmopolitan_AU_cosmopolitan","AUlifestyle_bazaar","AUlifestyle_elle","AU_Elle","AU_dolly","AU_aww"].join(' tags:'),
			sort: "updated_at",
			limit: limit,
			offset: offset
		}
	})
	// Handle the response
	.then(function(resp){

		// console.log( ","+JSON.stringify(resp, null, 2).replace(/^\[|\]$/,'') );
		resp.forEach(function(n){
			console.log( ","+JSON.stringify(n) );
		});

		if(resp.length){
			run( resp.length + offset );
		}
		else{
			console.log(offset);
		}

	}, function(err){
		console.log(err);
		run(page);
	});

})();