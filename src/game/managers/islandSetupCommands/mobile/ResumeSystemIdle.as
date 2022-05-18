package game.managers.islandSetupCommands.mobile
{
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	
	import engine.command.CommandStep;
	
	public class ResumeSystemIdle extends CommandStep
	{
		public function ResumeSystemIdle()
		{
			super();
		}
		
		override public function execute():void
		{
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
			super.complete();
		}
	}
}