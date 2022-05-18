package game.test
{
	import flash.system.System;
	import flash.utils.setTimeout;
	
	import engine.ShellApi;
	import engine.group.Scene;
	
	import game.data.island.IslandEvents;
	import game.manifest.DynamicallyLoadedClassManifest;
	import game.util.ClassUtils;
	import game.util.ProxyUtils;
	import game.util.Utils;

	public class LoadScenesTest
	{
		public function LoadScenesTest(shellApi:ShellApi)
		{
			_shellApi = shellApi;
		}
		
		public function start(islandEventsList:Array = null, finalScene:Class = null):void
		{
			_gcCycle = new GarbageCollectionCycle();
			
			if(islandEventsList == null)
			{
				var dlcm:DynamicallyLoadedClassManifest = new DynamicallyLoadedClassManifest();
				islandEventsList = dlcm.init();
			}
			
			var islandEvents:IslandEvents;
			_sceneList = new Array();
			
			for(var n:int = 0; n < islandEventsList.length; n++)
			{
				islandEvents = new islandEventsList[n]();
				
				if(islandEvents.scenes != null)
				{
					for(var m:int = 0; m < islandEvents.scenes.length; m++)
					{
						_sceneList.push(islandEvents.scenes[m]);
					}
				}
			}
			
			if(finalScene)
			{
				_sceneList.push(finalScene);
			}
			
			_sceneIndex = 0;
			
			loadNextScene();
		}
		
		private function loadNextScene():void
		{
			if(_sceneIndex < _sceneList.length)
			{
				var nextScene:* = new _sceneList[_sceneIndex]();
				
				if(nextScene is Scene)
				{
					Scene(nextScene).ready.addOnce(sceneLoaded);
					
					var logOutput:String = "Loading scene : " + (_sceneIndex + 1) + "/" + _sceneList.length + " : " + ProxyUtils.getIslandAndScene(ClassUtils.getNameByObject(nextScene))
					var clearOutput:Boolean = true;
						
					if(this.reportMemory)
					{
						var lastMemory:Number = _shellApi.longTermMemoryManager.getDevProperty("privateMemory");
						var privateMemory:Number = flash.system.System.privateMemory;
						
						if(!isNaN(lastMemory))
						{
							privateMemory -= lastMemory;
							logOutput += " Current Memory Delta : " + game.util.Utils.convertToMegabyte(privateMemory);
						}
						else
						{
							logOutput += " Current Memory Usage : " + game.util.Utils.convertToMegabyte(privateMemory);
						}
						
						clearOutput = false;
					}
					
					_shellApi.log(logOutput, null, clearOutput);
					
					_shellApi.loadScene(nextScene);
					
					_sceneIndex++;
				}
				else
				{
					sceneLoaded(new Scene());
					_sceneIndex++;
				}
			}
			/*
			else
			{
				_shellApi.loadScene(BareBones);
			}
			*/
		}
		
		private function clearScene():void
		{
			_shellApi.removeScene();
			_gcCycle.start();
			flash.utils.setTimeout(loadNextScene, 1000);
		}

		private function sceneLoaded(scene:Scene):void
		{
			if(this.reportMemory && _sceneIndex < _sceneList.length)
			{
				flash.utils.setTimeout(clearScene, WAIT_TIME);  // so we ignore pausing caused by popups
			}
			else
			{
				flash.utils.setTimeout(loadNextScene, WAIT_TIME);
			}
		}
		
		private var _sceneList:Array;
		private var _sceneIndex:int = 0;
		private var _shellApi:ShellApi;
		private var _gcCycle:GarbageCollectionCycle;
		public var reportMemory:Boolean = false;
		private const WAIT_TIME:int = 500;
	}
}