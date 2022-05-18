package com.poptropica.shellSteps.shared
{
	import com.poptropica.AppConfig;
	
	import game.managers.LongTermMemoryManager;
	import game.managers.ProfileManager;

	/**
	 * Retrieve long term memory from LSO, restore stored profile data.
	 * Establishes reference to the LSO functioning as long term memory.
	 * Profile data is restored from this long term memory.
	 */
	public class LongTermMemoryRestore extends ShellStep
	{
		// creation of fileManager, injector, shellApi, & managers
		public function LongTermMemoryRestore()
		{
			super();
			stepDescription = "Restoring Long Term Memory";
		}
		
		override protected function build():void
		{	

			// create LongTermMemoryManager, establish location of LSO
			// NOTE :: create before ProfileManager
			var memoryManager:LongTermMemoryManager = shellApi.addManager(new LongTermMemoryManager()) as LongTermMemoryManager;
			
			// create ProfileManager
			// profile and global data restored from longterm memory on construct()
			this.shellApi.addManager(new ProfileManager());
			
			// FOR DEBUG
			// if resetData flag is true, it clears the profile, generally used for debug purposes
			if( AppConfig.resetData )
			{
				ProfileManager(this.shellApi.getManager(ProfileManager)).clear();
			}
			
			built();
		}
	}
}