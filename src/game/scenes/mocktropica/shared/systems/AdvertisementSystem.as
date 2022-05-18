package game.scenes.mocktropica.shared.systems
{	
	import flash.display.BitmapData;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.Children;
	import game.components.scene.SceneInteraction;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.mocktropica.shared.components.AdvertisementComponent;
	import game.scenes.mocktropica.shared.nodes.AdvertisementNode;
	import game.systems.GameSystem;
	
	import org.osflash.signals.Signal;
	
	public class AdvertisementSystem extends GameSystem
	{
		public function AdvertisementSystem( hitArea:BitmapData, hitAreaScale:Number, hitBitmapOffsetX:Number, hitBitmapOffsetY:Number )
		{
			removeAd = new Signal( Entity );
			super( AdvertisementNode, updateNode );
			_hitArea = hitArea;
			_hitAreaScale = hitAreaScale;
			_hitBitmapOffsetX = hitBitmapOffsetX;
			_hitBitmapOffsetY = hitBitmapOffsetY;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_events = group.shellApi.islandEvents as MocktropicaEvents;
			_playerMotion = group.shellApi.player.get( Motion );
			_playerDisplay = group.shellApi.player.get( Display );
			_playerSpatial = group.shellApi.player.get( Spatial );
			
			super.addToEngine(systemManager);
		}
		
		private function updateNode( node:AdvertisementNode, time:Number ):void
		{
			var ad:AdvertisementComponent = node.ad;
			var spatial:Spatial = node.spatial;
			var motion:Motion = node.motion;
			var entity:Entity;
			
			var targetX:Number;
			var targetY:Number;
			
			var offsetX:Number = 0;
			var offsetY:Number = 0;
			
			
			switch( ad.state )
			{				
				case ad.SPAWN:
					introTween( node );
					break;
				
				case ad.IDLE:
					break;
				
				// find new target on screen
				case ad.SEEK:
					if( ad.level == 3 )
					{
						do {
							targetX = ( Math.random() * ad.camera.viewportWidth ) + ad.camera.viewport.left;
						} while ( Math.abs( targetX - ad.target.x ) < 100 );
						
						do {
							targetY = ( Math.random() * ad.camera.viewportHeight ) + ad.camera.viewport.top;
						} while ( Math.abs( targetY - ad.target.y ) < 100 );
					}
					else
					{
						do {
							targetX = ( Math.random() * group.shellApi.viewportWidth );
						} while ( Math.abs( targetX - ad.target.x ) < 100 );
						
						do {
							targetY = ( Math.random() * group.shellApi.viewportHeight );
						} while( Math.abs( targetY - ad.target.y ) < 100 );
					}
					
					ad.target.x = targetX;
					ad.target.y = targetY;
					
					ad.state = ad.MOVING;
					break;
				
				case ad.MOVING:
					var dx:Number = ad.target.x - spatial.x;
					var dy:Number = ad.target.y - spatial.y;
					var angle:Number = Math.atan2(dy, dx);
					
					motion.velocity.x = Math.cos(angle) * ad.speeds[ ad.level - 1 ];
					motion.velocity.y = Math.sin(angle) * ad.speeds[ ad.level - 1 ];
					
					if( ad.level == 2 )
					{
						tiltAd( spatial, angle );
						tiltAd( ad.visual.get( Spatial ), angle );
					}
					
					if( Math.abs( spatial.x - ad.target.x ) < 10 && Math.abs( spatial.y - ad.target.y ) < 10 )
					{
						ad.state = ad.SEEK;
						checkHits( node, _hitArea, motion, motion.totalVelocity.x * time, motion.totalVelocity.y * time, offsetX, offsetY );
					}
					
					break;
				
				case ad.DEAD:
					entity = node.entity.get( Children ).children[ 0 ];
					group.removeEntity( entity );
					node.entity.remove( Motion );
					node.entity.remove( SceneInteraction );
					node.entity.remove( Interaction );
					
					removeAd.dispatch( node.entity );
					break;
			}
			
			if( group.shellApi.checkEvent( _events.BOUGHT_ADS ))
			{
				ad.state = ad.DEAD;
			}
		}
		
		private function checkHits( node:AdvertisementNode, hitArea:BitmapData, motion:Motion, velocityX:Number, velocityY:Number, offsetX:Number = 0, offsetY:Number = 0 ):void
		{
			// Add a distance above a platform that the player will be pulled onto it.  This prevents 'bobbing' along the surface.
			var paddingY:uint = 5;
			// The minimum distance to check for hits along the y-axis
			var minimumRange:uint = 5 + paddingY;
			// origin point of the vector to test for hits
			var originX:Number = motion.x + offsetX + velocityX;
			var originY:Number = motion.y + offsetY + velocityY + paddingY;
			// target point of hit tests
			var targetY:Number;
			// total distance to test for hits
			var range:Number = minimumRange + (Math.abs(velocityX) + velocityY);
			var hitColor:uint = 0;
//			var hitData:HitData;
			var index:int;
			
			for(index = range; index > -1; index--)
			{
				targetY = originY - index;
				// check for the color of a 'platform'.  Apply the scale of the data to the x,y position.
				hitColor = hitArea.getPixel( originX * _hitAreaScale + _hitBitmapOffsetX, targetY * _hitAreaScale + _hitBitmapOffsetY );
				
				if( hitColor != 0 )
				{
					node.ad.state = node.ad.SEEK;
				}
			}
		}
		
		private function introTween( node:AdvertisementNode ):void
		{
			var ad:AdvertisementComponent = node.ad;
			var tween:Tween = new Tween();
			var display:Display = ad.visual.get( Display );
			var spatial:Spatial = ad.visual.get( Spatial );
			var interaction:Interaction;
			
			tween.to( display, 1, { alpha : 1 }, "alpha" );
			tween.from( spatial, 1, { scale : .25 }, "scale" );
			ad.visual.add( tween );
			
			
			InteractionCreator.addToEntity( node.entity, [ InteractionCreator.UP, InteractionCreator.OVER, InteractionCreator.DOWN, InteractionCreator.OUT, InteractionCreator.CLICK ]);
			if( ad.level > 0 )
			{
				interaction = node.entity.get( Interaction );
				interaction.down.add( adHit );
				
				if( ad.level == 1 )
				{
					ad.clickPath = BUTTON;
					ad.closePath = CLOSE;
				}
				else if( ad.level == 2 )
				{
					ad.clickPath = BUTTON;
					ad.closePath = TORCH;
				}
				else if( ad.level == 3 )
				{
					ad.clickPath = BUZZER;
					ad.closePath = BUZZER;
				}
				
				ad.state = ad.SEEK;
			}
			
			else
			{
				interaction = node.entity.get( Interaction );
				interaction.down.add( normalAdHit );
//				
//				sceneInteraction.reached.add( normalAdHit );
//				sceneInteraction.ignorePlatformTarget = false;
//				node.entity.add( sceneInteraction );	
				ad.state = ad.IDLE;
			}
		}
		
		private function tiltAd( spatial:Spatial, angle:Number ):void
		{
			var degrees:Number = angle * (180 / Math.PI);
			var delta:Number = spatial.rotation - degrees;
			
			if (delta < -180)
			{
				spatial.rotation = spatial.rotation + 360;
				delta += 360;
			}
			else if (delta >= 180)
			{
				spatial.rotation = spatial.rotation - 360;
				delta -= 360;
			}
			
			if(Math.abs(delta) < .2)
			{
				spatial.rotation = degrees;
			}
			else
			{
				spatial.rotation = spatial.rotation - delta * .1;
			}
		}
		
		private function normalAdHit( hitEnt:Entity ):void
		{
			var ad:AdvertisementComponent = hitEnt.get( AdvertisementComponent );
			var audio:Audio = hitEnt.get( Audio );
			var soundPath:String = BUTTON;
			audio.play( SoundManager.EFFECTS_PATH + CLOSE, false, SoundModifier.POSITION );
			ad.state = ad.DEAD;
		}
	
		private function adHit( hitEnt:Entity ):void
		{
			var ad:AdvertisementComponent = hitEnt.get( AdvertisementComponent );
			var audio:Audio = hitEnt.get( Audio );
			ad.hits++;
			
			if( ad.hits > ad.maxHits && ad.level < 3 )
			{
				ad.state = ad.DEAD;
				if( ad.level == 2 )
				{
					audio.play( SoundManager.EFFECTS_PATH + ad.closePath, true, null, 5 );
				}
				else
				{
					audio.play( SoundManager.EFFECTS_PATH + ad.closePath, false );
				}
			}
				
			else
			{
				ad.state = ad.SEEK;
				audio.play( SoundManager.EFFECTS_PATH + ad.clickPath, false );
			}
		}
		
		public var removeAd:Signal;
		private static const BUTTON:String = 		"button_01.mp3";
		private static const BUZZER:String =		"buzzer_02.mp3";
		private static const CLOSE:String =			"click_crab_01.mp3";
		private static const TORCH:String =			"torch_fire_01_L.mp3";
		
		
		private var _playerMotion:Motion;
		private var _playerDisplay:Display;
		private var _playerSpatial:Spatial;
		
		private var _hitArea:BitmapData;
		private var _hitAreaScale:Number;
		private var _events:MocktropicaEvents;
		private var _hitBitmapOffsetX:Number = 0;
		private var _hitBitmapOffsetY:Number = 0;
	}
}