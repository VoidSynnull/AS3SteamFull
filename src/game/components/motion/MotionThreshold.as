package game.components.motion
{	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Motion;
	
	import org.osflash.signals.Signal;
	
	public class MotionThreshold extends Component
	{
		public function MotionThreshold( property:String = "", operator:String = "", targetEntity:Entity = null, offset:Number = 0 )
		{
			this.property = property;
			this.operator = operator;
			this.offset = offset;
			
			if ( targetEntity )
			{
				this.target = targetEntity.get( Motion );
			}
			
			entered = new Signal();
			exitted = new Signal();
		}
		
		
		public var entered:Signal;
		public var exitted:Signal;
		public var isInside:Boolean = false;
		
		public var operator:String = "";
		public var property:String = "";
		
		public var target:Motion;		// target to test against
		
		public var threshold:Number;	// threshold to test against
		public var axisValue:String;	// for more complex motion parameters
		
		public var offset:Number;		// offset for either target or threshold
		
		public var _firstCheck:Boolean = true;
	}
}