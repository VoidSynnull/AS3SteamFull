package game.scenes.backlot.cityDestroy.systems
{
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.scene.HitCreator;
	import game.data.scene.hit.HazardHitData;
	import game.scenes.backlot.cityDestroy.components.CannonComponent;
	import game.scenes.backlot.cityDestroy.components.CannonShotComponent;
	import game.scenes.backlot.cityDestroy.nodes.CannonNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class CannonSystem extends GameSystem
	{
		public function CannonSystem( hitContainer:DisplayObjectContainer )
		{
			_hitContainer = hitContainer;
			super( CannonNode, updateNode );
		}
		
		private function updateNode( node:CannonNode, time:Number ):void
		{
			var cannon:CannonComponent = node.cannon;
			var spatial:Spatial = node.spatial;
			var barrelSpatial:Spatial = cannon.barrel.get( Spatial );
			var playerSpatial:Spatial = group.shellApi.player.get( Spatial );
			var timeline:Timeline;
			var playerDisplay:Display = group.shellApi.player.get( Display );
			
			// TARGETS PLAYER
			var dx:Number = playerSpatial.x - spatial.x;
			var dy:Number = playerSpatial.y - spatial.y;
			var angle:Number = Math.atan2( dy, dx );
			
			var degrees:Number = angle * (180 / Math.PI);
			var delta:Number = barrelSpatial.rotation - degrees;
			
			// temp
			var hit:MovieClip = cannon.hit;
			var playerMotion:Motion = group.shellApi.player.get( Motion );
			
			switch( cannon.state ) 
			{
				case IDLE:
					if (degrees < 0 || degrees > 180 )
					{
						barrelSpatial.rotation = degrees;
						cannon.timer ++;
						if( cannon.timer > 20 )
						{
							cannon.angle = angle; 
							
							timeline = cannon.barrel.get( Timeline );
							timeline.gotoAndPlay( 1 );
							timeline.labelReached.removeAll();
							timeline.labelReached.add( Command.create( barrelHandler, node ));
							cannon.state = LOAD;
						}
					}
					else
					{
						timeline = cannon.barrel.get( Timeline );
						timeline.gotoAndStop( 0 );
						cannon.timer = 0;
						cannon.state = IDLE;
					}
					break;
				
				case LOAD:
					if (degrees < 0 || degrees > 180 )
					{
						barrelSpatial.rotation = degrees;
						cannon.timer ++;
						cannon.angle = angle; 
					}
					else
					{
						timeline = cannon.barrel.get( Timeline );
						timeline.gotoAndStop( 0 );
						cannon.timer = 0;
						cannon.state = IDLE;
					}
					break;
				
				case SHOOT:
					cannon.timer ++;					
					if( cannon.timer > 20 )
					{
						cannon.state = IDLE;
						cannon.timer = 0;
					}
					
					break;
				
				// SET STATE TO DESTROYED AND PLAY ANIMATION
				case EXPLODE:
					if(node.entity.get(Audio))
						Audio(node.entity.get(Audio)).play("effects/explosion_01.mp3");
					Display( cannon.explosion.get( Display )).visible = true;
					Display( cannon.barrel.get( Display )).visible = false;
					
					timeline = cannon.explosion.get( Timeline );
					timeline.paused = false;
					timeline.gotoAndPlay( 1 );
					
					timeline = cannon.base.get( Timeline );
					timeline.gotoAndStop( Math.ceil(( Math.random() * 2 ) + 1 ));
					cannon.state = DESTROYED;
					break;

				case DESTROYED:
					node.entity.remove( CannonComponent );
					break;
			}
			
			//if( cannon.hit.hitTestObject( playerDisplay.displayObject ))
			//{
			if( cannon.state != EXPLODE && cannon.state != DESTROYED )
			{
				if ( hit.hitTestPoint( group.shellApi.offsetX( playerMotion.x ), group.shellApi.offsetY( playerMotion.y ), true))
				{
					cannon.state = EXPLODE;
				}
			}
		}
		
		private function barrelHandler( label:String, node:CannonNode ):void
		{
			var cannon:CannonComponent = node.cannon;

			if( cannon )
			{
				if( label == "ending" )
				{
					group.shellApi.loadFile( cannon.shellUrl, shootShell, node );
				}
			}
		}
		
		// CREATES A NEW CANNON SHOT ENTITY
		private function shootShell( asset:MovieClip, node:CannonNode ):void
		{
			var entity:Entity;
			var cannon:CannonComponent = node.cannon;
			var creator:HitCreator;
			var hazardHitData:HazardHitData;
			
			if( cannon )
			{
				Audio(node.entity.get(Audio)).play("effects/cannon_shot_01.mp3");
				
				var spatial:Spatial = node.spatial;
				var shotSpatial:Spatial;
				var barrelSpatial:Spatial;
				var timeline:Timeline;
				var sprite:Sprite;
				var bitmap:Bitmap;
				var shot:CannonShotComponent;
				
				cannon.state = SHOOT;
					
				barrelSpatial = cannon.barrel.get( Spatial );
				entity = EntityUtils.createSpatialEntity( group, asset, _hitContainer );
				
				shot = new CannonShotComponent();
				shot.hitBox = asset.contents.hit;
//				
//				creator = new HitCreator();
//				hazardHitData = new HazardHitData();
//				hazardHitData.knockBackCoolDown = .75;
//				hazardHitData.knockBackVelocity = new Point(400, 400);
//				hazardHitData.velocityByHitAngle = true;
//				creator.makeHit( shot.hit, HitType.HAZARD, hazardHitData, group );
//				
				shotSpatial = entity.get( Spatial );
				shotSpatial.rotation = barrelSpatial.rotation;
				shotSpatial.x = spatial.x + ( Math.cos( cannon.angle ) * 45 );
				shotSpatial.y = spatial.y + ( Math.sin( cannon.angle ) * 45 );
					
				
				shot.explosion = EntityUtils.createSpatialEntity( group, asset.contents.explosion );
				shot.shell = EntityUtils.createSpatialEntity( group, asset.contents.shell );
				TimelineUtils.convertClip( asset.contents.explosion, group, shot.explosion );
				
				timeline = shot.explosion.get( Timeline );
				timeline.gotoAndStop( 0 );
				
				Display( shot.explosion.get( Display )).visible = false;
					
				shot.trajectoryX = Math.cos( cannon.angle ) * 8;
				shot.trajectoryY = Math.sin( cannon.angle ) * 8;
				
				entity.add( new Audio()).add( shot );
					
				timeline = cannon.barrel.get( Timeline );
				timeline.gotoAndStop( 0 );
				cannon.timer = 0;
			}
		}
		
		private var _hitContainer:DisplayObjectContainer;
		private static const IDLE:String = 				"idle";
		private static const LOAD:String =				"load";
		private static const SHOOT:String = 			"shoot";
		private static const EXPLODE:String = 			"explode";
		private static const DESTROYED:String = 		"destroyed";
	}
}