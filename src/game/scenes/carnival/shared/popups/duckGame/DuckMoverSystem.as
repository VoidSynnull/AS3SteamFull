package game.scenes.carnival.shared.popups.duckGame
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.motion.FollowTarget;
	
	import org.osflash.signals.Signal;
	
	public class DuckMoverSystem extends System
	{
		private var nodes:NodeList
		
		public static const CENTER_X: int = 488;
		public static const CENTER_Y: int = 330;
		public static const POND_RADIUS:Number = 220;
		public static const DUCK_RADIUS:Number = 60
		private static const DUCK_HOOK_COLLIDE_DISTANCE:Number = 40
		
		private var _poleHookConnector:Entity
		private var _centerPt:Point;
		private var _dummyCollideEntity:Entity // convenience for colliding against sides of pool
		
		public var duckCaught:Signal;
		
		public function DuckMoverSystem()
		{
			_centerPt = new Point (CENTER_X,CENTER_Y);
			
			_dummyCollideEntity = new Entity()
			_dummyCollideEntity.add (new Spatial())
			_dummyCollideEntity.add (new DuckMover())
			
			duckCaught = new Signal()
			
		}
		
		override public function update( time : Number ) : void
		{
			var sp:Spatial
			var dir:DuckMover
			var e:Entity
			
			var closestDuckDistance:Number = DUCK_RADIUS * .6
			var duckOnLine:Entity
			var wc:PoleHookConnection = _poleHookConnector.get (PoleHookConnection)
				
			for(var node:DuckMoverNode = nodes.head; node; node = node.next)
			{
				e =  node.entity
				//trace ("update:" + mc.pole0);
				dir = node.duckMover
				sp = Spatial (node.entity.get(Spatial))
				sp.x += dir.dx
				sp.y += dir.dy
				checkCollisions (node) 
				if (wc.isHookDown() && !wc.duckOnLine && e.get(DuckMover) != null) { 
					var d:Number = checkDistanceToHook(e)
					if (d < closestDuckDistance) {
						trace ("[DuckMoverSystem] caught duck!")
						closestDuckDistance = d
						duckOnLine = e
					}
				} else {
					//trace ("@@@@@@" +  wc.isHookDown() +"," +  !wc.duckOnLine + "," + e.get(DuckMover) )
				}
			}
			if (duckOnLine) {
				wc.duckOnLine  = duckOnLine
				var follow:FollowTarget = new FollowTarget(wc.entity2.get (Spatial));
				follow.offset = new Point (0, 50)
				duckOnLine.add(follow);
				duckOnLine.remove(DuckMover)
				duckCaught.dispatch(duckOnLine)
				var mc:MovieClip = MovieClip (Display(e.get(Display)).displayObject)
				mc.parent.addChild (mc)
			}
		}
		
		private function checkDistanceToHook (e:Entity):Number {
			// Check against hook
			var sp1:Spatial = e.get(Spatial)
			var pt1:Point = new Point (sp1.x,sp1.y)
			var sp2:Spatial
			var pt2:Point
			var d:Number
			
			var wc:PoleHookConnection = _poleHookConnector.get (PoleHookConnection)
			var closestDuckDistance:Number = DUCK_HOOK_COLLIDE_DISTANCE
			var duckOnHook:Entity
			
			var hook:Entity = wc.entity2
			sp2 = hook.get (Spatial)
			pt2 = new Point (sp2.x, sp2.y+40)// doesn't account for rotation though :(
			d = Point.distance(pt1,pt2)
			return d
			
		}
		
		private function checkCollisions(n:DuckMoverNode):void
		{
			var e:Entity = n.entity
			var sp1:Spatial = n.entity.get(Spatial)
			var pt1:Point = new Point (sp1.x,sp1.y)
			var sp2:Spatial
			var pt2:Point
			var c1:DuckMover = n.entity.get(DuckMover);
			var c2:DuckMover
			var newRot:Number
			var t:Tween
			var newDirRot:Number
			
			var collided:Boolean
			
			// First check wall of pond
			var d:Number = Point.distance(pt1,_centerPt)
			if (d > POND_RADIUS) 
			{
				sp2 = _dummyCollideEntity.get(Spatial)
				pt2 = new Point (pt1.x - CENTER_X, pt1.y - CENTER_Y)
				pt2.normalize(d*1.1)
				pt2.x += CENTER_X
				pt2.y += CENTER_Y
				sp2.x = pt2.x
				sp2.y = pt2.y
				c2 = _dummyCollideEntity.get(DuckMover)
				c2.dx = -c1.dx
				c2.dy = -c1.dy
				collide (e,_dummyCollideEntity)
				
				collided = true
				
				// Update once so it doesn't get stuck on wall
				sp1.x += c1.dx;
				sp1.y += c1.dy;		
				
				// Rotate a lil, but not fully to new direction
				newDirRot = Math.atan2(c1.dy,c1.dx) / Math.PI * 180; 
				newRot = sp1.rotation + (newDirRot - sp1.rotation) * .2
				t = e.get(Tween);
				t.to (sp1, 1, {rotation:newRot})
			}
			
			// Check against other ducks
			if (!collided) {
				for(var node:DuckMoverNode = nodes.head; node; node = node.next)
				{
					if (node != n) {
						sp2 = node.entity.get(Spatial)
						pt2 = new Point (sp2.x, sp2.y)
						if (Point.distance(pt1,pt2) < DUCK_RADIUS) {
							collided = true;
							collide (node.entity, n.entity)
						}
					}
				}
				// Tween rotation fully to new direction
				if (collided) {
					newDirRot = Math.atan2(c1.dy,c1.dx) / Math.PI * 180 
					newRot = sp1.rotation + (newDirRot - sp1.rotation) * .5
					t = e.get(Tween);
					t.to (sp1, 1, {rotation:newRot})
				}
			}
		}
		
		private function collide (e1:Entity, e2:Entity):void{
			//trace ("collide:" + e1 + "," + e2)
			var sp1:Spatial = e1.get(Spatial)
			var sp2:Spatial = e2.get(Spatial)
			
			var c1:DuckMover = e1.get(DuckMover)
			var c2:DuckMover = e2.get(DuckMover)
			
			var dx:Number = sp1.x - sp2.x;
			var dy:Number = sp1.y - sp2.y;
			
			// calculate the angle of the collision in radians
			var collisionAngle:Number = Math.atan2(dy, dx);
			
			// calculate the velocity vector for each ball
			// using existing ball X & Y velocities
			var speed1:Number = Math.sqrt(c1.dx * c1.dx + c1.dy * c1.dy)
			var speed2:Number = Math.sqrt(c2.dx * c2.dx + c2.dy * c2.dy)
			
			// calculate the angle in radians for each ball using it's current velocities
			// Calculate the angle formed by vector velocity of each ball, knowing your direction.
			var direction1:Number = Math.atan2(c1.dy, c1.dx);
			var direction2:Number = Math.atan2(c2.dy, c2.dx);
			
			// rotate the vectors counterclockwise so we can
			// calculate the conservation of momentum next
			var dx1:Number = speed1 * Math.cos(direction1 - collisionAngle);
			var dy1:Number = speed1 * Math.sin(direction1 - collisionAngle);			
			var dx2:Number = speed2 * Math.cos(direction2 - collisionAngle);
			var dy2:Number = speed2 * Math.sin(direction2 - collisionAngle);
			
			// take the mass of each ball and update their velocities based
			// on the law of conservation of momentum
			var mass:Number = 1
			var finaldx1:Number = ((mass - mass) * dx1 + (mass + mass) * dx2) / (mass + mass);
			var finaldx2:Number = ((mass + mass) * dx1 + (mass - mass) * dx2) / (mass + mass);
			
			// Y velocities stay constant
			// because this is an 1D environment collision
			var finaldy1:Number = dy1;
			var finaldy2:Number = dy2;
			
			// after we have our final velocities, we rotate the angles back
			// so that the collision angle is preserved
			c1.dx = Math.cos(collisionAngle) * finaldx1 + Math.cos(collisionAngle + Math.PI / 2) * finaldy1;
			c1.dy = Math.sin(collisionAngle) * finaldx1 + Math.sin(collisionAngle + Math.PI / 2) * finaldy1;
			c2.dx = Math.cos(collisionAngle) * finaldx2 + Math.cos(collisionAngle + Math.PI / 2) * finaldy2;
			c2.dy = Math.sin(collisionAngle) * finaldx2 + Math.sin(collisionAngle + Math.PI / 2) * finaldy2;
			
			// add velocity to ball positions
			sp1.x += c1.dx;
			sp1.y += c1.dy;			
			sp2.x += c2.dx;
			sp2.y += c2.dy;
		}
		
		override public function addToEngine(system:Engine):void
		{
			this.nodes = system.getNodeList(DuckMoverNode);
		}
		
		override public function removeFromEngine(system:Engine):void
		{
			system.releaseNodeList(DuckMoverNode);
			this.nodes = null;
		}
		
		public function set poleHookConnector(value:Entity):void
		{
			_poleHookConnector = value;
		}
	}
}


