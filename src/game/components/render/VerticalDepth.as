package game.components.render
{
	import ash.core.Component;
	
	public class VerticalDepth extends Component
	{
		private var _offset:Number = 0;
		
		public function VerticalDepth()
		{
			super();
		}
		
		public function get offset():Number
		{
			return this._offset;
		}
		
		public function set offset(offset:Number):void
		{
			if(isFinite(offset))
			{
				this._offset = offset;
			}
		}
	}
}