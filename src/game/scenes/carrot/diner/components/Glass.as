package game.scenes.carrot.diner.components 
{
	import flash.geom.ColorTransform;
	
	import ash.core.Component;
	
	public class Glass extends Component
	{
		public var isFilling:Boolean = false;
		public var isFull:Boolean = false;
		public var wait:Number = 0;
		public var machine:uint;
		public var color:ColorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
		
		public function Glass()
		{
			
		}
	}
}