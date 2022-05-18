package game.data.scene.hit
{
	import game.data.scene.hit.HitDataComponent;

	public class LooperHitData extends HitDataComponent
	{
		public var motionRate:Number = 1;
		public var visualHeight:Number = NaN;
		public var visualWidth:Number = NaN;
		public var lastObject:Boolean = false;
		
			// TO TRIGGER A HIT BY AN EVENT
		public var event:String = null;
		public var active:Boolean = true;
	}
}



