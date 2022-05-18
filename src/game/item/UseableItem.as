package game.item
{
	import flash.display.MovieClip;

	public class UseableItem extends Item
	{
		public function UseableItem()
		{
			super();
		}
		
		override public function init (mc:MovieClip): void {
			super.init(mc)
			// set up use signal, etc
			
		}
	}
}