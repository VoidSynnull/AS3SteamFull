package game.scenes.poptropolis.weightLift.particles
{
	import flash.display.Shape;

	public class Star extends Shape 
	{
		
		public function Star()
		{
			draw();
		}
		
		private function draw():void
		{
			//drawscript illustrator plugin
			graphics.beginFill(16442376,1);
			graphics.lineStyle(2,15229733);
			graphics.moveTo(28,-6);
			graphics.lineTo(15,6);
			graphics.lineTo(18,24);
			graphics.lineTo(2,16);
			graphics.lineTo(-14,24);
			graphics.lineTo(-10,6);
			graphics.lineTo(-24,-6);
			graphics.lineTo(-6,-8);
			graphics.lineTo(2,-25);
			graphics.lineTo(10,-8);
			graphics.lineTo(28,-6);
			graphics.endFill();
		}
	}
}
