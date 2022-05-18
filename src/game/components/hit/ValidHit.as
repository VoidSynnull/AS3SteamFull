package game.components.hit
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	public class ValidHit extends Component
	{
		public function ValidHit(...args)
		{
			hitIds = new Dictionary();
			
			for(var n:int = 0; n < args.length; n++)
			{
				hitIds[args[n]] = true;
			}
			
			inverse = false;
		}
		
		public function setHitValidState(hitId:String, valid:Boolean = true):void
		{
			if(inverse)
				valid = !valid;
			hitIds[hitId] = valid;
		}
		
		public var inverse:Boolean;
		
		public var hitIds:Dictionary;
	}
}