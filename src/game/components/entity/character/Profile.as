package game.components.entity.character
{
	import ash.core.Component;
	
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.profile.ProfileData;
	import game.managers.ProfileManager;

	public class Profile extends Component
	{
		public function Profile( profileManager:ProfileManager, profileData:ProfileData = null )
		{
			this.profileData = profileData;
			_profileManager = profileManager;
			_lookConverter = new LookConverter();
		}

		/**
		 * Save look to the profile
		 * @param	lookData
		 */
		public function saveLook( lookData:LookData ):void
		{
			profileData.look = _lookConverter.playerLookFromLookData(lookData);//.serialize();
			save();
		}
		
		/**
		 * Save profile
		 */
		public function save():void
		{
			_profileManager.save();
		}
		
		public var profileData:ProfileData;
		private var _profileManager:ProfileManager;
		private var _lookConverter:LookConverter;
	}
}
