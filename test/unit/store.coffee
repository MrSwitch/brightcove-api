# Auth Storage
authStorage = require "#{SRC}/utils/store"

# Tests
describe 'Access Token Storage', ->

    authResponse = null
    authResponseA = null
    authResponseB = null

    beforeEach ->
        authResponse =
            access_token : 'token'
            expires_in : 300
        authResponseA =
            access_token : 'tokenA'
            expires_in : 300
        authResponseB =
            access_token : 'tokenB'
            expires_in : 300

    afterEach ->
        # reset the internal cache
        authStorage.cache = {}


    it 'should have a setItem, getItem and removeItem, similar to localStorage in the browser', ->

        # Set
        authStorage.setItem('client_a', authResponseA )

        # Get
        expect( authStorage.getItem('client_a') ).to.eql authResponseA

        # Remove
        authStorage.removeItem('client_a')
        expect( authStorage.getItem('client_a') ).to.eql undefined



    it 'should throw an Error if authResponse contains an `error` property', ->

        errorReponse =
            error : 'code'
            error_description : 'message'


        expect ->
            authStorage.setItem('client_a', errorReponse)
        .to.throw Error, 'code'



    it 'should not return an authResponse if it has expired', ->

        authResponse.expires_in = 0
        authStorage.setItem 'client_a', authResponse
        expect( authStorage.getItem('client_a') ).to.eql undefined



    it 'should hold multiple cached tokens by client_id', ->

        authStorage.setItem('client_a', authResponseA)
        authStorage.setItem('client_b', authResponseB)

        authStorage.getItem('client_a').should.be.eql authResponseA
        authStorage.getItem('client_b').should.be.eql authResponseB


    context 'setItem', ->
        it 'should return the object stored for use in Promise chain', ->

            # Set
            resp = authStorage.setItem('client_a', authResponseA );
            expect( resp ).to.be.eql authResponseA


    describe 'setItem exceptions', ->

        ['null','undefined','','true','false','randomstring', '{}',0,1,true, false,[],{},{something:'random'},NaN,undefined].forEach (item) ->

            it "should throw error 'invalid_token' if setItem is called with '#{item}'", ->

                expect ->
                    authStorage.setItem('client_a', item)
                .to.throw Error, 'invalid_token'


            if typeof(item) != 'string'

                it  "should throw error 'invalid_token' if the authResponse.access_token is `#{JSON.stringify(item)}`, and not a string", ->

                    authResponse.access_token = item

                    expect ->
                        authStorage.setItem('client_a', authResponse)
                    .to.throw Error, 'invalid_token'



            if typeof(item) != 'number'

                it  "should not store the token if the authResponse.expires_in is `#{item}`, and not a number", ->

                    authResponse.expires_in = item
                    authStorage.setItem('client_a', authResponse)
                    expect( authStorage.getItem('client_a') ).to.be.eql undefined

