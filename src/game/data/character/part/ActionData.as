package game.data.character.part
{
	import game.util.DataUtils;
	public class ActionData
	{	
		/**
		 * NOT IMPLEMENTED YET
		 * @param	type
		 * @param	effectClass
		 * @param	...args
		 */
		public function ActionData( type:String = "", effectClass:Class = null, ...args )
		{
			this.type = DataUtils.getString(type);
			this.effectClass = effectClass;
			this.params = args;
		}
		
		public var type:String;
		public var effectClass:Class;
		public var params:Array;
	}
}