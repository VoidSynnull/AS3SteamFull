package game.scenes.myth.hydra.components
{
	import ash.core.Component;
	
	public class HydraControlComponent extends Component
	{
		public function HydraControlComponent()
		{
			for( var number:int = 0; number < 5; number ++ )
			{
				activeHeads.push( true );
			}
		}
		public var isAttacking:Boolean = false;
		public var attackHead:int;
		
		public var idleTimer:Number = 0;
		public var deadHeads:Number = 0;
		
		public var defeated:Boolean = false;
		
		public var activeHeads:Vector.<Boolean> = new Vector.<Boolean>();
	}
}