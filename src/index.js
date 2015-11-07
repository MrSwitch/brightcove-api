// Expose a BrightCove API

var merge = require('lodash/object/merge');
var request = require('request');
var store = require('./utils/store');


var bc = module.exports = {

	// Options
	options : {},

	// Update local settings
	init : function(options){

		// Overwrite the parent instance settings
		merge( this.options, options );

		// Create a new instance which defines the new settings
		var init = Object.create(this);
		init.options = Object.create(this.options);
		merge(init.options, options);

		// Return the new instance
		return init;
	},

	api : function(options){

		if( !this.options.client_id || !this.options.client_secret ){
			throw new Error('required_credentials');
		}

		// Remove path from request
		if( options.path ){
			options.url = "https://cms.api.brightcove.com/v1/accounts/"+ bc.options.account_id +"/"+options.path;
			delete options.path;
		}

		if(!options.headers){
			options.headers = {};
		}


		return promise_request.call(this,options)
		.then(null, function(){
			// The call failed

			// Remove item from the store
			store.removeItem( bc.options.client_id );

			// Try once more
			return promise_request.call(bc,options);
		});

	},

	login : function(){


		if( !this.options.client_id || !this.options.client_secret ){
			throw new Error('required_credentials');
		}

		return Promise.resolve()
		.then(
			// Return a stored item if it exists
			store.getItem.bind( store, this.options.client_id )
		)
		.then(
			// Trigger authentication
			promise_login.bind( null, this.options )
		)
		.then(function(r){
			return r.access_token;
		});
	}
};




function promise_request(options){

	return Promise.resolve()
	.then(
		// Get login information
		this.login.bind(this)
	)
	.then(function(token){

		// Add OAuth header
		options.headers.Authorization = 'Bearer '+ token;

		// Augment the request
		return new Promise( request_json.bind( null, options ) );
	});
}




var pending_logins = {};

function promise_login(options, authObject){

	if( authObject ){
		return authObject;
	}

	var client_id = options.client_id;

	// Is there a current pending login operation
	var pending = pending_logins[client_id];

	if( pending ){
		return pending;
	}

	// Create a new pending promise operation
	pending = new Promise( request_login.bind( null, options ) )
	.then(
		// Set and return the login response
		store.setItem.bind( store, client_id )
	);

	// Store the pending operation
	pending_logins[client_id] = pending;
	
	// Remove the pending promise
	pending.then(
		removePending.bind(null, client_id ),
		removePending.bind(null, client_id )
	);

	// return the promise
	return pending;
}


function removePending(client_id, resp){

	// Remove the pending
	pending_logins[client_id] = null;

	// Passthru resp
	return resp;
}



function request_login(options, resolve, reject){
	// # Construct the Authorization header base64 value
	var auth_string = new Buffer( options.client_id + ":" + options.client_secret).toString("base64");

	request_json({
		method: 'POST',
		url: 'https://oauth.brightcove.com/v3/access_token?grant_type=client_credentials',
		headers: {
			"Authorization": "Basic " + auth_string,
			"Content-Type": "application/json"
		}
	}, resolve, reject);
}



function request_json(options, resolve, reject){

	request( options, resolve_json.bind( null, resolve, reject) );

}


function resolve_json(resolve, reject, err, res, body){
	var json;

	if( err ){
		reject(err);
		return;
	}

	if(body){
		try{
			json = JSON.parse(body);
		}
		catch(e){
			reject({
				error : "invalid_response",
				error_description : e.message
			});
			return;
		}
	}
	else{
		json = {};
	}

	if( res.statusCode >= 400 ){
		reject(json[0] || json);
		return;
	}

	resolve(json);
}