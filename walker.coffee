async = require 'async'
_ = require 'lodash'

module.exports = (ec2,launch) ->	
	find_role = (require './finder') ec2

	go = (cands,next) ->
		return next() if cands.length == 0

		targets = _.reject cands, (c) -> c[1].depends?.length > 0
		pending = _.filter cands, (c) -> c[1].depends?.length > 0
		wait_for = _.filter targets, (c) ->
			_.any pending, (p) -> _.contains p[1].depends, c[0]
		just_launch = _.without targets, wait_for...

		launch_role = (c,next) ->
			opts = _.extend c[1].instance, role:c[0]				
			find_role c[0], (err,data) ->
				if err					
					console.log "#{c[0]}이 없습니다. 준비하겠습니다.".bold.red
					launch opts, c[1].env, next
				else
					console.log "#{c[0]}을 발견했습니다.".bold.yellow
					next null, Instances:data

		wait_for_jobs = wait_for.map (c) ->
			(next) ->
				launch_role c, (err,data) ->
					return next err if err

					#console.log "#{c[0]}를 기다리고 있습니다."

					resources = [data.Instances[0].InstanceId]
					query = InstanceIds:resources

					ec2.waitFor 'instanceRunning', query, next
		just_launch_jobs = just_launch.map (c) ->
			(next) ->
				launch_role c, next				

		# console.log wait_for_jobs.length, just_launch_jobs.length

		jobs = _.flatten [wait_for_jobs,just_launch_jobs]
		async.parallel jobs, (err) ->		
			return next err if err

			launched = wait_for.map (c) -> c[0]
			pending.map (c) ->
				c[1].depends = _.without c[1].depends, launched...
			go pending, next
