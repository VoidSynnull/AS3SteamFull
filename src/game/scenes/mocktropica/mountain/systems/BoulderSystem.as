package game.scenes.mocktropica.mountain.systems
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import ash.core.Engine;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.data.scene.hit.HitData;
	import game.data.sound.SoundModifier;
	import game.scenes.mocktropica.mountain.components.BoulderComponent;
	import game.scenes.mocktropica.mountain.nodes.BoulderNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	
	public class BoulderSystem extends GameSystem
	{
		public function BoulderSystem(hitArea:BitmapData, hitAreaScale:Number, hitBitmapOffsetX:Number, hitBitmapOffsetY:Number )
		{
			super(BoulderNode, updateNode, null, null);
			_hitArea = hitArea;
			_hitAreaScale = hitAreaScale;
			_hitBitmapOffsetX = hitBitmapOffsetX;
			_hitBitmapOffsetY = hitBitmapOffsetY;
		}
		
		private function updateNode( node:BoulderNode, time:Number ):void
		{
			var motion:Motion;
			var offsetX:Number = 0;
			var offsetY:Number = node.edge.rectangle.bottom;
			var hitY:Number;
			var boulder:BoulderComponent = node.boulder;
			var randomX:Number;
			
			motion = node.motion;
			checkHits( node, _hitArea, motion, motion.totalVelocity.x * time, motion.totalVelocity.y * time, offsetX, offsetY );
			
			// Check if off of screen and if it has moved past the last hit y
			if( motion.y > ( _hitArea.height / _hitAreaScale ) + 300 + _hitBitmapOffsetX  || motion.x > ( _hitArea.width / _hitAreaScale ) + _hitBitmapOffsetY)
			{
				if( _playerSpatial.y > 2400 )
				{
					randomX = _playerSpatial.x - ( Math.random() * 200 ) - 100;
					if( _playerSpatial.x > 1200 )
					{
						randomX = 0;
					}
					
					EntityUtils.position( node.entity, randomX, boulder.startY );
					motion.velocity = new Point( 45, 350 );
					motion.rotationVelocity = 45;
					motion.acceleration.y = MotionUtils.GRAVITY;
				}
				else
				{
					motion.velocity = new Point( 0, 0 );
					motion.rotationVelocity = 0;
					motion.acceleration = new Point( 0, 0 );
				}
			}
			
			if( boulder.hit && Math.abs( motion.y  - boulder.lastY ) > 400 )
			{
				boulder.hit = false;
				boulder.rebound = false;
			}
			
			if( node.display.displayObject.hitTestObject( _playerDisplay.displayObject ))
			{
				_playerMotion.velocity.x = 0;
				if( !boulder.firstHit )
				{
					group.shellApi.triggerEvent( "no_pain" );
					boulder.firstHit = true;
				}
			}
		}
		
		private function checkHits( node:BoulderNode, hitArea:BitmapData, motion:Motion, velocityX:Number, velocityY:Number, offsetX:Number = 0, offsetY:Number = 0 ):void
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
			var hitData:HitData;
			var index:int;
			var boulder:BoulderComponent = node.boulder;
			var audio:Audio = node.audio;
			
			for(index = range; index > -1; index--)
			{
				targetY = originY - index;
				// check for the color of a 'platform'.  Apply the scale of the data to the x,y position.
				hitColor = hitArea.getPixel( originX * _hitAreaScale + _hitBitmapOffsetX, targetY * _hitAreaScale + _hitBitmapOffsetY );
				
				if( hitColor != 0 && !boulder.hit )
				{
					motion.velocity.y -= 150;
					if( !boulder.rebound )
					{
						boulder.lastY = targetY;
						if( !audio.isPlaying( SoundManager.EFFECTS_PATH + EXPLOSION ));
						audio.play( SoundManager.EFFECTS_PATH + EXPLOSION, false, SoundModifier.POSITION );
					}
					
					boulder.rebound = true;
				}
				else if( boulder.rebound && !boulder.hit )
				{
					boulder.hit = true;
				}
			}
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			_playerSpatial = group.shellApi.player.get( Spatial );
			_playerMotion = group.shellApi.player.get( Motion );
			_playerDisplay = group.shellApi.player.get( Display );
			super.addToEngine(systemManager);
		}
		
		private static const EXPLOSION:String = 		"explosion_01.mp3";
		private var _playerSpatial:Spatial;
		private var _playerMotion:Motion;
		private var _playerDisplay:Display;
		private var _hitArea:BitmapData;
		private var _hitAreaScale:Number;
		private var _hitBitmapOffsetX:Number = 0;
		private var _hitBitmapOffsetY:Number = 0;
	}
}