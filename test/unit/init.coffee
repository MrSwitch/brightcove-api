# Init

# Brightcove instance
bc = require "#{SRC}/index"

# Tests
describe 'bc.init()', ->

	it 'should create instances of the BrightCove API which contain the local settings, autonomous from the global settings', ->

		init = bc.init({
			client_id : 'a'
		})

		# The local value should be updated
		expect( init.options.client_id ).to.be.eql 'a'

		# The global value should be updated
		expect( bc.options.client_id ).to.be.eql 'a'

		# Change the client_id globally
		bc.init({
			client_id : 'b'
		})

		# The global value should be updated
		expect( bc.options.client_id ).to.be.eql 'b'

		# The local value should not have changed
		expect( init.options.client_id ).to.be.eql 'a'

		# Now lets change the instance settings
		init.init({
			client_id : 'c'
		})

		# The local value to have changed
		expect( init.options.client_id ).to.be.eql 'c'

		# The global value should not have changed
		expect( bc.options.client_id ).to.be.eql 'b'