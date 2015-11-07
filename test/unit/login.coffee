# brightcove-auth.spec.coffee
bc = require "#{SRC}/index"

# Test helpers
store = require "#{SRC}/utils/store"

# Nock
nock = require "nock"


# Tests
describe 'bc.login()', ->

    stubbedRequest = null
    scope = null
    clock = null

    authResponse = {}

    cred =
        client_id : 'client_id'
        client_secret : 'client_secret'


    beforeEach ->

        bc.init(cred)

        authResponse =
            access_token : 'token'
            expires_in : 100

        store.removeItem(cred.client_id)

        stubbedRequest = sinon.stub()
        nock.disableNetConnect()


        scope = nock 'https://oauth.brightcove.com'
                .filteringRequestBody (path) ->
                    return '*'
                .post '/v3/access_token?grant_type=client_credentials', '*'

    afterEach ->
        nock.enableNetConnect()
        nock.cleanAll()


    it 'should return a promise object', (done) ->

        scope.reply 201, (uri, requestBody) ->
                JSON.stringify authResponse


        result = bc.login()
        result.should.be.instanceOf Promise

        result.then (resp) ->
            done()



    it 'should request with signed Authorisation header', (done) ->

        auth_string = new Buffer(cred.client_id + ":" + cred.client_secret).toString("base64")

        mock = scope
            .matchHeader('Authorization', 'Basic ' + auth_string)
            .reply 201, (uri, requestBody) ->
                JSON.stringify authResponse

        bc
        .login()
        .then (token) ->
            expect(mock.isDone()).to.eql true
        .then ->
            done()
        ,done


    it 'should request with content-type application/json', (done) ->

        mock = scope
            .matchHeader('Content-Type', 'application/json')
            .reply 201, (uri, requestBody) ->
                JSON.stringify authResponse

        bc
        .login()
        .then (token) ->
            expect(mock.isDone()).to.eql(true)
        .then ->
            done()
        ,done



    it 'should return an access_token from an authResponse', (done) ->

        scope.reply 201, (uri, requestBody) ->
            JSON.stringify authResponse

        bc
        .login()
        .then (token) ->
            token.should.be.eql 'token'
        .then ->
            done()
        ,done



    it 'should cache the Auth Response and use in subsequent requests', (done) ->

        # Set up a spy
        spy = sinon.spy (uri, requestBody) ->
            JSON.stringify authResponse

        scope.times 2
            .reply 201, spy

        bc
        .login()
        .then (token) ->
            token.should.be.eql 'token'

            sinon.assert.calledOnce spy

            # Run again...
            bc
            .login()
            .then (token) ->
                sinon.assert.calledOnce spy
            .then -> 
                done()
            , done

        .then null, done

    it "should bind multiple calls for the login to the same promise", (done) ->

        # Set up a spy
        spy = sinon.spy (uri, requestBody) ->
            JSON.stringify authResponse

        scope.times 2
            .reply 201, spy

        # Spy the response
        spySuccess = sinon.spy (token) ->
            token.should.be.eql 'token'
            sinon.assert.calledOnce spy
            1

        # Call bc.login more than once
        # Should make a single request to the spy
        Promise.all([
            bc.login().then(spySuccess),
            bc.login().then(spySuccess),
            bc.login().then(spySuccess),
            bc.login().then(spySuccess),
            bc.login().then(spySuccess)
        ]).then () ->
                # Clean store
                store.removeItem(cred.client_id)

                # Run it again and this should make a second request to the spy
                setTimeout ->
                    bc.login().then () ->
                        sinon.assert.calledTwice spy
                        done()
                    .then null, done

            , done

    it 'should reauthenticate if the token has expired', (done) ->

        # Set up a spy
        spy = sinon.spy (uri, requestBody) ->
            JSON.stringify authResponse

        scope.times 2
            .reply 201, spy

        bc
        .login()
        .then (token) ->
            token.should.be.eql 'token'

            sinon.assert.calledOnce spy

            # Reset the cache time
            store.setItem( cred.client_id, authResponse )
            authResponse.expires = (new Date()).getTime() - 1

            # Run again...
            bc
            .login()
            .then (token) ->
                sinon.assert.calledTwice spy
            .then -> 
                done()
            , done

        .then null, done



    it 'should reauthenticate if the token expiry is less than 10 seconds', (done) ->

        # Set up a spy
        mock = scope.reply 201, ->
            JSON.stringify authResponse

        # Reset the cache time
        store.setItem( cred.client_id, authResponse )
        authResponse.expires = (new Date()).getTime() + 9

        bc
        .login()
        .then (token) ->
            expect(mock.isDone()).to.eql(true)
        .then ->
            done()
        ,done



    it 'should not reauthenticate if the token expiry is greater than 10 seconds', (done) ->

        # Set up a spy
        mock = scope.reply 201, ->
            JSON.stringify authResponse

        # Reset the cache time
        store.setItem( cred.client_id, authResponse )
        authResponse.expires = (new Date()).getTime() + 12

        bc
        .login()
        .then (token) ->
            expect(mock.isDone()).to.eql(false)
        .then ->
            done()
        ,done




    it 'should throw an error if the response is an error', (done) ->

        errorResponse =
            error : "invalid_client"
            error_description :"The &quot;client_id&quot; parameter is missing, does not name a client registration that is applicable for the requested call, or is not properly authenticated."

        # Set up a spy
        spy = sinon.spy (uri, requestBody) ->
            JSON.stringify errorResponse


        # Check callback
        scope.reply 401, spy


        bc
        .login()
        .then ->
            done("Should not be called")
        , (err) ->
            err.error.should.be.eql 'invalid_client'
            sinon.assert.calledOnce spy
            done()



    it 'should throw an "invalid_token" if the response is malformed', (done) ->

        # Set up a spy
        spy = sinon.spy (uri, requestBody) ->
            "notjson"

        # Check callback
        scope.reply 401, spy


        bc
        .login()
        .then ->
            done("Should not be called")
        , (err) ->
            err.error.should.be.eql "invalid_response"
            sinon.assert.calledOnce spy
            done()




    context 'store', ->

        stub = null
        setItem = null
        getItem = null

        beforeEach ->
            setItem = sinon.stub(store, 'setItem')
            getItem = sinon.stub(store, 'getItem')

        afterEach ->
            if setItem.restore
                setItem.restore()
            if getItem.restore
                getItem.restore()

        # it 'should propagate errors with setItem', (done) ->

        #     setItem.throws "Error", "invalid_token"
        #     getItem.restore()

        #     # Set up a spy
        #     spy = sinon.spy (uri, requestBody) ->
        #         authResponse

        #     # Check callback
        #     scope.reply 401, spy

        #     bc
        #     .login()
        #     .then ->
        #         done("Should not be called")
        #     , (err) ->
        #         console.log( err );
        #         err.message.should.be.eql 'invalid_token'
        #         sinon.assert.calledOnce setItem
        #         sinon.assert.calledOnce spy
        #         done()
        #     .then done, done


        it 'should call getItem everytime bc.login is triggered', (done) ->


            # Stub will return the authResponse
            getItem.returns authResponse

            # BrightCove Auth
            bc
            .login()
            .then () ->
                sinon.assert.calledOnce getItem
            .then () ->

                bc
                .login()
                .then () ->
                    sinon.assert.calledTwice getItem
                .then done, done

            , done
