package com.poptropica.shellSteps.shared
{
	import game.managers.ProfileManager;
	import game.util.DataUtils;

	/**
	 * Build Step that establishes the active profile to begin the game with.
	 * All profiles are restored from memory when ProfileManager is created, so that happens prior to this step.
	 * This step focuses on determining which of those profile's is active and if any additional updating is necessary.
	 * The active user is determined by a login id, if no id is found a default is used and a new active profile created.  
	 */
	public class SetActiveProfile extends ShellStep
	{
		public function SetActiveProfile()
		{
			super();
			stepDescription = "Setting up player profile";
		}
		
		override protected function build():void
		{
			// TODO :: If this actually necessary outside of Browser?
			determineActiveProfile();
			built();
		}
		
		protected function determineActiveProfile( login:String = "", clearProfile:Boolean = false ):void
		{
			var profileManager:ProfileManager = ProfileManager(this.shellApi.getManager(ProfileManager));
			if( !DataUtils.validString(login) )
			{
				login = profileManager.defaultProfileId;
			}
			
			if ( clearProfile || !profileManager.checkForProfile(login)) 
			{
				profileManager.clear(login);
				trace("SetActiveProfile Step : no profile for given login, creating new one.");
			} 
			else 
			{
				trace("SetActiveProfile Step : profile found for " + login);
			}
			
			profileManager.activeLogin = login;
		}
	}
}