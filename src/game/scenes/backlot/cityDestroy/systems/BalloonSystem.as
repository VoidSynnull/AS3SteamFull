package game.scenes.backlot.cityDestroy.systems
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.components.entity.character.Skin;
	import game.scenes.backlot.cityDestroy.components.BalloonComponent;
	import game.scenes.backlot.cityDestroy.nodes.BalloonNode;
	import game.systems.GameSystem;
	
	public class BalloonSystem extends GameSystem
	{
		public function BalloonSystem()
		{
			super( BalloonNode, updateNode );
		}
		
		private function updateNode( node:BalloonNode, time:Number ):void
		{
			var balloon:BalloonComponent = node.balloon;
			var entity:Entity;
			var hit:MovieClip = balloon.hit;
			var timeline:Timeline;
			
			var playerMotion:Motion = group.shellApi.player.get( Motion );
			
			var sprite:Sprite;
			
			var playerDisplay:Display = group.shellApi.player.get( Display );
			var playerSpatial:Spatial = group.shellApi.player.get( Spatial );

			var hand:Entity = Skin( group.shellApi.player.get( Skin )).getSkinPartEntity( "hand1" );
			var handSpatial:Spatial = hand.get( Spatial );
			
			var balloonSpatial:Spatial;
			var charX:Number;
			var charY:Number; 
			
			switch( balloon.state )
			{
				case IDLE:
					if ( hit.hitTestPoint( group.shellApi.offsetX( playerMotion.x ), group.shellApi.offsetY( playerMotion.y ) + 50, true))
					{
						if( balloon.number < 7 )
						{
							timeline = balloon.balloon.get( Timeline );
							timeline.gotoAndPlay( "pop" );
							
							timeline = balloon.rope.get( Timeline );
							timeline.gotoAndPlay( "pop" );
							balloon.state = POP;
						}
						
						else
						{
							sprite = new Sprite();	
							
							balloonSpatial = balloon.balloon.get( Spatial );
							
							charX = playerSpatial.x;
							charY = playerSpatial.y;
							
							balloon.state = HOLD;
							
							group.removeEntity( balloon.rope );
							balloon.rope = null;
							
							balloon.ropeEmpty.addChild( sprite );
							
							sprite.graphics.lineStyle( 1, 0x00000000, 1, false, "none" );
							sprite.graphics.moveTo( node.spatial.x, node.spatial.y - 50 );
							
							sprite.graphics.lineTo( charX, charY );
							
							balloon.holdingRope = sprite;
						}
						
						entity = group.getEntityById( "point" + balloon.number );
						timeline = entity.get( Timeline );
						timeline.gotoAndPlay( 1 );
						balloon.pop.dispatch(balloon.number);
				
					}
					break;
				
				case POP:
					if(!balloon.popped && node.entity.get(Audio) != null)
						Audio(node.entity.get(Audio)).play("effects/balloon_pop_01.mp3");
					balloon.popped = true;
					break;
				
				case HOLD:
					balloon.holdingRope.graphics.clear();
					balloonSpatial = balloon.balloon.get( Spatial );
					
					node.spatial.x = playerSpatial.x;
					node.spatial.y = playerSpatial.y - 100;
					
					charX = playerSpatial.x;
					charY = playerSpatial.y;
					
					balloon.holdingRope.graphics.lineStyle( 1, 0x00000000, 1, false, "none" );
					balloon.holdingRope.graphics.moveTo( node.spatial.x, node.spatial.y - 50 );
					
					balloon.holdingRope.graphics.lineTo( charX, charY );
					break;
			}
		}
		
		private static const IDLE:String =			"idle";
		private static const POP:String =			"pop";
		private static const HOLD:String =			"hold";
	}
}