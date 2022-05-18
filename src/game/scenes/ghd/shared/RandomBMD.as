package game.scenes.ghd.shared
{
	import flash.display.BitmapData;

	public class RandomBMD
	{
		/**
		 * Returns a random number where 0 <= n < 1 using the color of the BitmapData's pixel at
		 * (x, y) divided by 0xFFFFFF. This is used mainly with BitmapData set with noise() or
		 * perlinNoise() to produce pseudo-random/seeded values from pixels.
		 * 
		 * <p>Random numbers from BitmapData have the potential to produce 0 <= n <= 1.
		 * In an attempt to mimic Math.random()'s 0 <= n < 1, we're shifting 1 to 0.99999999.</p>
		 */
		public static function random(data:BitmapData, x:uint, y:uint):Number
		{
			var random:Number = data.getPixel(x, y) / 0xFFFFFF;
			if(random == 1) random = 0.99999999;
			return random;
		}
		
		public static function integer(data:BitmapData, x:uint, y:uint, min:int, max:int):int
		{
			return min + Math.floor(RandomBMD.random(data, x, y) * (max + 1 - min));
		}
		
		public static function number(data:BitmapData, x:uint, y:uint, min:Number, max:Number):Number
		{
			return min + RandomBMD.random(data, x, y) * (max - min);
		}
		
		public static function boolean(data:BitmapData, x:uint, y:uint, chance:Number = 0.5):Boolean
		{
			return RandomBMD.random(data, x, y) < chance;
		}
		
		public static function sign(data:BitmapData, x:uint, y:uint, chance:Number = 0.5):int
		{
			return RandomBMD.random(data, x, y) < chance ? 1 : -1;
		}
		
		public static function bit(data:BitmapData, x:uint, y:uint, chance:Number = 0.5):int
		{
			return RandomBMD.random(data, x, y) < chance ? 1 : 0;
		}
	}
}