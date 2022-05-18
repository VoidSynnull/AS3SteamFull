package game.managers.islandSetupCommands
{
	import engine.ShellApi;
	import engine.command.CommandStep;
	
	public class FadeOutCurrentScene extends CommandStep
	{
		public function FadeOutCurrentScene( shellApi:ShellApi)
		{
			super();
			
			_shellApi = shellApi;
		}
		
		override public function execute():void
		{
			// if there is a currentScene, fade out & display loading
			if( _shellApi.sceneManager.currentScene != null )
			{
				_shellApi.sceneManager.fadeOutScene( false );
			}
			super.complete();
		}
		
		private var _shellApi:ShellApi;
	}
}