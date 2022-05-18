package game.scenes.carrot.smelter.components 
{
	
	import flash.geom.ColorTransform;
	
	import ash.core.Component;
	
	public class Molten extends Component
	{	
		public var startX:Number;
		public var startY:Number;
		public var originColor:ColorTransform;
		public var redColor:ColorTransform;
		public var whiteColor:ColorTransform;
		
		public var state:String 				= FALLING;
		
		public const FALLING:String				= "falling";
		public const ON_CONVEYOR:String 		=  "on_conveyor";
	}
}