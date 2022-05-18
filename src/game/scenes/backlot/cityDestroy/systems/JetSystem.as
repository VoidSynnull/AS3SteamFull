package game.scenes.backlot.cityDestroy.systems
{
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.engine.BreakOpportunity;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.motion.Threshold;
	import game.creators.scene.HitCreator;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.scenes.backlot.cityDestroy.components.CannonShotComponent;
	import game.scenes.backlot.cityDestroy.components.JetComponent;
	import game.scenes.backlot.cityDestroy.nodes.JetNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class JetSystem extends GameSystem
	{
		public function JetSystem( hitContainer:DisplayObjectContainer )
		{
			_hitContainer = hitContainer;
			super( JetNode, updateNode );
		}
		
		public function updateNode( node:JetNode, time:Number ):void
		{
			var jet:JetComponent = node.jet;
			var spatial:Spatial = node.spatial;
			var motion:Motion = node.motion;
			var threshold:Threshold = node.threshold;
			var playerSpatial:Spatial = group.shellApi.player.get( Spatial );
			
			var tween:Tween = node.tween;
			
			// TARGETS PLAYER
			var dx:Number = playerSpatial.x - spatial.x;
			var dy:Number = playerSpatial.y - spatial.y;
			var angle:Number;
			var degrees:Number;
			
			// ADJUST FOR DIRECTION
			if( !jet.movingLeft )
			{
				angle = Math.atan2( dy, dx );
				degrees = angle * (180 / Math.PI);
			}
			else
			{
				angle = -( Math.atan2( dy, dx ));
				degrees = 180 - ( angle * ( 180 / Math.PI ));
			}
			
			var deltaY:Number = Math.abs( playerSpatial.y - spatial.y );	
			var deltaX:Number = Math.abs( playerSpatial.x - spatial.x );
			
			switch( jet.state )
			{
				case ACTIVE:
					if( !jet.movingLeft )
					{
						if( degrees > 0 && degrees < 55 && deltaY < 300 && deltaX < 600 )
						{						
							jet.state = DIVE;
						}
						else
						{
							spatial.x += 10;
						}
					}
					else
					{
						if( degrees < 360 && degrees > 305 && deltaY < 300 && deltaX < 600 )
						{
							jet.state = DIVE;
						}
						else
						{
							spatial.x -= 10;
						}
					}
					
					break;
				
				case TURN:
					if( !jet.movingLeft )
					{
						jet.movingLeft = true;
						
						threshold.operator = "<";
						threshold.threshold = -100;
						threshold.entered.add( Command.create( aboutFace, node ));
					}
					else
					{
						jet.movingLeft = false;
						
						threshold.operator = ">";
						threshold.threshold = 1000;
						threshold.entered.add( Command.create( aboutFace, node ));
					}
					
					jet.state = ACTIVE;
					break;
			
				case DIVE:
					jet.shootTimer++;
					if( jet.shootTimer > 15 )
					{
						jet.shootTimer = 0;
						jet.angle = angle;
						group.shellApi.loadFile( jet.shellUrl, shootShell, node );
					}
					
					if( deltaX > 100 )
					{
						spatial.rotation = degrees;
						spatial.y += Math.abs( Math.sin( angle ) * 10 );
						spatial.x += Math.cos( angle ) * 10;
					}
					else
					{
						jet.state = CLIMB;
					}
					
					break;
				
				case LEVEL_OFF:
					if( deltaX > 30 )
					{
						if( !jet.movingLeft )
						{
							spatial.x += 10;
							spatial.rotation = 360;
						}
						else
						{
							spatial.x -= 10;
							spatial.rotation = 0;
						}
					}
					else
					{
						jet.state = CLIMB;
					}
					
					break;
					
				case CLIMB:
					if( spatial.y > jet.level )
					{
						dy = jet.level - spatial.y;
						
						if( !jet.movingLeft )
						{
							dx = 900;
							angle = Math.atan2( dy, dx );
							degrees = angle * (180 / Math.PI);
							spatial.x += 10;
						}
						else
						{
							dx = 900;
							angle = -( Math.atan2( dy, dx ));
							degrees = angle * ( 180 / Math.PI );
							spatial.x -= 10;
						}
						
						spatial.rotation = degrees;
						spatial.y -= Math.abs( Math.sin( angle ) * 10 );
					}
					
					else
					{
						if( jet.movingLeft )
						{
							spatial.rotation = 0;
						}
						else
						{
							spatial.rotation = 360;
						}
						
						jet.state = GET_READY;
					}
					
					break;
				
				case GET_READY:
					if( jet.movingLeft )
					{
						spatial.x -= 10;
					}
					else
					{
						spatial.x += 10;
					}
					
					break;
			}
		}
		
		private function aboutFace( node:JetNode ):void
		{
			var jet:JetComponent = node.jet;
			var spatial:Spatial = node.spatial;
			var threshold:Threshold = node.threshold;
			
			spatial.scaleX *= -1;
			spatial.y = jet.level;
			
			threshold.entered.removeAll();
			
			jet.state = TURN;
			jet.deltaX *= -1;
		}
	
		// CREATES A NEW CANNON SHOT ENTITY
		private function shootShell( asset:MovieClip, node:JetNode ):void
		{
			var entity:Entity;
			var jet:JetComponent = node.jet;
			var creator:HitCreator;
			var hazardHitData:HazardHitData;
			
			if( jet )
			{
				var spatial:Spatial = node.spatial;
				var shotSpatial:Spatial;
				var propellorSpatial:Spatial;
				var timeline:Timeline;
				var sprite:Sprite;
				var bitmap:Bitmap;
				// TODO : MOVE JETS ABOVE SHELL EMPTY
				var shot:CannonShotComponent;
				
				propellorSpatial = jet.propellor.get( Spatial );
				entity = EntityUtils.createSpatialEntity( group, asset, _hitContainer );
				
				shotSpatial = entity.get( Spatial );
				shotSpatial.rotation = propellorSpatial.rotation;
				shotSpatial.x = spatial.x;
				shotSpatial.y = spatial.y;
				
				shot = new CannonShotComponent();
				shot.hitBox = asset.contents.hit;
				if(node.entity.get(Audio))
					Audio(node.entity.get(Audio)).play("effects/air_shot_04.mp3");//need a bettter machine gun sound
//				
//				creator = new HitCreator();
//				hazardHitData = new HazardHitData();
//				hazardHitData.knockBackCoolDown = .75;
//				hazardHitData.knockBackVelocity = new Point(400, 400);
//				hazardHitData.velocityByHitAngle = true;
//				creator.makeHit( shot.hit, HitType.HAZARD, hazardHitData, group );
//				
//				
				shot.explosion = EntityUtils.createSpatialEntity( group, asset.contents.explosion );
				shot.shell = EntityUtils.createSpatialEntity( group, asset.contents.shell );
				TimelineUtils.convertClip( asset.contents.explosion, group, shot.explosion );
				
				timeline = shot.explosion.get( Timeline );
				timeline.gotoAndStop( 0 );
				
				Display( shot.explosion.get( Display )).visible = false;
				
				shot.trajectoryX = Math.cos( jet.angle ) * 15;
				shot.trajectoryY = Math.abs( Math.sin( jet.angle ) * 15 );
				
				entity.add(new Audio()).add( shot );
			}
		}
		
		private var _hitContainer:DisplayObjectContainer;
		
		private static const ACTIVE:String =				"active";
		private static const ATTACK:String =				"attack";
		private static const DIVE:String =					"dive";
		private static const LEVEL_OFF:String =				"level_off";
		private static const CLIMB:String = 				"climb";
		private static const GET_READY:String = 			"get_ready";
		private static const TURN:String =					"turn";
		private static const SHOOT:String = 				"shoot";
		private static const EXPLODE:String = 				"explode";
		private static const DESTROYED:String = 			"destroyed";
	}
}