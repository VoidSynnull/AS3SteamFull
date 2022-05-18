package game.managers.islandSetupCommands
{
	import engine.ShellApi;
	import engine.command.CommandStep;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.data.PlayerLocation;
	import game.managers.ProfileManager;
	import game.util.ClassUtils;
	import game.util.ProxyUtils;

	/**
	 * SaveSceneToProfile
	 * 
	 * Saves the currently loaded scene to the active profile.
	 * @author Billy Belfied
	 */
	public class StoreCurrentScene extends CommandStep
	{
		public function StoreCurrentScene(shellApi:ShellApi)
		{
			super();
			
			_shellApi = shellApi;
		}
		
		override public function execute():void
		{
			var scene:Scene = _shellApi.sceneManager.currentScene;
			
			var canSaveIslandLocation:Boolean = true;
			if(_shellApi.islandEvents)
			{
				canSaveIslandLocation = _shellApi.islandEvents.canSaveIslandLocation;
			}
			if(canSaveIslandLocation && scene.sceneData != null && scene.sceneData.saveLocation)
			{
				var island:String = ProxyUtils.getIslandFromScene(scene);
				var profileManager:ProfileManager = _shellApi.profileManager;
				
				var x:Number = NaN;
				var y:Number = NaN;
				var direction:String = "R";
				if(_shellApi.player)
				{
					var spatial:Spatial = _shellApi.player.get(Spatial);
					if(spatial)
					{
						x = spatial.x;
						y = spatial.y;
						direction = spatial.scaleX > 0 ? "L" : "R";
					}
				}
				
				trace("Not only are you on", island, "at", ClassUtils.getNameByObject(scene), "you are at", x + ',' +  y, direction);
				profileManager.active.lastScene[island] = PlayerLocation.instanceFromInitializer(
					{type:PlayerLocation.AS3_TYPE, island:island, scene:ClassUtils.getNameByObject(scene), locX:x, locY:y, direction:direction}
				);
				_shellApi.profileManager.save();	
			}
			
			super.complete();
		}

		private var _shellApi:ShellApi;
	}
}