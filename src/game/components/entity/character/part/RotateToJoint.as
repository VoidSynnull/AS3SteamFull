package game.components.entity.character.part
{
	import ash.core.Component;
	
	import game.data.character.part.InstanceData;
	import game.util.SkinUtils;
	
	public class RotateToJoint extends Component
	{
		public var instanceData:InstanceData;
		public var isFront:Boolean = true;
		private var _part:String = SkinUtils.PANTS;
		
		public function get part():String { return _part; }
		public function set part( part:String ):void
		{
			_part = part;
		}
	}
}