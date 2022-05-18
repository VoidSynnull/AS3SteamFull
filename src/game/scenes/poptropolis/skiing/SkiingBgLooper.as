package game.scenes.poptropolis.skiing
{
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	public class SkiingBgLooper extends System
	{
		private var _entities:Vector.<Entity>
		private var _active:Boolean
		private var _minX:Number;
		
		public function SkiingBgLooper()
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
		
		public function init (__entities:Vector.<Entity>):void {
			_entities = __entities
			_minX = Skiing.TREE_MIN_X
			_active = true
		}
		
		override public function update( time : Number ) : void
		{
			
			if (_active) {
				var e:Entity
				var sp:Spatial
				for (var i:int = 0; i < _entities.length; i++) {
					e = _entities[i]
					sp = e.get (Spatial) as Spatial
					if (sp.x < _minX) {
						sp.x += Skiing.TREE_WRAP_X * 2
						sp.y += Skiing.TREE_WRAP_Y * 2
					//	trace ("[SkiingBgLooper] loop!")
					}
				}			
			}
		}
		
		public function start():void
		{
			
		}
	}
}


