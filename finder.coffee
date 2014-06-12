_ = require 'lodash'

module.exports = (ec2) ->
	find_role = (role,next) ->
		# console.log 'find_role',role
		ec2.describeInstances {}, (err,data) ->
			return next err if err 		
			result = _.flatten data?.Reservations?.map (r) ->
				instances = _.reject (r.Instances or []), (x) -> not (x.State.Name == 'pending' or x.State.Name == 'running')
				_.filter instances, (i) ->
					_.any i.Tags, (t) -> 
						t.Key == 'role' and t.Value == role
			return next 404 if result.length == 0
			next null, result