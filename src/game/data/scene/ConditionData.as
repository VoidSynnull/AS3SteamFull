package game.data.scene 
{
	import game.util.DataUtils;

	/**
	 * ...
	 * @author Billy/Bard
	 */
	public class ConditionData 
	{

		public var id:String;
		public var type:String;
		public var event:String;
		public var conditions:Vector.<ConditionData>;
		public var parent:ConditionData;
		public var not:Boolean;
	}
}
