crypto = require 'crypto'
module.exports = hash = (c) ->
	shasum = crypto.createHash 'sha1'
	shasum.update JSON.stringify c
	shasum.digest 'hex'
