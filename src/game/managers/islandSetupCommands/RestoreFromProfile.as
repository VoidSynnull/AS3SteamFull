package game.managers.islandSetupCommands
{
	import engine.ShellApi;
	import engine.command.CommandStep;

	import game.data.profile.ProfileData;
	import game.managers.PhotoManager;
	/**
	 * RestoreFromProfile
	 *
	 * Pulls the events, items and photos from the saved profile (if they exist.) and restores them to the appropriate manager.
	 * @author Billy Belfied
	 */

	public class RestoreFromProfile extends CommandStep
	{
		public function RestoreFromProfile(profileData:ProfileData, island:String, shellApi:ShellApi, newIsland:Boolean = true)
		{
			super();

			_profileData = profileData;
			_island = island;
			_shellApi = shellApi;
			_newIsland = newIsland;
		}

		override public function execute():void
		{
			if(_newIsland)
			{
				if(_profileData.events[_island] != null)
				{
					trace( "RestoreFromProfile :: restoring events");
					_shellApi.gameEventManager.restore(_profileData.events, _island);
				}

				if (_profileData.items[_island] != null)
				{
					trace( "RestoreFromProfile :: restoring items");
					_shellApi.itemManager.restoreSets(_profileData.items, _island);
				}

				if (_profileData.photos[_island] != null)
				{
					trace( "RestoreFromProfile :: restoring photos");
					var photoManager:PhotoManager = _shellApi.getManager(PhotoManager) as PhotoManager;
					if( photoManager )
					{
						photoManager.restore(_profileData.photos, _island);
					}
				}
			}

			super.complete();
		}

		private var _profileData:ProfileData;
		private var _island:String;
		private var _shellApi:ShellApi;
		private var _newIsland:Boolean;
	}
}
