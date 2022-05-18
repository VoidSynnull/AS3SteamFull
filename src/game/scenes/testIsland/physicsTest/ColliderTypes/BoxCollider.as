package game.scenes.testIsland.physicsTest.ColliderTypes
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class BoxCollider extends LineCollider
	{		
		public function BoxCollider(bounds:Rectangle, inverse:Boolean = false)
		{
			var shape:Vector.<Point> = new Vector.<Point>();
			
			if(inverse)
				shape.push(bounds.topLeft, new Point(bounds.left, bounds.bottom), bounds.bottomRight, new Point(bounds.right, bounds.top), bounds.topLeft);
			else
				shape.push(bounds.topLeft, new Point(bounds.right, bounds.top), bounds.bottomRight, new Point(bounds.left, bounds.bottom), bounds.topLeft);
			super(shape);
		}
	}
}