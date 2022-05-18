package game.systems.ui
{
	
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	
	import game.components.timeline.Timeline;
	import game.nodes.ui.TabBarNode;
	import game.systems.SystemPriorities;
	
	/**
	 * Manages the alignment of tab buttons, so as their width changes their x position shifts to account for change
	 */
	public class TabBarSystem extends ListIteratingSystem
	{
		public function TabBarSystem()
		{
			super( TabBarNode, updateNode );
			super._defaultPriority = SystemPriorities.postUpdate;
		}
		
		private function updateNode( node:TabBarNode, time:Number):void
		{
			if( node.tabBar.inTransition )	// this is turned off externally
			{
				var childEntity:Entity = node.children.children[0];

				if( childEntity.get(Timeline).frameAdvance )
				{
					var previousChildEntity:Entity = childEntity;
					var previousDisplay:MovieClip;
					var numChildren:uint = node.children.children.length;
					
					for (var i:int = 1; i < numChildren; i++) 
					{
						childEntity = node.children.children[i];
						previousDisplay = MovieClip( previousChildEntity.get(Display).displayObject );
						childEntity.get(Display).displayObject.x = previousDisplay.x + previousDisplay.width;
						previousChildEntity = childEntity;
					}
				}
			}
		}
		
		public static const SELECTED:String	= 'selected';
		public static const DISABLED:String	= 'disabled';
	}
}
