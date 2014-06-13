events = require 'events'
async = require 'async'
_ = require 'lodash'
fs = require 'fs'
preprocess = require './preprocess'

module.exports = (ec2) ->
	find_role = (require './finder') ec2


	next_id = 0
	replace = (target,dict,next) ->
		role_cached = {}
		role_cached.E = new events.EventEmitter()
		
		id = next_id++
		# console.log 'replacing', dict, id
		async.series [
			(next) ->
				exts = _.uniq _.filter _.values(dict), (x) -> /^\@role:/.test x			
				find_exts = _.compact exts.map (e) ->
					[prefix,role] = e.split(':')
					if role_cached[role]?
						(next) ->
							if role_cached[role] == 'pending'
								# console.log 'pending!', id
								role_cached.E.once role, ->
									# console.log 'resovled', id
									next()
							else
								# console.log 'reuse!',id
								next()					
					else
						role_cached[role] = 'pending'
						# console.log 'begin to fetch', role
						(next) ->
							# console.log 'find_role!', id
							find_role role, (err,instances) ->
								instances = _.reject instances or [], (i) -> not i.PrivateIpAddress?
								role_cached[role] = instances
								role_cached.E.emit role

								return next err if err
								return next 404 unless instances.length	

								# console.log 'find_role exit', id
								next()
				async.parallel find_exts, next
			(next) ->
				# console.log 'replace #2', id
				dict = preprocess dict
				for k,v of dict
					if /^\@role:/.test v
						[prefix,role] = v.split(':')
						# console.log v, prefix, role, '<--'
						v = role_cached[role]?[0]?.PrivateIpAddress									
						return next [500,"#{role}을 찾을 수 없습니다"] unless v?					

					target = target.replace new RegExp(k,'g'), v
				# console.log JSON.stringifytarget
				# console.log target
				next null, target
		], (err,result) ->			
			next err,result?[1]

	replace