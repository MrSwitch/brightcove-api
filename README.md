# BrightCove CMS API

Provides an API for signing and sending calls to the BrightCove CMS API


# API

```javascript
	// Load brightcove module

	var bc = require('brightcove');


	// Set the account credentials to use

	bc.init({
		client_id : process.env.BC_CLIENT_ID,
		client_secret : process.env.BC_CLIENT_SECRET,
		account_id : process.env.BC_ACCOUNT_ID
	});


	// Get videos updated since .

	bc
	.api({
		path : 'videos',
        qs : {
            q: "updated_at:2015-03-14T04:56:42.589Z..",
            sort: "updated_at",
            limit: 10,
            offset: 0
        }
	})
	.then(function(resp){
		// Handle the response
		console.log(JSON.stringify(resp, null, 2));
	},
	function(err){
		console.error(err);
	});

```
