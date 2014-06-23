require 'colors'

AWS = require 'aws-sdk'
AWS.config.region = 'ap-northeast-1'

ec2 = new AWS.EC2()

recipes = (require 'cson').parseFileSync './recipes.cson'	
CLUSTER_ID = recipes.id
recipes = recipes.cluster

ec2.CLUSTER_ID = CLUSTER_ID

async = require 'async'
_ = require 'lodash'

prep = (next) ->
	console.log '기존의 instance를 지우고 있습니다.'

	ec2.describeInstances {}, (err,data) ->
		return next err if err
		cands = _.flatten data.Reservations.map (d) -> d.Instances		
		cands = _.reject cands, (x) -> 
			return true unless _.any x.Tags, (t) -> t.Key == 'cluster' and t.Value == ec2.CLUSTER_ID
			x.State.Name == 'terminated'
		instances = _.pluck cands, 'InstanceId'

		if instances.length
			console.log "#{instances.length}개의 인스턴스를 종료(terminate)합니다."
			ec2.terminateInstances InstanceIds: instances, (err,data) ->			
				next err
		else
			next()

launch = (require './launcher') ec2,
	InstanceType : 'm1.small'
	ImageId : 'ami-bddaa2bc'
	SecurityGroups : ['default']

walk = (require './walker')	ec2, (args...) ->
	launch cluster:CLUSTER_ID, args...

cleanup = (next) ->
	async.waterfall [
		(next) ->
			ec2.describeInstances {}, (err,data) ->
				return next err if err
				return next null, _.flatten data?.Reservations?.map (r) ->
					instances = _.reject (r.Instances or []), (x) -> not (x.State.Name == 'pending' or x.State.Name == 'running')
				
		(instances,next) ->
			instances = instances.map (i) ->
				i.Tag = {}
				i.Tags.map (t) ->
					i.Tag[t.Key] = t.Value
				i
			instances = _.filter instances, (i) -> i.Tag.cluster == ec2.CLUSTER_ID
			jobs = _.pairs(recipes).map (c) ->
				(next) ->
					opts = _.extend role:c[0], c[1].instance
					# console.log '<___ B4', opts
					launch cluster:CLUSTER_ID, _.extend(opts,only_hash:true), c[1].env, (err,sha1) ->
						old_instances = _.filter instances, (i) -> 
							# console.log i, '<--'
							i.Tag.role == c[0] and i.Tag.sha1 != sha1
						if old_instances.length
							console.log "#{old_instances.length}개의 구 인스턴스!", c[0], sha1, old_instances[0].Tag.sha1
							query = _.pluck old_instances, 'InstanceId'
							ec2.terminateInstances InstanceIds:query, next
						else
							next()
			
			abandoned = _.reject instances, (i) -> recipes[i.Tag.role]?
			if abandoned.length
				console.log "#{abandoned.length}개의 버려진 인스턴스를 종료합니다.".red.bold
				jobs.push (next) ->
					query = _.pluck abandoned, 'InstanceId'
					ec2.terminateInstances InstanceIds:query, next

			async.parallel jobs, next
	], next

main = (next) ->
	walk _.pairs(recipes), next

argv = (require 'minimist')(process.argv.slice(2))
jobs = [cleanup,main]
if argv.c
	jobs.unshift prep
async.series jobs, (err) ->
	console.log '종료!'.bold.green
	if err
		console.error err
