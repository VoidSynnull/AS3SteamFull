package game.particles.emitter.specialAbility 
{
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.display.GradientType;
	import game.particles.emitter.specialAbility.FireBlob;
	
	public class FireBlob extends Shape
	{
		public static const DefaultColors : Array = [ 0xFFC814, 0xFF351E ];
		public static const DefaultAlphas : Array = [ 1, 0.1 ]; 
		public static const DefaultRatios : Array = [ 0, 255 ];
		
		public function FireBlob( a : Number = 5, b : Number = 10, colors : Array = null, alphas : Array = null, ratios : Array = null, bm:String = "normal")
		{
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox( a * 2, b * 2, 0, -a, -b );
			graphics.beginGradientFill( GradientType.RADIAL, 
				colors ? colors : DefaultColors, 
				alphas ? alphas : DefaultAlphas, 
				ratios ? ratios : DefaultRatios, 
				matrix );
			graphics.moveTo( a, 0 );
			graphics.curveTo( 0, b, -a, b );
			graphics.curveTo( -a/2, 0, -a, -b );
			graphics.curveTo( 0, -b, a, 0 );
			graphics.endFill();
			blendMode = bm;
		}
	}
}