package game.scenes.poptropolis.promoDive.particles
{
    import flash.display.Shape;

    public class DiveSand extends Shape
    {
        private var _ellipseWidth:Number;
        private var _ellipseHeight:Number;
        private var _color:uint;

        public function DiveSand(  )
        {
           draw();
        }

        private function draw():void
        {
			graphics.beginFill(35005,1);
			graphics.moveTo(0,3);
			graphics.cubicCurveTo(1,3,2,3,4,2);
			graphics.cubicCurveTo(5,1,6,0,6,-1);
			graphics.cubicCurveTo(6,0,6,0,6,0);
			graphics.cubicCurveTo(6,1,5,3,4,4);
			graphics.cubicCurveTo(3,5,1,6,0,6);
			graphics.cubicCurveTo(-1,6,-3,5,-4,4);
			graphics.cubicCurveTo(-5,3,-6,1,-6,0);
			graphics.cubicCurveTo(-6,0,-6,0,-6,-1);
			graphics.cubicCurveTo(-6,0,-5,1,-4,2);
			graphics.cubicCurveTo(-2,3,-1,3,0,3);
			graphics.endFill();
			
			graphics.beginFill(11791103,1);
			graphics.moveTo(4,-4);
			graphics.cubicCurveTo(5,-3,6,-1,6,0);
			graphics.cubicCurveTo(6,1,5,3,4,4);
			graphics.cubicCurveTo(3,5,1,6,0,6);
			graphics.cubicCurveTo(-1,6,-3,5,-4,4);
			graphics.cubicCurveTo(-5,3,-6,1,-6,0);
			graphics.cubicCurveTo(-6,-1,-5,-3,-4,-4);
			graphics.cubicCurveTo(-3,-5,-1,-6,0,-6);
			graphics.cubicCurveTo(1,-6,3,-5,4,-4);
			graphics.endFill();
			
			graphics.beginFill(11791103,1);
			graphics.moveTo(2,-3);
			graphics.cubicCurveTo(2,-3,2,-3,1,-2);
			graphics.lineTo(0,-2);
			graphics.lineTo(-1,-2);
			graphics.cubicCurveTo(-2,-3,-2,-3,-2,-3);
			graphics.cubicCurveTo(-2,-4,-2,-4,-1,-4);
			graphics.cubicCurveTo(-1,-5,0,-5,0,-5);
			graphics.cubicCurveTo(0,-5,1,-5,1,-4);
			graphics.cubicCurveTo(2,-4,2,-4,2,-3);
			graphics.endFill();
        }
    }
}