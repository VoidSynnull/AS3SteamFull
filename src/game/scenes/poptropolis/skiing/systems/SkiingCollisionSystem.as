package game.scenes.poptropolis.skiing.systems
{
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.common.StateString;
	import game.scenes.poptropolis.skiing.GatePartner;
	import game.scenes.poptropolis.skiing.Skiing;
	import game.scenes.poptropolis.skiing.components.ObstacleType;
	
	import org.osflash.signals.Signal;
	
	public class SkiingCollisionSystem extends System
	{
		private var _player:Entity
		private var _entities:Vector.<Entity>
		private var _finishLine:Entity
		public var collision:Signal;
		private var _cData:Object = {}
		private var _debugRects:Array;
		private var prevPlayerSp:Point;
		
		public function SkiingCollisionSystem()
		{
			collision = new Signal()
			prevPlayerSp = new Point(0,0)
		}
		
		public function init ( __player:Entity, __entities:Vector.<Entity>):void{
			_player = __player
			_entities = __entities
			setupRace()
			
			if ( Skiing.DEBUG_SHOW_COLLISION_RECTS) {
				_debugRects = []
				var cl:Array = [0xFF0000,0x00FF00, 0x0000FF, 0x000000, 0xFFFFFF]
				for  (var i:int =0; i < 5 ; i++) {
					var container:Sprite = new Sprite();
					container.graphics.beginFill(cl[i], 1);
					container.graphics.lineStyle(1, cl[i]);
					container.graphics.drawCircle(0,0,7);
					container.graphics.endFill()
					Display(_player.get(Display)).displayObject.parent.addChild(container);
					_debugRects.push(container)
				}
			}
			
			_cData["gate"] = {offset: new Point (Skiing.GATE_SEPARATION_X/2,Skiing.GATE_SEPARATION_Y/2), width:50, depth:120}
			_cData["rampSmall"] = {offset: new Point (0,0), width:90, depth:40}
			_cData["rampBig"] = {offset: new Point (0,0), width:130, depth:45}
			_cData["obstacleHead"] = {offset: new Point (0,0), width:200, depth:100}
			_cData["obstacleStatue"] = {offset: new Point (0,0), width:100, depth:80}
			_cData["obstacleFoot"] = {offset: new Point (0,0), width:100, depth:50}
			_cData["obstacleRock0"] = {offset: new Point (0,0), width:100, depth:60}
			_cData["obstacleRock1"] = {offset: new Point (0,0), width:215, depth:60}
			_cData["obstacleRock2"] = {offset: new Point (0,0), width:100, depth:60}
			_cData["obstacleRock3"] = {offset: new Point (0,0), width:100, depth:60}
			_cData["obstacleTree"] = {offset: new Point (0,0), width:100, depth:60}
			_cData["finishLineFront"] = {offset: new Point (0,0), width:100, depth:2000}
			
			var o:Object
			var m1:Number = Skiing.SLOPE_DEPTH
			var m2:Number = Skiing.SLOPE_WIDTH
			for (var t:String in _cData) {
				o = _cData[t]
				var d1:Number = o.depth / (2 * Math.sqrt(m1 * m1 + 1))
				var w1:Number = d1 * m1
				var w2:Number = o.width / (2 * Math.sqrt(m2 * m2 + 1))
				var d2:Number = w2 * m2
				o.x1 = o.offset.x -w1 -w2
				o.y1 = o.offset.y + d1 - d2
				o.x2 = o.offset.x + w1 - w2
				o.y2 = o.offset.y -d1 -d2
				o.x3 = o.offset.x + w1 + w2
				o.y3 = o.offset.y -d1 + d2
				o.x4 = o.offset.x -w1 + w2
				o.y4 = o.offset.y + d1 + d2
			}
			
			
		}
		
		public function setupRace ():void {
		}
		
		override public function update( time : Number ) : void
		{
			var i:int
			var playerSp:Spatial = Spatial (_player.get(Spatial))
			var st:String = _player.get(StateString).state
			var t:String 
			var r:Rectangle
			var sp:Spatial
			var o:Object
			
			if (st == "skiing") {
				for each (var e:Entity in _entities) {
					t = e.get(ObstacleType).type
					o = _cData[t]
					sp = Spatial (e.get(Spatial));
					
					if (e.get(StateString).state != "hit") {
						var o2:Object = {}
						for  (i =0; i < 4 ; i++) {
							//								_debugRects[i].x = o["x"+(i+1)] + sp.x
							//								_debugRects[i].y = o["y"+(i+1)] + sp.y
							//								_debugRects[i].parent.addChild(_debugRects[i])
							o2["pt"+(i+1)]= new Point ( o["x"+(i+1)] + sp.x, o["y"+(i+1)] + sp.y)
						}	
						//							_debugRects[4].x = sp.x
						//							_debugRects[4].y = sp.y
						//							_debugRects[0].parent.addChild(_debugRects[i])
						
						if (isPointInQuad (o2.pt1,o2.pt2,o2.pt3,o2.pt4, new Point (playerSp.x, playerSp.y+ Skiing.PLAYER_OFFSET_Y))){
							//						if (checkInside (_cData["gate"],500, 200, playerSp.x, playerSp.y)){
							trace ("QUAD IIIIIIIIIIIIIIIIIIIIIIIIINNNNSIDE!!!!!!!!!!!! type:" + t)
							collision.dispatch(e)
							
						} else {
							
							// second check for gates
							if (t == "gate" ) {
								if (e.get(GatePartner)) {
									if (e.get(StateString).state != "hit") {
										var e2:Entity = e.get(GatePartner).partner
										var sp2:Spatial = e2.get(Spatial) as Spatial
										var pt1:Point = new Point (sp.x,sp.y)
										var pt2:Point = new Point (sp2.x,sp2.y)
										var pt3:Point = new Point ( prevPlayerSp.x,prevPlayerSp.y)
										pt3.y += Skiing.PLAYER_OFFSET_Y
										var pt4:Point = new Point (playerSp.x, playerSp.y+Skiing.PLAYER_OFFSET_Y)
										var intersection:Point = intersectSegment(pt1,pt2,pt3,pt4)
										if (intersection) {
											e.get(StateString).state = "hit"
											collision.dispatch(e)
											trace ("LINnnnnnnnnnnne INNNNSIDE!!!!!!!!!!!!")

										}
									}
								}
							}
						}
						
					}
				}
				//trace ("dist:" + Point.distance(prevPlayerSp, new Point ( playerSp.x ,playerSp.y)))
				if (Point.distance(prevPlayerSp, new Point ( playerSp.x ,playerSp.y)) > 5){
					prevPlayerSp.x = playerSp.x
					prevPlayerSp.y = playerSp.y
				}
			}
		}
		
		private function intersectSegment(p1:Point, p2:Point, p3:Point, p4:Point):Point {
			var arr:Array = [p1,p2,p3,p4]
			//trace ("-------")
//			if ( Skiing.DEBUG_SHOW_COLLISION_RECTS) {
//				for  (var i:int =0; i < 5 ; i++) {
//					_debugRects[i].x = arr[i].x
//					_debugRects[i].y = arr[i].y
//					//trace (arr[i])
//					_debugRects[i].parent.addChild(_debugRects[i])
//				}
//			}
			
			var v12:Object = {x:p2.x - p1.x, y:p2.y - p1.y};
			var v34:Object = {x:p4.x - p3.x, y:p4.y - p3.y};
			var d:Number = v12.x * v34.y - v12.y * v34.x
			if(!d) return null; //points are collinear
			var a:Number = p3.x - p1.x;
			var b:Number = p3.y - p1.y
			var t:Number = (a * v34.y - b * v34.x) / d;
			var s:Number = (b * v12.x - a * v12.y) / -d;
			if(t < 0 || t > 1 || s < 0 || s > 1) {
				return null; //line segments don't intersect
			}
			else {
				return new Point(p1.x + v12.x * t, p1.y + v12.y * t)
			}
		}
		
		private function checkInside (o:Object, x:Number, y:Number):Boolean {
			var i:int
			var inside:Boolean = false
			var k:Number;
			var m:Number;
			if (y >= o.y1 && y <= o.y3) {
				k = (o.x4 - o.x1) / (o.y4 - o.y1);
				m = o.x1 - k * o.y1;
				if (x >= k * y + m) {
					k = (o.x3 - o.x2) / (o.y3 - o.y2);
					m = o.x2 - k * o.y2;
					if (x <= k * y + m) {
						inside = true
					}
				}
			}
			
			_debugRects[4].x = x
			_debugRects[4].y = y-50
			_debugRects[0].parent.addChild(_debugRects[4])
			
			trace( "=========" + o.x1 )
			for  (i =0; i < 4 ; i++) {
				
				_debugRects[i].x = o["x"+(i+1)] 
				_debugRects[i].y = o["y"+(i+1)] 
				_debugRects[i].parent.addChild(_debugRects[i])
			}
			
			return inside
		}
		
		private function isPointInQuad(point1, point2, point3, point4, testPoint):Boolean
		{ 
			//Check the two triangles. If the first is true, skip the second calculation to save memory
			if(inTriangle(point1, point2, point3, testPoint)) return true;
			if(inTriangle(point4, point1, point3, testPoint)) return true;
			return false;
		}
		
		private function dot(vect1:Point, vect2:Point) : Number
		{
			return(vect1.x*vect2.x + vect1.y*vect2.y);
		}
		
		private function inTriangle(t1:Point, t2:Point, t3:Point, point:Point) : Boolean
		{
			var invDenom:Number;
			var u:Number;
			var v:Number;
			var dot00:Number;
			var dot01:Number;
			var dot02:Number;
			var dot11:Number;
			var dot12:Number;
			var v0:Point = new Point();
			var v1:Point = new Point();
			var v2:Point = new Point();
			
			// Compute vectors
			v0.x = t3.x - t1.x;
			v1.x = t2.x - t1.x;
			v2.x = point.x - t1.x;
			v0.y = t3.y - t1.y;
			v1.y = t2.y - t1.y;
			v2.y = point.y - t1.y;
			
			// Compute dot products
			dot00 = dot(v0, v0);
			dot01 = dot(v0, v1);
			dot02 = dot(v0, v2);
			dot11 = dot(v1, v1);
			dot12 = dot(v1, v2);
			
			// Compute barycentric coordinates
			invDenom = 1 / (dot00 * dot11 - dot01 * dot01);
			u = (dot11 * dot02 - dot01 * dot12) * invDenom;
			v = (dot00 * dot12 - dot01 * dot02) * invDenom;
			
			// Check if point is in triangle
			return (u > 0) && (v > 0) && (u + v < 1);
		}
		
		
	}
}

