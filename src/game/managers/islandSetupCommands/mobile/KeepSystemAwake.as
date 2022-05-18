package game.managers.islandSetupCommands.mobile
{
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	
	import engine.command.CommandStep;
	
	public class KeepSystemAwake extends CommandStep
	{
		public function KeepSystemAwake()
		{
			super();
		}
		
		override public function execute():void
		{
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			super.complete();
		}
	}
}