_ = require 'lodash'
mongojs = require 'mongojs'
Datastore = require 'meshblu-core-datastore'
http = require 'http'
UUID_REGEX = /[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/i

class AliasService
  constructor: ({mongoDbUri, mongoDbOptions}) ->
    @datastore = new Datastore
      database: mongojs mongoDbUri, null, mongoDbOptions
      collection: 'aliases'

  create: ({name,uuid,owner}, callback) =>
    return callback @userError 422, http.STATUS_CODES[422] unless @_valid {name,uuid,owner}

    @datastore.insert {name, uuid, owner}, (error) =>
      return callback error if error?
      callback()

  delete: ({name, owner}, callback) =>
    @datastore.findOne {name}, (error, alias) =>
      return callback error if error?
      return callback @userError 404, http.STATUS_CODES[404] if _.isEmpty alias
      return callback @userError 403, http.STATUS_CODES[403] unless alias.owner == owner

      @datastore.remove {name}, (error, alias) =>
        return callback error if error?
        callback()

  find: ({name}, callback) =>
    @datastore.findOne {name}, (error, alias) =>
      return callback @userError 404, http.STATUS_CODES[404] if _.isEmpty alias
      return callback error if error?
      callback null, alias

  update: ({name, owner}, {uuid}, callback) =>
    @datastore.findOne {name}, (error, alias) =>
      return callback error if error?

      return callback @userError 404, http.STATUS_CODES[404] if _.isEmpty alias
      return callback @userError 403, http.STATUS_CODES[403] unless alias.owner == owner

      update =
        $set: {uuid}

      @datastore.update {name}, update, (error, alias) =>
        return callback error if error?
        callback()

  userError: (status, message) =>
    error = new Error message
    error.status = status
    error

  _valid: ({name,uuid,owner}) =>
    return false if _.isEmpty name
    return false if _.isEmpty uuid
    return false if UUID_REGEX.test name
    return false unless UUID_REGEX.test uuid
    return false unless UUID_REGEX.test owner
    true

module.exports = AliasService
