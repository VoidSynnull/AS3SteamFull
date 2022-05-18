package game.systems.ui
{
	
	import ash.tools.ListIteratingSystem;
	
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.components.ui.ToolTipActive;
	import game.nodes.ui.ButtonNode;
	import game.systems.SystemPriorities;
	
	public class ButtonSystem extends ListIteratingSystem
	{
		public function ButtonSystem()
		{
			super( ButtonNode, updateNode );
			super._defaultPriority = SystemPriorities.postUpdate;
		}
		
		private function updateNode( node:ButtonNode, time:Number):void
		{
			var button:Button = node.button
			var timeline:Timeline = node.timeline;

			if( button.active )
			{
				if ( button.invalidate )
				{
					var prefix:String = "";
					if( button.isSelected )	{ prefix = SELECTED + "_"; }
					
					// handle change in disabled, turn toolTip on or off
					if( button._disableInvalidate )
					{
						if ( button.isDisabled ) 
						{ 
							button.active = false;
							timeline.gotoAndStop( prefix + DISABLED );
							if( node.toolTip )
							{
								node.entity.remove(ToolTipActive)
							}
							return;
						}
						else
						{
							if( node.toolTip )
							{
								node.entity.add(new ToolTipActive()) 
							}
						}
						button._disableInvalidate = false;
					}
					
					timeline.gotoAndStop( prefix + button.currentState );
					button.invalidate = false;
				}
			}
			/*
			else if( timeline.playing )
			{
				
			}
			*/
		}
		
		public static const SELECTED:String	= 'selected';
		public static const DISABLED:String	= 'disabled';
	}
}
