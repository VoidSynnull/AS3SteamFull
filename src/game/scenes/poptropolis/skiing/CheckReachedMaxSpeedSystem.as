package game.scenes.poptropolis.skiing
{
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Motion;
	
	import org.osflash.signals.Signal;
	
	public class CheckReachedMaxSpeedSystem extends System
	{
		public var reachedMaxSpeed:Signal
		private var _bgEntities:Vector.<Entity>
		
		private var _speed:Number;
		
		public function CheckReachedMaxSpeedSystem()
		{
			
		}
		
		public function set speed(value:Number):void
		{
			_speed = value;
		}
		
		public function init(__bgEntities:Vector.<Entity>):void
		{
			_bgEntities = __bgEntities
			
		}
		
		override public function update( time : Number ) : void
		{
			var m:Motion = _bgEntities[0].get(Motion) as Motion
			if (m.velocity.x < _speed) {
				for each (var e:Entity in _bgEntities) {
					m = e.get(Motion) as Motion
					m.acceleration.x = 0
					m.acceleration.y = 0
				}
			}
			
		}
		
	}
}