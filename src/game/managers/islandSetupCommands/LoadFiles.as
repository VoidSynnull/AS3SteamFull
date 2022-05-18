package game.managers.islandSetupCommands
{
	import engine.ShellApi;
	import engine.command.CommandStep;

	/**
	 * LoadFiles
	 * 
	 * Loads a list of files.
	 */
	
	public class LoadFiles extends CommandStep
	{
		public function LoadFiles(files:Array, shellApi:ShellApi)
		{
			super();
			
			_files = files;
			_shellApi = shellApi;
		}
		
		override public function execute():void
		{
			_shellApi.loadFiles(_files, super.complete);
		}
		
		private var _files:Array;
		private var _shellApi:ShellApi;
	}
}