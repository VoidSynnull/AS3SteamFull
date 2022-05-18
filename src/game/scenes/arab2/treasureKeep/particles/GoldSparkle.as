package game.scenes.arab2.treasureKeep.particles
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	
	public class GoldSparkle extends Sprite
	{
		public function GoldSparkle(bitmapData:BitmapData=null)
		{
			super();
			
			/**
			 * Have to do it this way as Flint doesn't have an easy documented way to change the bitmap's position within the particle clip.
			 * If anyone finds one -- please let me know
			 * Bart Henderson
			 */
			
			var bitmap:Bitmap = new Bitmap(bitmapData);
			bitmap.x = -bitmap.width / 2;
			bitmap.y = -bitmap.height / 2;
			
			this.addChild(bitmap);
		}
	}
}