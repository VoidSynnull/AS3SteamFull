package game.components.motion
{
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import org.osflash.signals.Signal;

	public class Threshold extends Component
	{
		public function Threshold( property:String = "", operator:String = "", targetEntity:Entity = null, offset:Number = 0 )
		{
			this.property = property;
			this.operator = operator;
			this.offset = offset;
			
			if ( targetEntity )
			{
				this.target = targetEntity.get( Spatial );
			}
			
			entered = new Signal();
			exitted = new Signal();
		}
		
		
		public var entered:Signal;
		public var exitted:Signal;
		public var isInside:Boolean = false;

		public var operator:String = "";
		public var property:String = "";
		
		public var target:Spatial;		// target to test against
		
		public var threshold:Number;	// threshold to test against
		
		public var offset:Number;		// offset for either target or threshold
		
		public var _firstCheck:Boolean = true;
	}
}