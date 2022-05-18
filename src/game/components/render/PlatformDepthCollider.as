package game.components.render
{
	import ash.core.Component;
	
	public class PlatformDepthCollider extends Component
	{
		private var _priority:int = 0;
		private var _depth:Number = 0;
		private var _depthInvalidated:Boolean = false;
		private var _manualDepth:Boolean = false;
		
		public function PlatformDepthCollider(priority:int = 0)
		{
			this.priority = priority;
		}
		
		public function get priority():int
		{
			return this._priority;
		}
		
		public function set priority(priority:int):void
		{
			this._priority = priority;
			this.depthInvalidated = true;
		}
		
		public function get depth():Number
		{
			return this._depth;
		}
		
		public function set depth(depth:Number):void
		{
			if(isFinite(depth) && this._depth != depth)
			{
				this._depth = depth;
				this._depthInvalidated = true;
			}
		}
		
		public function get depthInvalidated():Boolean
		{
			return this._depthInvalidated;
		}
		
		public function set depthInvalidated(depthInvalidated:Boolean):void
		{
			this._depthInvalidated = depthInvalidated;
		}
		
		public function get manualDepth():Boolean
		{
			return this._manualDepth;
		}
		
		public function set manualDepth(manualDepth:Boolean):void
		{
			this._manualDepth = manualDepth;
		}
	}
}