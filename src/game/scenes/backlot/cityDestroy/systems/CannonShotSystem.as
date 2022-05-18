package game.scenes.backlot.cityDestroy.systems
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.timeline.Timeline;
	import game.scenes.backlot.cityDestroy.components.CannonShotComponent;
	import game.scenes.backlot.cityDestroy.nodes.CannonShotNode;
	import game.systems.GameSystem;
	import game.systems.entity.character.states.CharacterState;
	
	public class CannonShotSystem extends GameSystem
	{
		public function CannonShotSystem()
		{
			super( CannonShotNode, updateNode );
		}
		
		private function updateNode( node:CannonShotNode, time:Number ):void
		{
			var shot:CannonShotComponent = node.shot;
			var spatial:Spatial = node.spatial;
			var hit:MovieClip = shot.hitBox;
			var playerMotion:Motion = group.shellApi.player.get( Motion );
			var state:FSMControl = group.shellApi.player.get( FSMControl );
			var timeline:Timeline;
			
			switch( shot.state )
			{
				case shot.ACTIVE:
					spatial.x += shot.trajectoryX;
					spatial.y += shot.trajectoryY;
					break;
				case shot.HIT:
					if(node.entity.get(Audio))
						Audio(node.entity.get(Audio)).play("effects/explosion_01.mp3");
					Display( shot.shell.get( Display )).visible = false;
					Display( shot.explosion.get( Display )).visible = true;
					timeline = shot.explosion.get( Timeline );
					timeline.labelReached.add( Command.create( explosionHandler, node ));
					timeline.gotoAndPlay( 0 );
					shot.state = shot.EXPLODE;
					break;
				
				case shot.DESTROYED:
					group.removeEntity( node.entity );
					break;
			}
			
			if( spatial.x < -50 || spatial.x > 980 || spatial.y < -50 || spatial.y > 2470 )
			{
				group.removeEntity( node.entity );
			}
		}
		
		private function explosionHandler( label:String, node:CannonShotNode ):void
		{
			var shot:CannonShotComponent = node.shot;
			
			switch( label )
			{
				case "ending":
			//		_hitContainer.swapChildren( Display( group.shellApi.player.get( Display )).displayObject, node.display.displayObject );
					shot.state = shot.DESTROYED;
					break;
			}
		}
	}
}