require 'colors'

AWS = require 'aws-sdk'
AWS.config.region = 'ap-northeast-1'

ec2 = new AWS.EC2()

async = require 'async'
_ = require 'lodash'

prep = (next) ->
	console.log '기존의 instance를 지우고 있습니다.'

	ec2.describeInstances {}, (err,data) ->
		return next err if err
		cands = _.flatten data.Reservations.map (d) -> d.Instances		
		cands = _.reject cands, (x) -> x.State.Name == 'terminated'
		instances = _.pluck cands, 'InstanceId'

		if instances.length
			ec2.terminateInstances InstanceIds: instances, (err,data) ->			
				next err
		else
			next()

launch = (require './launcher') ec2,
	InstanceType : 't1.micro'
	ImageId : 'ami-bddaa2bc'
	SecurityGroups : ['default']
walk = (require './walker')	ec2, launch

recipes = (require 'cson').parseFileSync './recipes.cson'	

main = (next) ->
	walk _.pairs(recipes), next

argv = (require 'minimist')(process.argv.slice(2))
jobs = [main]
if argv.c
	jobs.unshift prep
async.series jobs, (err) ->
	console.log '종료!'.bold.green
	if err
		console.error err
