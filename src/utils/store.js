// # authStorage


module.exports = {
    // Hash lookup
    cache  : {},

    // Add
    getItem : function(client_id){

        var auth = this.cache[client_id];

        return ( auth && auth.expires > Date.now() + 10 ? auth : undefined );
    },


    // Set
    setItem : function(client_id, auth){

        if( typeof(auth) != 'object' || auth === null){
            throw new Error("invalid_token");
        }

        // Is the response not what we were expecting?
        if (auth.error){
            throw new Error(auth.error);
        }

        if (typeof(auth.access_token) != 'string'){
            throw new Error("invalid_token");
        }

        // Add expires
        if (typeof(auth.expires_in) == 'number'){
            // # Update the Expires property
            auth.expires = Date.now() + ( auth.expires_in * 1000 );

            // # Get/Set the cache storage
            if(!this.cache){
                this.cache={};
            }

            this.cache[client_id] = auth;
        }
        else{
            this.removeItem( client_id );
        }

        return auth;
    },

    // # remove item
    removeItem : function(client_id){
        this.cache[client_id] = undefined;
    }

};
