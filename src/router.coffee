AliasController = require './controllers/alias-controller'

class Router
  constructor: ({mongoDbUri, mongoDbOptions}) ->
    @aliasController = new AliasController {mongoDbUri, mongoDbOptions}

  route: (app) =>
    app.post '/aliases', @aliasController.create
    app.post '/aliases/:alias', @aliasController.createSubAlias
    app.get '/aliases/:name', @aliasController.find
    app.delete '/aliases/:name', @aliasController.delete
    app.patch '/aliases/:name', @aliasController.update

module.exports = Router
