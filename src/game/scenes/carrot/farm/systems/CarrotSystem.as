package game.scenes.carrot.farm.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.nodes.entity.collider.PlatformCollisionNode;
	import game.scenes.carrot.farm.nodes.CarrotNode;
	import game.systems.SystemPriorities;
	
	import org.osflash.signals.Signal;
	
	public class CarrotSystem extends System
	{
		public function CarrotSystem()
		{
			_pulled = new Signal();
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_nodes = systemsManager.getNodeList( CarrotNode );
			_player = systemManager.getNodeList(PlatformCollisionNode);
			_pulled = new Signal( String );
		}
		
		override public function update( time:Number ):void
		{
			var node:PlatformCollisionNode;
			var carrot:CarrotNode;
			var charSpatial:Spatial;
			var carrotSpatial:Spatial;
			var timeline:Timeline;
			
			for( node = _player.head; node; node = node.next )
			{
				charSpatial = node.entity.get( Spatial );
				
				for( carrot = _nodes.head; carrot; carrot = carrot.next )
				{
					carrotSpatial = carrot.spatial;
					timeline = carrot.timeline;

					if( Math.abs( charSpatial.x - carrotSpatial.x ) < 200 )
					{
						if( !carrot.carrot.playing )
						{
							timeline.gotoAndPlay( 1 );
							carrot.carrot.playing = true;
						}
						else if( timeline.currentIndex == 25 )
						{
							_pulled.dispatch( Id( carrot.entity.get( Id )).id );
					//		var audio:Audio = new Audio();
				//			carrot.entity.add( audio );
				//			audio.play( "effects/pop_02.mp3" );
						}
					}
				}
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( CarrotNode );
			_nodes = null;
			_player = null;
		}
		
		public var _pulled:Signal;
		private var _nodes : NodeList;
		private var _player : NodeList;
	}
}
