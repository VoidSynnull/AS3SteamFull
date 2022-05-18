package game.components.render
{
	import ash.core.Component;
	
	public class PlatformDepthCollision extends Component
	{
		private var _depth:Number = 0;
		
		public function PlatformDepthCollision()
		{
			
		}
		
		public function get depth():Number
		{
			return this._depth;
		}
		
		public function set depth(depth:Number):void
		{
			if(isFinite(depth))
			{
				this._depth = depth;
			}
		}
	}
}