package game.scenes.ghd.shared
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import game.util.GeomUtils;

	public class PlanetGenerator
	{
		public var landColors:Array = [0xFF8AAB50, 0xFF97C8D2, 0xFFDEB06B, 0xFFE15011, 0xFFAC82D2, 0xFF846937, 0xFFC7CEC1, 0xFF589522, 0xFFBEB489, 0xFF717055, 0xFF58667A];
		public var waterColors:Array = [0xFF2F6580, 0xFF7BB9C6, 0xFFD67D43, 0xFF4D2215, 0xFF7558C0, 0xFF65492E, 0xFF9EA899, 0xFFB5D044, 0xFF3DA9D1, 0xFF9A9274, 0xFF8C8EA2];
		
		public function PlanetGenerator()
		{
			
		}
		
		//Seeds consist of GalaxySeed + "0" + Star.x + "0" + Star.y + "0" + Planet.x + "0" + Planet.y
		public function create(seed:uint):Sprite
		{
			var data:BitmapData = new BitmapData(1, 10, false, 0);
			data.noise(seed, 0, 255, 7, true);
			
			var sprite:Sprite = new Sprite();
			
			var radius:int = RandomBMD.integer(data, 0, 0, 25, 75);
			
			var variation1:Number = RandomBMD.random(data, 0, 0);
			var variation2:Number = RandomBMD.random(data, 0, 1);
			var textureSeed:uint = data.getPixel(0, 2);
			
			var colorIndex:int = RandomBMD.integer(data, 0, 3, 0, waterColors.length - 1);
			var landColor:uint = landColors[colorIndex];
			var waterColor:uint = waterColors[colorIndex];
			
			var baseSize:uint = Math.round(60 * (variation1 + 0.2));
			var baseSizeOffset:uint = Math.round(baseSize * (2 * variation2 + 1));
			var colorChannels:uint = 8 + Math.ceil(7 * variation1); //we want this to be 9-15 (alpha channel plus all color combinations)
			
			var surface:BitmapData = new BitmapData(radius * 2, radius * 2, true, waterColor);
			
			var land:BitmapData = new BitmapData(radius * 2, radius * 2, false, 0xFF000000);
			land.perlinNoise(baseSize, baseSize, 4, textureSeed, false, true, 0, true);
			surface.threshold(land, land.rect, new Point(0, 0), ">", 0xFF777777, landColor);
			surface.applyFilter(surface, surface.rect, new Point(0, 0), new BlurFilter(1.5, 1.5, 3));
			
			var atmosphere1:BitmapData = new BitmapData(radius * 2, radius * 2, true, 0xFFFFFF);
			atmosphere1.perlinNoise(baseSizeOffset, baseSize, 1, textureSeed + 1, false, true, colorChannels, true);
			
			var atmosphere2:BitmapData = new BitmapData(radius * 2, radius * 2, false, 0xFFFFFF);
			atmosphere2.perlinNoise(baseSizeOffset*0.5, baseSize*0.5, 1, textureSeed + 2, false, false, colorChannels, true);
			atmosphere1.draw(atmosphere2, null, null, BlendMode.DIFFERENCE);
			
			surface.draw(atmosphere1, null, null, BlendMode.OVERLAY);
			
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0x000000, 0.2);
			shape.graphics.drawCircle(0, 0, radius);
			shape.graphics.drawCircle(radius/4, -radius/4, radius);
			shape.graphics.endFill();
			
			surface.draw(shape, new Matrix(1, 0, 0, 1, radius, radius), null, BlendMode.NORMAL, null, true);
			
			land.dispose();
			atmosphere1.dispose();
			atmosphere2.dispose();
			data.dispose();
			
			for(var py:int = surface.width - 1; py > -1; --py)
			{
				for(var px:int = surface.height - 1; px > -1; --px)
				{
					if(GeomUtils.distSquared(px, py, radius, radius) > radius * radius)
					{
						surface.setPixel32(px, py, 0);
					}
				}
			}
			
			var bitmap:Bitmap = new Bitmap(surface);
			bitmap.x = -bitmap.width / 2;
			bitmap.y = -bitmap.height / 2;
			sprite.addChild(bitmap);
			
			shape.graphics.clear();
			shape.graphics.beginFill(0, 0);
			shape.graphics.lineStyle(3, 0, 1);
			shape.graphics.drawCircle(0, 0, radius);
			shape.graphics.endFill();
			sprite.addChild(shape);
			
			return sprite;
		}
	}
}