package game.scenes.shrink.kitchenShrunk01.Particles
{
	import flash.display.Shape;
	
	public class Air extends Shape
	{
		public function Air(width:Number = 20, height:Number = 10, thickness:Number = 5)
		{
			graphics.beginFill(0xFFFFFF);
			graphics.moveTo(-height / 2, -width / 2);
			graphics.lineTo(height / 2 + thickness / 2, 0);
			graphics.lineTo(-height / 2, width / 2);
			graphics.lineTo(height / 2 - thickness / 2, 0);
			graphics.lineTo(-height / 2, -width / 2);
			graphics.endFill();
		}
	}
}