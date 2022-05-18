package game.scenes.myth.labyrinth.systems
{
	import flash.display.Sprite;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.character.Skin;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.myth.labyrinth.components.ThreadComponent;
	import game.scenes.myth.labyrinth.nodes.ThreadNode;
	import game.systems.GameSystem;
	
	public class GoldenThreadSystem extends GameSystem
	{
		public function GoldenThreadSystem( timestamp:Number )
		{
			super( ThreadNode, nodeUpdate );
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{				
			super.addToEngine( systemManager );
			var player:Entity = group.shellApi.player;
			var hand:Entity = Skin( player.get( Skin )).getSkinPartEntity( "hand1" );
			
			_handSpatial = hand.get( Spatial );
			_spatial = player.get( Spatial );
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function removeFromEngine( systemManager:Engine ) : void
		{
			systemManager.releaseNodeList( ThreadNode );	
			
			super.removeFromEngine( systemManager );
		}
		
		public function nodeUpdate( node:ThreadNode, time:Number ):void
		{
			var thread:ThreadComponent = node.thread;			
			var sprite:Sprite = thread.trail;
			
			var currentX:Number = _spatial.x + ( .36 * _handSpatial.x );
			var currentY:Number = _spatial.y + ( .36 * _handSpatial.y );
			
			if( Math.abs( thread.lastX - currentX ) > 5 || Math.abs( thread.lastY - currentY ) > 5 )
			{	
				if( thread.supported )
				{
					sprite.graphics.lineStyle( 6, 0xFFCC00, .10, false, "none" );
					sprite.graphics.moveTo( thread.lastX, thread.lastY );
					sprite.graphics.lineTo( currentX, currentY );
				}
				
				sprite.graphics.lineStyle( 2, 0xFFCC00, .40, false, "none" );
				sprite.graphics.moveTo( thread.lastX, thread.lastY );
				sprite.graphics.lineTo( currentX, currentY );
				
				thread.lastX = currentX;
				thread.lastY = currentY;
			}
		}
		
		private var _handSpatial:Spatial;
		private var _spatial:Spatial;
	}
}