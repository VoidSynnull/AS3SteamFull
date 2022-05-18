package game.scenes.poptropolis.skiing
{
	import flash.display.Sprite;
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.skiing.components.ObstacleType;
	
	// Handles looping and spawning of obstacles
	public class SkiingObstacleSystem extends System
	{
		private var _active:Boolean
		private var _gateIndex:int;
		private var _obstacles:Vector.<Entity>;
		private var _xml:XML;
		private var _indexByType:Object
		
		private var _obstaclesByType:Object;
		private var _spritesForPooling:Object;
		
		public function SkiingObstacleSystem()
		{
		}
		
		
		public function get active():Boolean
		{
			return _active;
		}
		
		public function set active(value:Boolean):void
		{
			_active = value;
		}
		
		public function init ( __obstacles:Vector.<Entity>, __spritesForPooling:Object):void {
			_obstacles = __obstacles
			_active = true
			_spritesForPooling = __spritesForPooling
			_gateIndex = 0
			_indexByType = {}
			_obstaclesByType = {}
		}
		
		override public function update( time : Number ) : void
		{
			if (_active) {
				var type:String
				var spr:Sprite
				var d:Display 
				var e:Entity
				var e2:Entity
				var sp:Spatial
				for (var j:int = 0; j < _obstacles.length; j++) {
					e = _obstacles[j]
					d = e.get(Display)
					sp =  e.get(Spatial)
					type = e.get(ObstacleType).type
					//trace ("[SkiingObstacleSystem] "+ type)
					if (sp.x < 1100 && sp.x > -100 ) {
						if (!d.displayObject) {
							if (_spritesForPooling[type].length > 0) {
								spr = _spritesForPooling[type].pop()
								d = new Display (spr)
								e.add(d)
								//trace ("---------------- [SkiingObstacleSystem] add display to:" + type) 
								if (type == "gate" && e.get(GatePartner)) {
									e2 = e.get(GatePartner).partner;
									if (e2.get(Display).displayObject == null) {
										var spr2:Sprite = _spritesForPooling[type].pop()
										e2.add(new Display (spr2))
									}
								}
							} else {
								trace ("[SkiingObstacleSystem] ERROR: no sprites left in the pool of type:" + type)
							}
							//trace ("----------------[SkiingObstacleSystem] it now has :" + _spritesForPooling[type].length + " item(s)") 
						}
					}
					else if (sp.x < -300) {
						if (d.displayObject) {
							spr = Sprite (d.displayObject)
							_spritesForPooling[type].push(spr)
							d.displayObject = null
							//trace ("----------------[SkiingObstacleSystem] return sprite to pool of type " + type + " it now has :" + _spritesForPooling[type].length + " item(s)") 
						}
					}
				}
			}
		}
	}
}
