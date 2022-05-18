package game.scenes.mocktropica.shared.components
{
	import ash.core.Component;
	
	import game.scenes.mocktropica.shared.AdvertisementGroup;
	
	public class CreateRandomAdComponent extends Component
	{
		public var lastX:Number;
		public var lastY:Number;
		
		public var timeSinceMovement:Number = 0;
		public var count:int = 0;
		public var max:int = 10;
		
		public var adSystem:AdvertisementGroup;
	}
}