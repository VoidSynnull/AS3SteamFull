package game.data.particles
{
	import flash.display.Sprite;

	public class FlameData
	{
		public var sprite:Sprite;
		public var isShrinking:Boolean;
		public var targetScale:Number;
		public var velocityY:Number;
		
		public function FlameData(sprite:Sprite)
		{
			this.sprite = sprite;
			this.reset();
		}
		
		public function reset():void
		{
			this.isShrinking 	= false;
			this.targetScale 	= Math.random() * 0.5 + 1.5;
			this.velocityY 		= 0;
		}
		
		public function destroy():void
		{
			//this.wrapper.destroy();
		}
	}
}