package game.systems.scene.browser
{
	import game.data.scene.DoorData;
	import game.proxy.browser.AdProxyUtils;
	import game.scenes.hub.town.Town;
	import game.systems.scene.DoorSystemPop;
	import game.util.ClassUtils;

	public class DoorSystemBrowser extends DoorSystemPop
	{
		public function DoorSystemBrowser()
		{
			super();
		}
		
		// BROWSER SPECIFIC
		override protected function loadNextScene( data:DoorData ):void
		{
			var destinationScene:String = data.destinationScene;
			var destinationSceneX:Number = data.destinationSceneX;
			var destinationSceneY:Number = data.destinationSceneY;
			var destinationSceneDirection:String = data.destinationSceneDirection;
			
			// if previous scene or returning from ad interior with destination of "return"
			if ((destinationScene.indexOf(PREVIOUS_SCENE) > -1) || (AdProxyUtils.checkReturnScene(_shellApi, destinationScene)))
			{
				destinationScene = _shellApi.sceneManager.previousScene;
				destinationSceneX = _shellApi.sceneManager.previousSceneX;
				destinationSceneY = _shellApi.sceneManager.previousSceneY;
				destinationSceneDirection = _shellApi.sceneManager.previousSceneDirection;
			}
			
			// if destination has "." (AS2 code removed)
			if (destinationScene.indexOf(".") != -1)
			{
				_shellApi.loadScene(ClassUtils.getClassByName(destinationScene), destinationSceneX, destinationSceneY, destinationSceneDirection);
			}
			// if trying to load AS2, then load town as default
			else
			{
				_shellApi.loadScene(Town);
			}
		}
	}
}