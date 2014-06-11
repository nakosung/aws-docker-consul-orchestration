fs = require 'fs'
_ = require 'lodash'

module.exports = preprocess = (obj) ->
	obj = _.clone obj
	for k,v of obj
		if /^\@file:/.test v
			[prefix,file] = v.split(':')
			obj[k] = (fs.readFileSync file).toString()			
	obj