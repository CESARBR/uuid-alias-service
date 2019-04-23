_ = require 'lodash'
AliasService = require '../services/alias-service'
SubAliasService = require '../services/sub-alias-service'

class AliasController
  constructor: ({mongoDbUri, mongoDbOptions}) ->
    @aliasService = new AliasService {mongoDbUri, mongoDbOptions}
    @subAliasService = new SubAliasService {mongoDbUri, mongoDbOptions}

  find: (req, res) =>
    {name} = req.params

    onFind = (error, alias) =>
      return res.status(error.status).send error.messsage if error?.status?
      return res.status(500).send error.message if error?
      res.status(200).send(alias)

    if req.query.name
      alias = name
      {name} = req.query
      @subAliasService.find {alias,name}, onFind

    else
      @aliasService.find {name}, onFind


  delete: (req, res) =>
    {name} = req.params
    owner = req.meshbluAuth.uuid

    onDelete = (error) =>
      return res.status(error.status).send error.messsage if error?.status?
      return res.status(500).send error.message if error?
      res.status(204).end()

    if req.query.name
      alias = name
      {name} = req.query
      @subAliasService.delete {alias,name,owner}, onDelete
    else
      @aliasService.delete {name,owner}, onDelete

  update: (req, res) =>
    {name} = req.params
    owner = req.meshbluAuth.uuid
    {uuid} = req.body

    onUpdate = (error) =>
      return res.status(error.status).send error.messsage if error?.status?
      return res.status(500).send error.messsage if error?
      res.status(204).end()

    if req.query.name
      alias = name
      {name} = req.query
      @subAliasService.update {alias,name,owner}, {uuid}, onUpdate
    else
      @aliasService.update {name,owner}, {uuid}, onUpdate

  create: (req, res) =>
    {name, uuid} = req.body
    owner = req.meshbluAuth.uuid

    @aliasService.create {name, uuid, owner}, (error) =>
      return res.status(error.status).send error.messsage if error?.status?
      return res.status(500).send error.message if error?
      res.status(201).end()

  createSubAlias: (req, res) =>
    {alias} = req.params
    {name, uuid} = req.body
    owner = req.meshbluAuth.uuid

    @subAliasService.create {alias, name, uuid, owner}, (error) =>
      return res.status(error.status).send error.messsage if error?.status?
      return res.status(500).send error.message if error?
      res.status(201).end()

module.exports = AliasController
