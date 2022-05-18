package game.managers.islandSetupCommands
{
	import engine.ShellApi;
	import engine.command.CommandStep;
	import engine.group.Scene;
	
	import game.util.ClassUtils;

	/**
	 * LoadScene
	 * 
	 * Loads a scene and completes when scene is loaded.
	 */
	public class LoadScene extends CommandStep
	{
		public function LoadScene(nextScene:*, x:Number, y:Number, direction:String, shellApi:ShellApi, fadeInTime:Number = NaN, fadeOutTime:Number = NaN)
		{
			super();
			
			_nextScene = nextScene;
			_nextSceneX = x;
			_nextSceneY = y;
			_nextSceneDirection = direction;
			_shellApi = shellApi;
			_fadeInTime = fadeInTime;
			_fadeOutTime = fadeOutTime;
		}
		
		override public function execute():void
		{
			_shellApi.sceneManager.sceneLoaded.addOnce(handleSceneLoaded);
			_shellApi.sceneManager.loadScene(_nextScene, _nextSceneX, _nextSceneY, _nextSceneDirection, _fadeInTime, _fadeOutTime);
		}
		
		private function handleSceneLoaded(scene:Scene):void
		{
			// make sure the scene that loaded is the scene you were trying to load
			var nextSceneName:String = (_nextScene is String) ? _nextScene : ClassUtils.getNameByObject(_nextScene);
			if( nextSceneName == ClassUtils.getNameByObject(scene) )
			{
				super.complete();
			}
			else
			{
				trace(this," :: WARNING :: handleSceneLoaded : returned scene is not same as nextScene, halting process");
				super.completeAll();
			}
		}
		
		private var _shellApi:ShellApi;
		private var _nextScene:*;
		private var _nextSceneX:Number;
		private var _nextSceneY:Number;
		private var _nextSceneDirection:String;
		private var _fadeInTime:Number;
		private var _fadeOutTime:Number;
	}
}