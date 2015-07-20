module.exports = (env) ->
	Promise = env.require 'bluebird'
	assert = env.require 'cassert'
	MjpegCamera = require 'mjpeg-camera'
	fs = env.require 'fs'
	path = env.require 'path'

	class IpCameraPlugin extends env.plugins.Plugin
		init: (app, @framework, @config) =>
			deviceConfigDef = require("./device-config-schema")
			@framework.deviceManager.registerDeviceClass("IpCameraDevice",{
				configDef : deviceConfigDef.IpCameraDevice,
				createCallback : (config) => new IpCameraDevice(config,this)
			})
			@framework.on "after init", =>
				mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
				if mobileFrontend?
					mobileFrontend.registerAssetFile 'js', "pimatic-ipcamera/app/IpCameraTempl-page.coffee"
					mobileFrontend.registerAssetFile 'html', "pimatic-ipcamera/app/IpCameraTempl-template.html"
		info: (text) ->
			env.logger.info text
			return
		debug: (text) ->
			env.logger.debug text
			return
		replaceAll: (x,s,r) -> 
			return x.split(s).join(r)
			
	class IpCameraDevice extends env.devices.Device
		attributes:
			cameraUrl:
				description: "URL of IP Camera"
				type: "string"		
			filename:
				description: "File name of the output"
				type: "string"
			refresh:
				description: "Time to refresh screenshot"
				type: "number"
			actions:
				sendCommand:
					description: "action for camera"
					params: 
						command: 
							type: "string"				
		template: 'ipcamera'
		
		constructor: (@config,@plugin) ->
			@id = @config.id
			@name = @config.name
			@filename = @config.filename
			@refresh = @config.refresh
			@cameraUrl = @config.cameraUrl
			super()
			if @refresh > 0
				@getSnapshot(@filename)
				setInterval( ( => @getSnapshot(@filename) ), 1000*@refresh)
		
		getCameraUrl : -> Promise.resolve(@cameraUrl)	
		getRefresh : -> Promise.resolve(@refresh)
		getFilename: -> Promise.resolve(@filename)
		getSnapshot: (@filename) ->
			camera = new MjpegCamera(url: @cameraUrl)
			camera.getScreenshot((err,frame)=>
				dirString = path.dirname(fs.realpathSync(__filename+"\\..\\"))+"\\pimatic-mobile-frontend\\public\\"
				imgPath = dirString + "img\\"
				if process.platform not in ['win32', 'win64']
					imgPath = @plugin.replaceAll(imgPath,"\\","/")
				fs.exists(imgPath,(exists)=>
					if !exists 
						@plugin.debug "Creating Image Path...only create one time"
						fs.mkdir(imgPath)
					fs.writeFile(imgPath+@filename, frame)
					return
				)
				return
		  )
			return
		sendCommand: (command) ->
			return "test"
	myPlugin = new IpCameraPlugin
	return myPlugin