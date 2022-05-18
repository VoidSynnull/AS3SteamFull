package game.scenes.myth.sphinx.systems
{
	import ash.core.Engine;
	
	import game.scenes.myth.MythEvents;
	import game.scenes.myth.sphinx.components.LeverComponent;
	import game.scenes.myth.sphinx.components.WaterWayComponent;
	import game.scenes.myth.sphinx.nodes.LeverNode;
	import game.systems.GameSystem;
	
	public class AquaductSystem extends GameSystem
	{
		public function AquaductSystem( )
		{
			super( LeverNode, updateNode );
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_events = group.shellApi.islandEvents as MythEvents;
			super.addToEngine( systemManager );
		}
		
		private function updateNode( node:LeverNode, time:Number ):void
		{
			var lever:LeverComponent = node.lever;
			var waterWay:WaterWayComponent = lever.pathIn;
		
			if( waterWay.isOn )
			{				
				if( lever.isLeft )
				{
					checkPath( node );
				}
				else
				{
					checkPath( node, false );
				}
			}
			else
			{
				lever.pathOut.isOn = false;
				lever.altPathOut.isOn = false;
			}
		}
		
		private function checkPath( node:LeverNode, isLeft:Boolean = true ):void
		{
			var lever:LeverComponent = node.lever;
			var waterWay:WaterWayComponent;
			
			if( lever.leftIsAlt )
			{
				if( isLeft )
				{
					waterWay = lever.altPathOut;
				}
				else
				{
					waterWay = lever.pathOut;
				}

				waterWay.isOn = true;
				
				if( waterWay.isFall )
				{
					waterWay.feedsInto.isOn = true;
				}
			}
			else
			{
				if( isLeft )
				{
					waterWay = lever.pathOut;
				}
				else
				{
					waterWay = lever.altPathOut;
				}
				waterWay.isOn = true;
				
				if( waterWay.isFall )
				{
					if( waterWay.feedsInto )
					{
						waterWay.feedsInto.isOn = true;
					}
					else if ( !_pathComplete )
					{
						_pathComplete = true;
						group.shellApi.triggerEvent( _events.AQUADUCT_COMPLETE );
					}					
				}
			}
		}
		
		private var _events:MythEvents;
		private var _pathComplete:Boolean = false;
	}
}