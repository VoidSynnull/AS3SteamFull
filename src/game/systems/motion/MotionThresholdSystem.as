package game.systems.motion
{
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Motion;
	
	import game.components.motion.MotionThreshold;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.MotionThresholdNode;
	import game.systems.SystemPriorities;
	
	public class MotionThresholdSystem extends ListIteratingSystem
	{
		public function MotionThresholdSystem()
		{
			super( MotionThresholdNode, updateNode );
			super._defaultPriority = SystemPriorities.moveComplete;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function updateNode( node:MotionThresholdNode, time:Number ):void
		{
			var motionThreshold:MotionThreshold = node.motionThreshold;
			var motion:Motion = node.motion;
			var target:Motion = node.motionThreshold.target;
			var modifier:String = node.motionThreshold.axisValue;
			
			var thresholdTest:Number;
			var currentValue:Number;
			
			if( target )
			{
				if( modifier )
				{
					thresholdTest = target[ motionThreshold.property ][ modifier ] + motionThreshold.offset;
					currentValue = motion[ motionThreshold.property ][ modifier ];
				}
				else
				{
					thresholdTest = target[ motionThreshold.property ] + motionThreshold.offset;
					currentValue = motion[ motionThreshold.property ];					
				}
			}
			else
			{
				thresholdTest = motionThreshold.threshold + motionThreshold.offset;
				if( modifier )
				{
					currentValue = motion[ motionThreshold.property ][ modifier ];
				}
				else
				{
					currentValue = motion[ motionThreshold.property ];
				}
			}
		
			if ( motionThreshold.operator == EQUALS )
			{
				trigger( node, currentValue == thresholdTest );
			}
			else if ( motionThreshold.operator == GREATER )
			{
				trigger( node, currentValue > thresholdTest );
			}
			else if ( motionThreshold.operator == LESS )
			{
				trigger( node, currentValue < thresholdTest );
			}
			else if ( motionThreshold.operator == GREATER_EQUALS )
			{
				trigger( node, currentValue >= thresholdTest );

			}
			else if ( motionThreshold.operator == LESS_EQUALS )
			{
				trigger( node, currentValue <= thresholdTest );

			}
			
			else if ( motionThreshold.operator == WITHIN )
			{
				if ( target )	// if a target has been set use its property as threshold
				{
					if (( thresholdTest == 0 ) && ( currentValue == 0 ))
						return;
						
					trigger( node, Math.abs( thresholdTest - currentValue ) < motionThreshold.offset );
				}
				else
				{
					if (( motionThreshold.threshold == 0) && ( currentValue == 0 ))
						return;
					
					trigger( node, Math.abs( motionThreshold.threshold - currentValue ) < motionThreshold.offset );
				}
			}
		}
		
		private function trigger( node:MotionThresholdNode, bool:Boolean ):void
		{
			if( !node.motionThreshold._firstCheck )
			{
				if ( bool )
				{
					if ( !node.motionThreshold.isInside )
					{
						node.motionThreshold.isInside = true;
						if ( node.motionThreshold.entered.numListeners > 0 )
						{
							node.motionThreshold.entered.dispatch();
						}
					}
				}
				else
				{
					if ( node.motionThreshold.isInside )
					{
						node.motionThreshold.isInside = false;
						if ( node.motionThreshold.exitted.numListeners > 0 )
						{
							node.motionThreshold.exitted.dispatch();
						}
					}
				}
			}
			else	// if checking for first time, ignore isInside 
			{
				node.motionThreshold._firstCheck = false;
				if ( bool )
				{
					node.motionThreshold.isInside = true;
					if ( node.motionThreshold.entered.numListeners > 0 )
					{
						node.motionThreshold.entered.dispatch();
					}
				}
				else
				{
					node.motionThreshold.isInside = false;
					if ( node.motionThreshold.exitted.numListeners > 0 )
					{
						node.motionThreshold.exitted.dispatch();
					}
				}
			}
		}
		
		public const WITHIN:String 			= "<>";
		public const EQUALS:String 			= "==";
		public const GREATER:String 		= ">";
		public const LESS:String 			= "<";
		public const GREATER_EQUALS:String 	= ">=";
		public const LESS_EQUALS:String 	= "<=";
	}
}