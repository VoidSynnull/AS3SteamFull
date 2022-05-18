package game.components.render
{
	import flash.display.DisplayObject;
	
	import ash.core.Component;
	
	public class FollowDisplayIndex extends Component
	{
		private var _leader:DisplayObject;
		private var _indexOffset:int = 1;
		
		public function FollowDisplayIndex(leader:DisplayObject, indexOffset:int = 1)
		{
			super();
			this.leader = leader;
			this.indexOffset = indexOffset;
		}
		
		public function get leader():DisplayObject { return _leader }
		public function set leader(value:DisplayObject):void
		{
			if(_leader != value)
			{
				_leader = value;
			}
		}
		
		public function get indexOffset():int { return _indexOffset }
		public function set indexOffset(value:int):void
		{
			//indexOffset can't be 0 because a 0 offset is the DisplayObject we're following.
			if(value != 0)
			{
				if(_indexOffset != value)
				{
					_indexOffset = value;
				}
			}
		}
	}
}