package game.scenes.poptropolis.skiing
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	
	public class SkiingLooperSystem extends System
	{
		private var _hurdleGroups:Array
		private var _player:Entity
		private var _hurdleDistance:Number
		private var _active:Boolean
		
		private var _maxSkiingX:*;
		public function SkiingLooperSystem()
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
		
		public function init (__player:Entity, h0:Vector.<Entity>, h1:Vector.<Entity>, __hurdleDistance:Number, __maxSkiingX:Number):void {
			_player = __player
			_hurdleGroups = new Array
			_hurdleGroups.push (h0)
			_hurdleGroups.push (h1)
			_hurdleDistance = __hurdleDistance
			_maxSkiingX = __maxSkiingX
			
			_active = true
		}
		
		override public function update( time : Number ) : void
		{
			var tl:Timeline
			
			if (_active) {
				if (_player) 
				{
					for each (var hGroup:Vector.<Entity> in _hurdleGroups) 
					{
						for (var j:int = 0; j < hGroup.length; j++) {
							var h:Entity = hGroup[j]
							var sp:Spatial = h.get(Spatial)// check loop skiing
							var playerSpatial:Spatial = _player.get(Spatial) as Spatial
							if (sp.x < _player.get(Spatial).x - 1000) {
								if (sp.x + _hurdleDistance*2 < _maxSkiingX) {
									sp.x += _hurdleDistance*2
									tl = h.get(Timeline) 
									tl.gotoAndStop ("stand")	
								}
							}
						}
					}
				}			
			}
		}
	}
}