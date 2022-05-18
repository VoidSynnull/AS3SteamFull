package game.scenes.myth.labyrinth.components
{
	import flash.display.DisplayObject;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;

	public class ScorpionComponent extends Component
	{
		public function ScorpionComponent( scorpion:Entity )
		{
			spatial = scorpion.get( Spatial );

			var number:int;
			for( number = 1; number < 9; number ++ )
			{
				leg[ number - 1 ] = scorpion.get( Display ).displayObject.getChildByName( "leg" + number )
			}
			startX = spatial.x;	
		}
		
		public var timer:int = 0;
		public var isHit:Boolean = false;
		
		public var accel:Number = 0;
		public var startX:Number;
		public var spatial:Spatial;
		public var leg:Vector.<DisplayObject> = new Vector.<DisplayObject>;
	}
}