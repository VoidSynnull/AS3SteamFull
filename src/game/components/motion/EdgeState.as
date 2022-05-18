package game.components.motion
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	import game.data.character.EdgeData;
	
	public class EdgeState extends Component
	{
		private var _states:Dictionary = new Dictionary();
		
		public function EdgeState()
		{
			super();
		}
		
		public function get(id:String):EdgeData
		{
			return this._states[id];
		}
		
		public function add(data:EdgeData):EdgeData
		{
			if(!this._states[data.id])
			{
				this._states[data.id] = data;
				return data;
			}
			return null;
		}
		
		public function remove(id:String):EdgeData
		{
			var data:EdgeData = this._states[id];
			if(data)
			{
				delete this._states[id];
			}
			return data;
		}
	}
}