package game.scenes.virusHunter.shared
{
	import flash.display.Sprite;

	public class BulletView extends Sprite
	{
		public function BulletView( color:uint = 0xffffff, radius:Number = 4 )
		{
			graphics.beginFill( color );
			graphics.drawCircle( 0, 0, radius );
			graphics.endFill();
		}
	}
}
