_ = require 'lodash'
mongojs = require 'mongojs'
Datastore = require 'meshblu-core-datastore'
http = require 'http'
UUID_REGEX = /[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/i

class SubAliasService
  constructor: ({mongoDbUri, mongoDbOptions}) ->
    @datastore = new Datastore
      database: mongojs mongoDbUri, null, mongoDbOptions
      collection: 'aliases'

  create: ({alias,name,uuid,owner}, callback) =>
    return callback @userError 422 unless @_valid {name,uuid,owner}

    @datastore.findOne name: alias, (error, response) =>
      return callback error if error?
      return callback @userError 404, http.STATUS_CODES[404] if _.isEmpty response
      return callback @userError 403, http.STATUS_CODES[403] unless response.owner == owner

      update =
        $addToSet:
          subaliases:
            name: name
            uuid: uuid

      @datastore.update name: alias, update, (error) =>
        return callback error if error?
        callback()

  delete: ({alias,name,owner}, callback) =>
    @datastore.findOne name: alias, (error, response) =>
      return callback error if error?
      return callback @userError 404, http.STATUS_CODES[404] if _.isEmpty response
      return callback @userError 403, http.STATUS_CODES[403] unless response.owner == owner

      update =
        $pullAll:
          subaliases: {name}

      @datastore.update name: alias, update, (error) =>
        return callback error if error?
        callback()

  find: ({alias,name}, callback) =>
    query =
      name: alias
      'subaliases.name': name

    @datastore.findOne query, (error, response) =>
      return callback @userError 404, http.STATUS_CODES[404] if _.isEmpty response
      return callback error if error?
      callback null, _.find response.subaliases, {name}

  update: ({alias,name,owner}, {uuid}, callback) =>
    return callback @userError 422 unless @_valid {name,uuid,owner}

    query =
      name: alias
      'subaliases.name': name

    @datastore.findOne query, (error, response) =>
      return callback error if error?
      return callback @userError 404, http.STATUS_CODES[404] if _.isEmpty response
      return callback @userError 403, http.STATUS_CODES[403] unless response.owner == owner

      update =
        $set:
          'subaliases.$.uuid': uuid

      @datastore.update query, update, (error) =>
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

module.exports = SubAliasService
