package game.managers.islandSetupCommands.mobile
{
	import engine.ShellApi;
	import engine.command.CommandStep;

	public class TrackFirstTimeStart  extends CommandStep
	{
		public function TrackFirstTimeStart(shellApi:ShellApi)
		{
			super();
			
			_shellApi = shellApi;
		}
		
		override public function execute():void
		{
			// track the event for the very first scene load for this user.
			if(_shellApi.completeEvent(FIRST_TIME_START))
			{
				_shellApi.track(FIRST_TIME_START);
			}
			
			super.complete();
		}
		
		private var _shellApi:ShellApi;
		private static const FIRST_TIME_START:String = "firstTimeStart";
	}
}