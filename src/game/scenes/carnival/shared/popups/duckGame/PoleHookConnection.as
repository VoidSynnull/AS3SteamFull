package game.scenes.carnival.shared.popups.duckGame
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.components.motion.FollowTarget;
	
	public class PoleHookConnection extends Component
	{
		private var _entity1:Entity
		private var _entity2:Entity;
		private var _followOffsetDy:int = 0 // direction y offset is moving in. Used to raise, lower string
		private var _followOffsetYMin:int = 0 // min and max for that offset
		private var _followOffsetYMax:int = 0
		private var _duckOnLine:Entity 
		
		public function PoleHookConnection()
		{
			
		}
		
		public function isHookDown():Boolean {
			return FollowTarget(_entity2.get(FollowTarget)).offset.y >= _followOffsetYMax-10
		}
		
		public function get followOffsetYMax():int
		{
			return _followOffsetYMax;
		}
		
		public function set followOffsetYMax(value:int):void
		{
			_followOffsetYMax = value;
		}
		
		public function get followOffsetYMin():int
		{
			return _followOffsetYMin;
		}
		
		public function set followOffsetYMin(value:int):void
		{
			_followOffsetYMin = value;
		}
		
		public function get followOffsetDy():int
		{
			return _followOffsetDy;
		}
		
		public function set followOffsetDy(value:int):void
		{
			_followOffsetDy = value;
		}
		
		public function get entity2():Entity
		{
			return _entity2;
		}
		
		public function set entity2(value:Entity):void
		{
			_entity2 = value;
		}
		
		public function get entity1():Entity
		{
			return _entity1;
		}
		
		public function set entity1(value:Entity):void
		{
			_entity1 = value;
		}
		
		public function get duckOnLine():Entity
		{
			return _duckOnLine;
		}
		
		public function set duckOnLine(value:Entity):void
		{
			_duckOnLine = value;
		}
		
		
	}
}