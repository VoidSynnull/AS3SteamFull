package game.systems.motion
{
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Spatial;
	
	import game.components.motion.Threshold;
	import game.nodes.motion.ThresholdNode;
	import game.systems.SystemPriorities;

	public class ThresholdSystem extends ListIteratingSystem
	{
		public function ThresholdSystem()
		{
			super( ThresholdNode, updateNode);
			super._defaultPriority = SystemPriorities.update;	// TODO :: may want to change priority?
		}

		private function updateNode(node:ThresholdNode, time:Number):void
	    {
			var threshold:Threshold = node.threshold;
			var spatial:Spatial = node.spatial;
			var target:Spatial = node.threshold.target;
			
			var thresholdTest:Number;
			
			// NOTE: on the first update the spatial values are returning zero!!!!
			
			if ( target )	// if a target has been set use its property as threshold
			{
				thresholdTest = target[threshold.property] + threshold.offset;
			}
			else			// if no target has been set, use threshold
			{
				thresholdTest = threshold.threshold + threshold.offset;
			}
				
			if ( threshold.operator == EQUALS )
			{
				trigger( node, spatial[threshold.property] == thresholdTest );
			}
			else if ( threshold.operator == GREATER )
			{
				trigger( node, spatial[threshold.property] > thresholdTest );
			}
			else if ( threshold.operator == LESS )
			{
				trigger( node, spatial[threshold.property] < thresholdTest );
			}
			else if ( threshold.operator == GREATER_EQUALS )
			{
				trigger( node, spatial[threshold.property] >= thresholdTest );
			}
			else if ( threshold.operator == LESS_EQUALS )
			{
				trigger( node, spatial[threshold.property] <= thresholdTest );
			}
			else if ( threshold.operator == WITHIN )
			{
				if ( target )	// if a target has been set use its property as threshold
				{
					if ((target[threshold.property] == 0) && (spatial[threshold.property] == 0))
						return;
					trigger( node, Math.abs(target[threshold.property] - spatial[threshold.property]) < threshold.offset );
				}
				else
				{
					if ((threshold.threshold == 0) && (spatial[threshold.property] == 0))
						return;
					trigger( node, Math.abs(threshold.threshold - spatial[threshold.property]) < threshold.offset );
				}
			}
		}
		
		private function trigger( node:ThresholdNode, bool:Boolean ):void
		{
			if( !node.threshold._firstCheck )
			{
				if ( bool )
				{
					if ( !node.threshold.isInside )
					{
						node.threshold.isInside = true;
						if ( node.threshold.entered.numListeners > 0 )
						{
							node.threshold.entered.dispatch();
						}
					}
				}
				else
				{
					if ( node.threshold.isInside )
					{
						node.threshold.isInside = false;
						if ( node.threshold.exitted.numListeners > 0 )
						{
							node.threshold.exitted.dispatch();
						}
					}
				}
			}
			else	// if checking for first time, ignore isInside 
			{
				node.threshold._firstCheck = false;
				if ( bool )
				{
					node.threshold.isInside = true;
					if ( node.threshold.entered.numListeners > 0 )
					{
						node.threshold.entered.dispatch();
					}
				}
				else
				{
					node.threshold.isInside = false;
					if ( node.threshold.exitted.numListeners > 0 )
					{
						node.threshold.exitted.dispatch();
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
