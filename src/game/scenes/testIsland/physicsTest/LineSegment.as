package game.scenes.testIsland.physicsTest
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.scenes.testIsland.physicsTest.Collider.Collider;
	import game.scenes.testIsland.physicsTest.Collider.Collision;
	import game.scenes.testIsland.physicsTest.PhysicsSystem.PhysicsSystem;
	import game.util.PointUtils;
	
	public class LineSegment
	{
		private var _start:Point;
		private var _end:Point;
		
		private var _length:Number;
		
		private var _radians:Number;
		
		private var _angle:Point;
		private var _normal:Point;
		
		public function LineSegment(start:Point, end:Point)
		{
			_start = start;
			_end = end;
			
			_length = Point.distance(start, end);
			
			_radians = PointUtils.getRadiansBetweenPoints(start, end);
			
			_angle = PointUtils.getUnitDirectionOfAngle(_radians);
			
			_normal = new Point(_angle.y, -_angle.x);
		}
		
		public function get start():Point{return _start;}
		
		public function get end():Point{return _end;}
		
		public function get length():Number{return _length;}
		
		public function get normal():Point{return _normal;}
		
		public function get angle():Point{return _angle;}
		
		public function get radians():Number{return _radians;}
		
		public function offsetBySpatial(spatial:Spatial, rotate:Boolean = true):LineSegment
		{
			var radians:Number = -spatial.rotation * Math.PI / 180;
			
			if(!rotate)
				radians = 0;
			
			var start:Point = new Point(_start.x * spatial.scaleX, _start.y * spatial.scaleY);
			var end:Point = new Point(_end.x * spatial.scaleX, _end.y * spatial.scaleY);
			var origin:Point = new Point(spatial.x, spatial.y);
			
			var pointAngle:Number = PointUtils.getRadiansOfTrajectory(start);
			var pointRadius:Number = start.length;
			var rotation:Point = PointUtils.getUnitDirectionOfAngle(pointAngle - radians);
			
			start = PointUtils.times(rotation, pointRadius);
			
			pointAngle = PointUtils.getRadiansOfTrajectory(end);
			pointRadius = end.length;
			rotation = PointUtils.getUnitDirectionOfAngle(pointAngle - radians);
			
			end = PointUtils.times(rotation, pointRadius);
			
			start = start.add(origin);
			end = end.add(origin);
			
			return new LineSegment(start, end);
		}
		
		public static function checkForCrossSection(line1:LineSegment, collider1:Collider, line2:LineSegment, collider2:Collider, physics:PhysicsSystem = null):Collision
		{
			/*// how I get to these equations
			
			y = m(x - Px) + Py
			
			y = m1(x - line1Start.x) + line1Start.y
			y = m2(x - line2Start.x) + line2Start.y
			
			set them = to one another
			m1(x - line1Start.x) + line1Start.y = m2(x - line2Start.x) + line2Start.y
			
			work to get x by itself
			m1x - m1* line1Startx + line1Start.y = m2x - m2 * line2Start.x + line2Start.y
			
			combine like terms
			m1x - m2x = -m2 * line2Start.x + m1 * line1Start.x + line2Start.y - line1Start.y
			
			isoloate x
			x(m1 - m2) = ""
			
			divide by (m1 - m2)
			x =  (-m2 * line2Start.x + m1 * line1Start.x + line2Start.y - line1Start.y) / (m1 - m2);
			
			plug in for x to solve for y
			y = m1(x - line1Start.x) + line1Start.y
			
			point = new Point(x,y);
			
			*/
			
			var m1:Number = NaN;
			var m2:Number = NaN;
			
			// rise over run
			
			if(line1.angle.x != 0 && Math.abs(line1.angle.y) != 1)
				m1 = line1.angle.y / line1.angle.x;
			
			if(line2.angle.x != 0 && Math.abs(line2.angle.y) != 1)
				m2 = line2.angle.y / line2.angle.x;
			
			var x:Number = 0;
			var y:Number = 0;
			
			if(m1 == m2)
				return null;
			
			if(isNaN(m1))
				x = line1.start.x;
			else if(isNaN(m2))
				x = line2.start.x;
			else
				x =  (-m2 * line2.start.x + m1 * line1.start.x + line2.start.y - line1.start.y) / (m1 - m2);
			
			if(!isNaN(m1))
				y =  m1 * (x - line1.start.x) + line1.start.y;
			else if(!isNaN(m2))
				y =  m2 * (x - line2.start.x) + line2.start.y;
			else
				return null;
			
			var point:Point = new Point(x, y);
			
			if(physics != null)
			{
				if(physics.showHits)
					physics.drawCircle(point ,5, 0xff0000);
			}
			
			// now to check to see if point is of a greater distance than the length of either line
			
			var distance:Number = Point.distance(point, line1.start);
			var length:Number = line1.length;
			if(distance > length)
				return null;
			
			distance = Point.distance(point, line1.end);
			if(distance > length)
				return null;
			
			distance = Point.distance(point, line2.start);
			length = line2.length;
			if(distance > length)
				return null;
			
			distance = Point.distance(point, line2.end);
			if(distance > length)
				return null;
			
			return new Collision(collider1, collider2, line1, line2.normal, point);
		}
	}
}