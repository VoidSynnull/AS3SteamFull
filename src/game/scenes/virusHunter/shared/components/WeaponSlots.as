package game.scenes.virusHunter.shared.components
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	public class WeaponSlots extends Component
	{
		public var active:Entity;
		public var slots:Dictionary = new Dictionary();
		public var shut:Number = 0;
	}
}