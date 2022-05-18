package game.scenes.backlot.cityDestroy.systems
{	
	import flash.display.MovieClip;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.backlot.cityDestroy.components.SearchLightComponent;
	import game.scenes.backlot.cityDestroy.nodes.SearchLightNode;
	import game.systems.GameSystem;
	
	public class SearchLightSystem extends GameSystem
	{
		public function SearchLightSystem()
		{
			super( SearchLightNode, updateNode );
		}
		
		private function updateNode( node:SearchLightNode, time:Number ):void
		{
			var light:SearchLightComponent = node.light;
			var spatial:Spatial = node.spatial;
			var beamSpatial:Spatial = light.beam.get( Spatial );
			var playerSpatial:Spatial = group.shellApi.player.get( Spatial );
			var timeline:Timeline;
			var playerDisplay:Display = group.shellApi.player.get( Display );
			
			var hit:MovieClip = light.hit;
			var playerMotion:Motion = group.shellApi.player.get( Motion );
			// TARGETS PLAYER
			switch( light.state ) 
			{
				case IDLE:
					var dx:Number = playerSpatial.x - spatial.x;
					var dy:Number = playerSpatial.y - spatial.y;
					var angle:Number = Math.atan2( dy, dx );
					
					var degrees:Number = angle * (180 / Math.PI);
					var delta:Number = beamSpatial.rotation - degrees;
					
					
					if( Math.abs(delta) < .2 )
					{
						beamSpatial.rotation = beamSpatial.rotation - delta * .1;
					}
					else
					{
						beamSpatial.rotation = degrees;
					}
					
					if ( hit.hitTestPoint( group.shellApi.offsetX( playerMotion.x ), group.shellApi.offsetY( playerMotion.y ), true))
					{
						if(node.entity.get(Audio))
							Audio(node.entity.get(Audio)).play("effects/explosion_01.mp3");
						light.state = EXPLODE;
					}
					
					break;
				
				// SET STATE TO DESTROYED AND PLAY ANIMATION
				case EXPLODE:
					Display( light.explosion.get( Display )).visible = true;
					Display( light.beam.get( Display )).visible = false;
					
					timeline = light.explosion.get( Timeline );
					timeline.paused = false;
					timeline.gotoAndPlay( 1 );
					
					timeline = light.base.get( Timeline );
					timeline.gotoAndStop( Math.ceil(( Math.random() * 2 ) + 1 ));
					light.state = DESTROYED;
					break;
				
				case DESTROYED:
					break;
			}
			
			
		}
		
		private static const IDLE:String = 				"idle";
		private static const EXPLODE:String = 			"explode";
		private static const DESTROYED:String = 		"destroyed";
	}
}