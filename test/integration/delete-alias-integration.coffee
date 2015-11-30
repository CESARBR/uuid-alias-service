http    = require 'http'
request = require 'request'
shmock  = require 'shmock'
Server  = require '../../src/server'
mongojs = require 'mongojs'
Datastore = require 'meshblu-core-datastore'
iri = require 'iri'

describe 'DELETE /aliases/poor-trunk-ventilation', ->
  beforeEach ->
    @meshblu = shmock 0xd00d

  afterEach (done) ->
    @meshblu.close => done()

  beforeEach (done) ->
    meshbluConfig =
      server: 'localhost'
      port: 0xd00d

    serverOptions =
      port: undefined,
      disableLogging: true
      meshbluConfig: meshbluConfig
      mongoDbUri: 'mongodb://127.0.0.1/test-uuid-alias-service'

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  beforeEach ->
    @whoamiHandler = @meshblu.get('/v2/whoami')
      .reply(200, '{"uuid": "user-uuid"}')

  beforeEach (done) ->
    @datastore = new Datastore
      database: mongojs 'mongodb://127.0.0.1/test-uuid-alias-service'
      collection: 'aliases'
    @datastore.remove {}, (error) => done() # delete everything

  afterEach (done) ->
    @server.stop => done()

  context 'when the alias exists', ->
    context 'an ascii name', ->
      beforeEach (done) ->
        @datastore.insert name: 'poor-trunk-ventilation', uuid: '21560426-7338-450d-ab10-e477ef1908a6', owner: 'user-uuid', (error, @alias) =>
          done error

      beforeEach (done) ->
        auth =
          username: 'user-uuid'
          password: 'user-token'

        options =
          auth: auth
          json: true

        request.del "http://localhost:#{@serverPort}/aliases/poor-trunk-ventilation", options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 204', ->
        expect(@response.statusCode).to.equal 204

      beforeEach (done) ->
        @datastore.findOne name: 'poor-trunk-ventilation', (error, @alias) =>
          done error

      it 'should delete the alias in mongo', ->
        expect(@alias).to.be.null

    context 'a unicode name', ->
      beforeEach (done) ->
        @datastore.insert name: '💩', uuid: '4fac613f-fea4-49b6-8c0a-715d15d21120', owner: 'user-uuid', (error, @alias) =>
          done error

      beforeEach (done) ->
        auth =
          username: 'user-uuid'
          password: 'user-token'

        options =
          auth: auth
          json: true

        path = new iri.IRI "http://localhost:#{@serverPort}/aliases/💩"

        request.del path.toURIString(), options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 204', ->
        expect(@response.statusCode).to.equal 204

      beforeEach (done) ->
        @datastore.findOne name: '💩', (error, @alias) =>
          done error

      it 'should delete the alias in mongo', ->
        expect(@alias).to.be.null

  context 'when the alias does not exists', ->
    beforeEach (done) ->
      auth =
        username: 'user-uuid'
        password: 'user-token'

      options =
        auth: auth
        json: true

      request.del "http://localhost:#{@serverPort}/aliases/car-over-cliff", options, (error, @response, @body) =>
        done error

    it 'should authenticate with meshblu', ->
      expect(@whoamiHandler.isDone).to.be.true

    it 'should respond with 404', ->
      expect(@response.statusCode).to.equal 404

    it 'should not return an alias', ->
      expect(@body).to.be.undefined

  context 'when a different user', ->
    context 'when the alias exists', ->
      beforeEach (done) ->
        @datastore.insert name: 'poor-trunk-ventilation', uuid: '21560426-7338-450d-ab10-e477ef1908a6', owner: 'user-uuid', (error, @alias) =>
          done error

      beforeEach (done) ->
        auth =
          username: 'other-user-uuid'
          password: 'other-user-token'

        options =
          auth: auth
          json: true

        request.del "http://localhost:#{@serverPort}/aliases/poor-trunk-ventilation", options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 403', ->
        expect(@response.statusCode).to.equal 403

      beforeEach (done) ->
        @datastore.findOne name: 'poor-trunk-ventilation', (error, @alias) =>
          done error

      it 'should not delete the record in mongo', ->
        expect(@alias).to.contain name: 'poor-trunk-ventilation', uuid: '21560426-7338-450d-ab10-e477ef1908a6'
