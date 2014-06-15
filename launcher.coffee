async = require 'async'
_ = require 'lodash'
fs = require 'fs'
path = require 'path'

load = (base,file) ->
	file = fs.readFileSync path.join(base,file)
	lines = file.toString().split('\n')	
	lines = lines.map (line) ->
		if /^#include/.test line
			(load base, line.split(' ')[1]).toString()
		else
			line
	# console.log lines
	new Buffer(lines.join('\n'))

preprocess = require './preprocess'
hash = require './hash'

module.exports = (ec2,default_instance) ->
	replace = (require './replacer') ec2

	launch = (global,opts,env,next) ->
		{cluster} = global
		{public_ip,role,script,only_hash} = _opts = preprocess opts
		
		script = load 'scripts', script

		replace script.toString(), env, (err,replaced) ->
			return next err if err
			userdata = new Buffer(replaced).toString('base64')

			config = _.extend _.clone(default_instance),
				UserData : userdata
				MinCount : 1
				MaxCount : 1

			config = _.extend config, opts.instance or {}

			sha1 = hash 
				role:role
				public_ip:public_ip
				config:config

			# if role == 'backend'
			# 	console.log
			# 		role:role
			# 		public_ip:public_ip
			# 		config:config

			if only_hash
				return next null, sha1
			
			ec2.runInstances config,		
				(err,data) ->
					return next err if err

					console.log "#{role} 설정 완료".bold.green

					# console.log JSON.stringify data

					resources = _.pluck data.Instances, 'InstanceId'

					async.parallel [
						(next) ->
							return next() unless public_ip?
							return next 500 unless resources.length == 1

							console.log "Public IP(#{public_ip})를 #{role}에 연결합니다."

							ec2.waitFor 'instanceRunning', InstanceIds:resources, (err) ->
								return next err if err

								ec2.associateAddress 
									InstanceId:resources[0]
									PublicIp:public_ip
									next
						(next) ->
							ec2.createTags 
								Resources:resources
								Tags:[
									{Key:'role',Value:role}
									{Key:'cluster',Value:cluster}
									{Key:'sha1',Value:sha1}
								]
								next
					], (err) ->
						return next err if err
						next null, data
