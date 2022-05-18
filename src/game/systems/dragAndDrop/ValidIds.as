package game.systems.dragAndDrop
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	import game.util.DataUtils;
	
	public class ValidIds extends Component
	{
		public var ids:Dictionary;
		public var inverse:Boolean;
		
		public function ValidIds(args:Array = null)
		{
			inverse = false;
			ids = new Dictionary();
			if(args == null)
				return;
			
			for each(var id:* in args)
			{
				if(DataUtils.validString(id))
					setIdValidState(id, true);
			}
		}
		
		public function setIdValidState(id:String, valid:Boolean = true):void
		{
			if(inverse)
				valid = !valid;
			ids[id] = valid;
		}
		
		public function isValidId(id:String):Boolean
		{
			if(!DataUtils.validString(id))
				return !inverse;
			return (ids[id] != null) ? ids[id] == !inverse : inverse;
		}
	}
}