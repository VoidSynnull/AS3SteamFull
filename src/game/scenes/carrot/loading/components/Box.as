package game.scenes.carrot.loading.components 
{
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	
	public class Box extends Component
	{
		public var chute:uint;
		public var level:uint;
		public var currentLevel:int;
		public var start:Number;
		public var initVelocity:Number;
		public var display:Display;
		
		public var waitTime:Number;	// in seconds
		public var time:Number = 0;	// time passed
		
		public var target:Number;
	}
}