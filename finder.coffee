_ = require 'lodash'

# state_names = {}

module.exports = (ec2) ->
	find_role = (role,next) ->
		# console.log 'find_role',role
		ec2.describeInstances {}, (err,data) ->
			return next err if err 		
			result = _.flatten data?.Reservations?.map (r) ->
				instances = _.reject (r.Instances or []), (x) -> 
					# name = x.State.Name
					# unless state_names[name]?
						# state_names[name] = name
						# console.log name.bold.red

					not (x.State.Name == 'pending' or x.State.Name == 'running')
				instances.forEach (i) ->
					i.Tag = {}
					i.Tags.map (t) ->
						i.Tag[t.Key] = t.Value

				_.filter instances, (i) -> 
					unless i.Tag.role?
						console.log 'no tag here', i					
					i.Tag.role == role
					
			return next 404 if result.length == 0
			next null, result