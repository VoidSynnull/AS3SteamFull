package game.item
{
	import flash.display.MovieClip;
	import flash.display.Sprite;

	public class Item extends Sprite
	{
		public function Item()
		{
		}
		
		public function init (mc:MovieClip): void {
			addChild (mc)
		}
	}
}