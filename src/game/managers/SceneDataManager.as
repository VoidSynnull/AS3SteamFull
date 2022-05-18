package game.managers
{
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.character.LookParser;
	import game.data.game.GameEvent;
	import game.data.scene.CameraLayerData;
	import game.data.scene.SceneData;
	import game.data.scene.SceneParser;
	import game.scene.template.GameScene;
	import game.util.DataUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class SceneDataManager
	{
		public function SceneDataManager(scene:Scene)
		{
			this.loaded = new Signal();
			this.filesLoaded = new Signal(Array);
			_scene = scene;
		}
		
		/**
		 * load scene xml, on loaded calls parseSceneData which calls callback passing 
		 * @param sceneXmlPath - url or name of scene xml file, if not specified defaults to "scene.xml"
		 * @param prefix - prefix containing data files
		 * @param callback - eventually called by sceneFilesLoaded, Array of urls of loaded scene files supplied as callback parameter
		 * @param failureCallback - sends
		 */
		public function loadSceneConfiguration(sceneXmlPath:String = null, prefix:String = null, callback:Function = null, failureCallback:Function = null):void
		{
			if( !DataUtils.validString(sceneXmlPath) ) { sceneXmlPath = GameScene.SCENE_FILE_NAME; }
			if(prefix == null)
			{
				prefix = _scene.groupPrefix;
			}
			
			var url:String = getFullUrl(sceneXmlPath, prefix);
			if(_scene.fetchFromServer) {
				_scene.shellApi.loadFileWithServerFallback(url,parseSceneData,prefix,callback);
			}
				
			else
			{
				var sceneXml:XML = _scene.shellApi.getFile(url);
			
				if(sceneXml == null)
				{
					_scene.shellApi.loadFile(url, parseSceneData, prefix, callback);
				}
				else
				{
					if( sceneXml.hasOwnProperty("pullFromServer") )
					{
						_scene.shellApi.logWWW("scene xml found, but force pull from server");
						_scene.shellApi.loadFile(url, parseSceneData, prefix, callback);
					}
					else 
					{
						parseSceneData(sceneXml, prefix, callback, failureCallback);
					}
				}
			}
		}
		
		/**
		 * Merges together data and asset files for a scene
		 * NOTE - requires that merging files have identical names, if file names may not match use mergeSceneFilesToScene
		 * @param files - Array of file names to be merged into original files
		 * @param prefix - prefix of given files to be merged into original files
		 * @param mergePrefix - prefix of original files that given files are being merged into
		 * @param mergeProcessor - function if given is used to merge files, if returns false will continue onto standard merge process
		 */
		public function mergeSceneFiles(files:Array = null, prefix:String = "", mergePrefix:String = null, mergeProcessor:Function = null, suffix:String = ""):void
		{
			if(mergePrefix != null)
			{
				if(files != null)
				{
					var file:*;
					var originalFile:*;
					var url:String;
					var originalUrl:String;
					var strippedUrl:String;
					var urlParts:Array;
					var layers:Array = getOrderedLayers(_scene.sceneData.layers);
					var delay:Array = [];
					
					for(var n:int = 0; n < files.length; n++)
					{
						url = getFullUrl(files[n], prefix);						
						
						// if file contains data or asset prefix replace with mergePrefix to get full url of file to be merged into
						if(files[n].indexOf(_scene.shellApi.assetPrefix) > -1 || files[n].indexOf(_scene.shellApi.dataPrefix) > -1)
						{
							strippedUrl = files[n];
							urlParts = strippedUrl.split("/");
							strippedUrl = urlParts[urlParts.length - 1];
							originalUrl = getFullUrl(strippedUrl, mergePrefix);
						}
						else
						{
							var fileName:String = files[n];
							var layerName:String = fileName.substr(0,fileName.length-4);
							var layerData:CameraLayerData;
							for(var i:int = 0; i < layers.length; i++)
							{
								layerData = layers[i];
								if(layerData.id == layerName)
								{
									fileName = layerData.asset;
								}
							}
							originalUrl = getFullUrl(fileName, mergePrefix);
						}
						
						file = _scene.shellApi.getFile(url);
						
						if(file != null)
						{
							originalFile = _scene.shellApi.getFile(originalUrl);
							
							// if a merge processor function has been passed in, let it deal with any custom modifications to the loaded files.
							if(mergeProcessor != null)
							{
								if(url.indexOf("interactive") != -1)
								{
									delay.push(Command.create(mergeProcessor, file, url, originalFile, originalUrl, suffix));
									continue;
								}
								// if a mergeProcessor returns false, it means it will handle the merge on its own.  Otherwise the default
								//   merge behavior occurs.
								if(!mergeProcessor.apply(null, [file, url, originalFile, originalUrl, suffix]))
								{
									continue;
								}
							}
							
							if(url.indexOf(".xml") > -1)
							{
								if(originalFile != null)
								{
									originalFile = DataUtils.mergeXML(file.copy(), originalFile, "combine");
								}
								else
								{
									originalFile = file.copy();
								}
								
								_scene.shellApi.setCache(originalUrl, originalFile);
							}
							else if(url.indexOf(".swf") > -1)
							{
								if(originalFile != null && (url.indexOf("interactive.swf") > -1 || url.indexOf("hits.swf") > -1))
								{
									mergeHits(file, originalFile, suffix);
								}
								else if(originalFile != null)
								{
									originalFile.addChild(file);
								}
								else
								{
									_scene.shellApi.setCache(originalUrl, file);
								}
							}
						}
					}
					for(var d:int = 0; d < delay.length; d++)
					{
						delay[d]();
					}
				}
			}
		}
		
		private function getOrderedLayers(layers:Dictionary):Array
		{
			var orderedLayers:Array = new Array();
			var layerData:CameraLayerData;
			var allLayerData:Dictionary;
			var events:Vector.<String> = _scene.shellApi.getEvents().slice();
			events.unshift(GameEvent.DEFAULT);
			
			for each(allLayerData in layers)
			{
				// get the layer data associated with the most recent event.
				for (var n:uint = 0; n < events.length; n++)
				{
					if(allLayerData[events[n]])
					{
						layerData = allLayerData[events[n]];
					}
				}
				
				if(layerData)
				{
					orderedLayers.push(layerData);
					
					layerData = null;
				}
			}
			
			orderedLayers.sortOn("zIndex", Array.NUMERIC); 
			
			return(orderedLayers);
		}
		
		private function getFullUrl(url:String, prefix:String = ""):String
		{
			var fullUrl:String;
			var typePrefix:String = _scene.shellApi.assetPrefix;
			
			if (String(url).indexOf(".xml") > -1)
			{
				typePrefix = _scene.shellApi.dataPrefix;
			}
			
			if(url.indexOf(typePrefix) > -1)
			{
				// if it has the type path in the url, assume it is an absolute url
				fullUrl = url;
			}
			else
			{
				fullUrl = typePrefix + prefix + url;
			}
			
			return(fullUrl);
		}
		
		/**
		 * Parse the scene xml and load any files included in the &lt;absoluteFilePaths&gt; tag of scene.xml.
		 * @param sceneXml
		 * @param prefix
		 * @param callback - eventually called by sceneFilesLoaded, Array of urls of loaded scene files supplied as callback parameter
		 * @param failureCallback
		 */
		private function parseSceneData(sceneXml:XML, prefix:String, callback:Function = null, failureCallback:Function = null):void
		{
			if( sceneXml != null )
			{
				var parser:SceneParser = new SceneParser();
				var sceneData:SceneData = parser.parse(sceneXml, _scene.shellApi);
				var files:Array = sceneData.data.concat(sceneData.assets);
				
				if(prefix == _scene.groupPrefix)
				{
					// only add global if there is any dialog to begin with
					if(sceneData.data.indexOf(GameScene.DIALOG_FILE_NAME) >= 0)
						sceneData.absoluteFilePaths.push(SHARED_PATH + GameScene.DIALOG_FILE_NAME);
					
					// TODO : streamline this.
					if(sceneData.prependTypePath)
					{
						var fullUrls:Array = new Array();
						
						for(var n:int = 0; n < sceneData.absoluteFilePaths.length; n++)
						{
							fullUrls.push(getFullUrl(sceneData.absoluteFilePaths[n]));
						}
						
						sceneData.absoluteFilePaths = fullUrls;
					}
					
					if( sceneData.hasPlayer )
					{
						if (isNaN(_scene.shellApi.profileManager.active.lastX) || isNaN(_scene.shellApi.profileManager.active.lastY))
						{
							_scene.shellApi.profileManager.active.lastX = sceneData.startPosition.x;
							_scene.shellApi.profileManager.active.lastY = sceneData.startPosition.y;
							_scene.shellApi.profileManager.active.lastDirection = sceneData.startDirection;
						}
						if(sceneXml.player.hasOwnProperty("skin"))
						{
							var gender:Number = _scene.shellApi.profileManager.active.look.gender;	
							var playerLookData2:LookData = new LookData();
							
							if(gender == 0)
								playerLookData2 = (sceneData.hasPlayer) ? LookParser.parseChar( XML(sceneXml.player.skin.girlLook)) : null;
							else
								playerLookData2 = (sceneData.hasPlayer) ? LookParser.parseChar( XML(sceneXml.player.skin.boyLook)) : null;
							
							if(playerLookData2.getValue(SkinUtils.SKIN_COLOR) == null)
								playerLookData2.applyAspect(new LookAspectData(SkinUtils.SKIN_COLOR,_scene.shellApi.profileManager.active.look.skinColor));
							if(playerLookData2.getValue(SkinUtils.HAIR_COLOR) == null)
								playerLookData2.applyAspect(new LookAspectData(SkinUtils.HAIR_COLOR,_scene.shellApi.profileManager.active.look.hairColor));
							playerLookData2.applyAspect(new LookAspectData(SkinUtils.GENDER,_scene.shellApi.profileManager.active.gender));
							_scene.shellApi.saveLook(playerLookData2);
							//_scene.shellApi.profileManager.active.look.gender = gender;
						}
					}
					
					_scene.sceneData = sceneData;
				}
				else
				{
					// merging camera limits
					if(_scene.sceneData.cameraLimits && sceneData.cameraLimits)
					{
						if(sceneData.cameraLimits.bottom > _scene.sceneData.cameraLimits.bottom)
						{
							_scene.sceneData.cameraLimits.bottom = sceneData.cameraLimits.bottom;
						}
						if(sceneData.cameraLimits.left < _scene.sceneData.cameraLimits.left)
						{
							_scene.sceneData.cameraLimits.left = sceneData.cameraLimits.left;
						}
						if(sceneData.cameraLimits.top < _scene.sceneData.cameraLimits.top)
						{
							_scene.sceneData.cameraLimits.top = sceneData.cameraLimits.top;
						}
						if(sceneData.cameraLimits.right > _scene.sceneData.cameraLimits.right)
						{
							_scene.sceneData.cameraLimits.right = sceneData.cameraLimits.right;
						}
					}
					//mergin bounds
					if(_scene.sceneData.bounds && sceneData.bounds)
					{
						if(sceneData.bounds.bottom > _scene.sceneData.bounds.bottom)
						{
							_scene.sceneData.bounds.bottom = sceneData.bounds.bottom;
						}
						if(sceneData.bounds.left < _scene.sceneData.bounds.left)
						{
							_scene.sceneData.bounds.left = sceneData.bounds.left;
						}
						if(sceneData.bounds.top < _scene.sceneData.bounds.top)
						{
							_scene.sceneData.bounds.top = sceneData.bounds.top;
						}
						if(sceneData.bounds.right > _scene.sceneData.bounds.right)
						{
							_scene.sceneData.bounds.right = sceneData.bounds.right;
						}
					}
				}
				loadSceneFiles(files, sceneData.absoluteFilePaths, prefix, callback);
			}
			else
			{
				// TODO :: We need to handling this scenario. - bard
				trace( "ERROR :: SceneDataManager :: parseSceneData : sceneXml received was null, TODO :: hand this error case.");
				if( failureCallback != null ) { failureCallback(); }
			}
		}
		
		/**
		 * load all external files from the &lt;data&gt; and &lt;assets&gt; tags of the scene.xml.
		 * @param files
		 * @param absoluteUrls
		 * @param prefix
		 * @param callback - eventually called by sceneFilesLoaded, Array of urls of loaded scene files supplied as callback parameter
		 */
		private function loadSceneFiles(files:Array, absoluteUrls:Array, prefix:String, callback:Function = null):void
		{
			if(files.length > 0)
			{
				var fileList:Array = new Array();
				var url:String;
				
				for(var n:int = 0; n < files.length; n++)
				{
					url = getFullUrl(files[n], prefix);
					
					if(_scene.shellApi.getFile(url) == null)
					{
						fileList.push(url);
					}
				}
				
				fileList = fileList.concat(absoluteUrls);
				
				if(fileList.length > 0)
				{
					_scene.shellApi.loadFiles(fileList, sceneFilesLoaded, files.concat(absoluteUrls), callback);
					return;
				}
			}
			sceneFilesLoaded();
		}
		
		/**
		 * Handler for scene files loaded, returns loaded files 
		 * @param files
		 * @param callback - Array of urls of loaded file supplied as callback paramaters
		 */
		private function sceneFilesLoaded(files:Array = null, callback:Function = null):void
		{
			loaded.dispatch();
			filesLoaded.dispatch(files);
			if(callback != null)
			{
				callback.apply(null, [files]);
			}
		}
		
		/**
		 * Merges together interactive/hit layers
		 * @param file
		 * @param originalFile
		 */
		private function mergeHits(file:*, originalFile:*, suffix:String):void
		{
			var nextChild:MovieClip;
			var addedChild:MovieClip;
			
			while (file.numChildren > 0)
			{
				nextChild = file.getChildAt(0);
				
				if(nextChild.name == "bitmapHits")
				{
					addedChild = originalFile.bitmapHits.addChild(file.bitmapHits);
				}
				else
				{
					addedChild = originalFile.addChild(nextChild);
					addedChild.name += suffix;
					originalFile[addedChild.name] = addedChild;
				}
			}
		}
		
		public var loaded:Signal;
		public var filesLoaded:Signal;
		private var _scene:Scene;
		private const SHARED_PATH:String = "scenes/shared/";
	}
}