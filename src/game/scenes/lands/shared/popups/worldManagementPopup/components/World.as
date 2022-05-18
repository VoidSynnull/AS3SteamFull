package game.scenes.lands.shared.popups.worldManagementPopup.components
{
	import ash.core.Component;
	
	import game.scenes.lands.shared.world.LandRealmData;
	
	public class World extends Component
	{
		public var wait:Number;

		public var targetScale:Number;
		public var vx:Number;
		public var vy:Number;
		public var rolledOver:Boolean;

		public var realmData:LandRealmData;

		public function World( data:LandRealmData )
		{
			this.realmData = data;
		}
	}
}