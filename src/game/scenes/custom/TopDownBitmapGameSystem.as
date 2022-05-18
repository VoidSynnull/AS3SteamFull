package game.scenes.custom
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.geom.Point;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.entity.Sleep;
	import game.components.entity.collider.RaceCollider;
	import game.components.timeline.Timeline;
	import game.data.game.GameEvent;
	import game.scene.template.ads.TopDownBitmapGame;
	import game.scenes.custom.StarShooterSystem.EnemyAi;
	import game.systems.GameSystem;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class TopDownBitmapGameSystem extends GameSystem
	{
		private var _game:TopDownBitmapGame;		// reference to top down race game
		private var _moving:Boolean = false;		// if roadway is moving
		private var _dist:Number = 0;				// current distance of roadway movement
		private var _lastTime:Number = 0;			// elapsed time at last update
		private var _playerX:Number = 480;			// position of player at current update
		private var _lastPlayerX:Number = 480;		// position of player at last update
		private var _onScreenObstacles:Array = [];	// array of on-screen obstacles
		private var _index:int = 0;					// index in array of obstacles
		
		// boost variables (only one boost can be active at one time)
		private var _boostActive:Boolean = false;	// when boost is active
		private var _boostStartTime:Number;			// time when boost started
		private var _boostSpeed:uint;				// current boost speed (pulled from boost entity)
		private var _boostTimeLength:uint;			// length of time (in milliseconds) for boost (pulled from boost entity)
		
		public function TopDownBitmapGameSystem(game:TopDownBitmapGame):void
		{
			// store game reference
			_game = game;
			super( Node, updateNode, null, null );	
		}
		
		/**
		 * Start race and begin roadway movement
		 */
		public function startRace():void
		{
			// set moving flag to true
			_moving = true;
			// set last update time to current time
			_lastTime = getTimer();
		}
		
		/**
		 * Update node
		 * @param node
		 * @param eTime
		 */
		private function updateNode( node:Node, eTime:Number ):void
		{
			// get player X if game is playing (means player has been selected)
			if (_game.playing)
				_playerX = _game.playerEntity.get(Spatial).x;
			
			// if roadway is moving
			if (_moving)
			{
				// get elapsed time in seconds since last update
				var time:Number = getTimer();
				var elapsedTime:Number = (time - _lastTime) / 1000;
				_lastTime = time;
				
				// calculate speed and distance applying any active boost
				var currentSpeed:Number = _game.speed + addBoost(time);
				_dist += (currentSpeed * elapsedTime);
				
				// update progress bar
				if (_game.progressAlignment == "vertical")
					_game.progress.height = _dist * _game.progressFactor;
				else
					_game.progress.width = _dist * _game.progressFactor;
				
				// update backgrounds vertically
				var shift:Number = _game.tileHeight * 2;
				var base:Number = _game.startTileY + _dist;
				_game.backEntity1.get(Spatial).y = base - Math.floor((_dist + _game.tileHeight) / shift) * shift;
				_game.backEntity2.get(Spatial).y = base - Math.floor(_dist / shift) * shift - _game.tileHeight;
				// if game has foregrounds
				if (_game.foreEntity1 != null)
				{
					_game.foreEntity1.get(Spatial).y = base - Math.floor((_dist + _game.tileHeight) / shift) * shift;
					_game.foreEntity2.get(Spatial).y = base - Math.floor(_dist / shift) * shift - _game.tileHeight;
				}
				
				// update obstacles holder vertically
				_game.roadEntity.get(Spatial).y = _dist;
				
				// if reach distance then win and return before checking obstacles
				if (_dist >= _game.targetDistance)
				{
					_game.winGame();
					return;
				}
				
				// check on-screen obstacles (in array)
				for (var i:int = _onScreenObstacles.length - 1; i!= -1; i--)
				{
					// get entity and collider
					var name:String = _onScreenObstacles[i];
					var entity:Entity = _game.obstacles[name];
					var collider:RaceCollider = entity.get(RaceCollider);
					
					// get y position relative to top of screen
					var y:Number = entity.get(Spatial).y + _dist;
					
					// if off-screen (one quarter screen height past bottom edge), then turn off obstacle
					if (y > _game.tileHeight * 1.25)
					{
						trace("turn off: " + name);
						// turn off display
						entity.get(Display).visible = false;
						
						// stop any animation
						if (entity.has(Timeline))
							entity.get(Timeline).gotoAndStop(0);
						
						// remove from on-screen array
						_onScreenObstacles.splice(i,1);
					}
						// if obstacle has hit clip
					else if (collider.hitClip != null)
					{
						// check if hit and remove from screen array if true
						if (checkObstacleHit(entity, y, collider))
							_onScreenObstacles.splice(i,1);
					}
				}
			}
			
			// get next obstacles and position them
			getNextObstacles();
			
			// remember player X
			_lastPlayerX = _playerX;
		}
		
		/**
		 * Get next obstacles and position them
		 */
		private function getNextObstacles():void
		{
			// if index within obstacle array
			if (_index < _game.obstacleData.length)
			{
				while (true)
				{
					// get obstacle from data array for current index
					var obstacle:Object = _game.obstacleData[_index];
					
					// if reached distance for obstacle
					if (_dist >= obstacle.y)
					{
						// get obstacle entity
						var name:String = obstacle.name;
						var entity:Entity = _game.obstacles[name];
						if (entity == null)
						{
							trace("-----------------Error: Entity not found for name: " + name);
						}
						else
						{
							var collider:RaceCollider = entity.get(RaceCollider);
							var spatial:Spatial = entity.get(Spatial);
							// position just above top edge of screen
							spatial.x = obstacle.x;
							var basePosY:Number = -2 * _dist - collider.halfHeight;
							// if obstacle Y is negative, then place in scene before moving starts
							if (obstacle.y < 0)
								spatial.y = basePosY - obstacle.y;
							else
								spatial.y = basePosY + obstacle.y;
							
							trace("turn on: " + name + " @ ("+spatial.x+", "+spatial.y+")");
							
							// set velocity
							entity.get(Motion).velocity = new Point(0, -collider.speed);
							
							// make visible
							entity.get(Display).visible = true;
							
							var ai:EnemyAi = entity.get(EnemyAi);
							if(ai) {
								ai.currentHealth = 1;
							}
							
							// make active
							collider.inactive = false;
							
							Sleep(entity.get(Sleep)).sleeping = false;
							
							// add to on-screen obstacles array
							_onScreenObstacles.push(name);
							
							if (entity.has(Timeline))
							{
								// reset animation if slick
								if (collider.type == RaceCollider.SLICK)
									entity.get(Timeline).gotoAndStop(0);
								else if (collider.looping)
									entity.get(Timeline).gotoAndPlay("idle");
								else
									entity.get(Timeline).gotoAndStop(0);
							}
							
							// clear hit
							collider.isHit = false;
						}
						
						// increment index for next obstacle
						// continue checking because next obstacle might be in range
						_index++;
						
						// break out if reached end of data array
						if (_index == _game.obstacleData.length)
							break;
					}
						// else break out if next obstacle has not reached distance
					else
					{
						break;
					}
				}
			}
		}
		
		/**
		 * Check if obstacle hits and return true if need to remove from screen (such as powerup)
		 * @param entity
		 * @param y
		 * @param collider
		 */
		private function checkObstacleHit(entity:Entity, y:Number, collider:RaceCollider):Boolean
		{
			// get verticle overlap distance between player and obstacle hit clips
			var verticalOverlap:Number = y + collider.halfHeight - _game.playerTopY;
			
			if(EntityUtils.sleeping(entity))
				return false;
			
			if (collider.inactive)
				return false;
			
			// if overlap and obstacle still on screen
			if ((verticalOverlap >= 0) && (y - collider.halfHeight < _game.tileHeight))
			{
				// if hit clips intersect
				if (_game.playerHit.hitTestObject(collider.hitClip))
				{
					var playerAtRight:Boolean = false;
					
					// keep hit clips from overlapping if moving or static obstacles (for moving, crashing or static colliders)
					if ((collider.type == RaceCollider.MOVING) || (collider.type == RaceCollider.CRASHING)
						|| (collider.type == RaceCollider.STATIC || collider.type == RaceCollider.OBSTACLE))
					{
						var spatialX:Number = entity.get(Spatial).x;
						var offsetX:Number = _playerX - spatialX;
						var spacing:Number = collider.halfWidth + _game.playerHalfWidth;
						
						// if collider is within horizontal range of player and hitting front (overlap of 25) and player not moving
						if ((Math.abs(offsetX) < spacing) && (verticalOverlap < 25) && (_playerX != _lastPlayerX))
						{
							// if player moving left, then force obstacle to left of player
							if (_playerX < _lastPlayerX)
								playerAtRight = true;
						}
						// if not in range of player and obstacle is at right, then force obstacle to left of player
						else if (offsetX > 0)
							playerAtRight = true;
						
						//really would like to swap the meaning between obstacle and static
						if(collider.type != RaceCollider.OBSTACLE)
						{
							// set spatial to move obstacle to left or right of player
							if (playerAtRight)
								entity.get(Spatial).x = _playerX - spacing;
							else
								entity.get(Spatial).x = _playerX + spacing;
						}
					}
					
					// if not yet registered hit
					if (!collider.isHit)
					{
						// set hit flag
						collider.isHit = true;
						
						// check type of collider
						switch(collider.type)
						{
							// if moving collider such as car or static collider such as a fixed object on roadway
							case RaceCollider.MOVING:
							case RaceCollider.CRASHING:
							case RaceCollider.STATIC:
								
								// play sfx
								playSFX(entity);
								
								// get side speed for left or right
								var speed:Number = _game.sideSpeed;
								if (playerAtRight)
									speed = -speed;
								
								// get hit response speed
								// static colliders usually bounce upwards so hitSpeed is usually negative
								var hitSpeed:Number = collider.hitSpeed
								// if moving collider, then maintain current y velocity
								if (collider.type == RaceCollider.MOVING)
									hitSpeed = entity.get(Motion).velocity.y;
								
								// set velocity and tween to slow down to zero
								entity.get(Motion).velocity = new Point(speed, hitSpeed);
								var tween:Tween = entity.get(Tween);
								if(!tween)
								{
									tween = new Tween();
									entity.add(tween);
								}
								var tweenMax:TweenMax = tween.to(entity.get(Motion).velocity, collider.hitTime, {x:0, ease:Quad.easeOut});
								
								// notify game of hit
								_game.gotHit(playerAtRight, collider.type);
								
								// notify game of points if crashing obstacle such as cars in demo derby
								if (collider.type == RaceCollider.CRASHING)
								{
									_game.gotPoints(collider.points, collider.type);
								}
								if (collider.type != RaceCollider.STATIC)
								{
									// show collider crash animation
									_game.crashAnim(entity, !playerAtRight);
								}
								break;
							
							// if boost collider
							case RaceCollider.BOOST:
								
								// play sfx
								playSFX(entity);
								
								// play boost clip animation, if any
								if (_game.boostTimeline != null)
								{
									_game.boostTimeline.gotoAndPlay(0);
								}
								
								// start boost and convert time to milliseconds
								_boostSpeed = collider.boostSpeed;
								_boostTimeLength = collider.boostTime * 1000;
								_boostActive = true;
								// remember start time
								_boostStartTime = getTimer();
								
								// move player forward (third of screen)
								var forwardDest:Number = _game.playerY - _game.tileHeight / 3;
								TweenUtils.entityTo(_game.playerEntity, Spatial, collider.boostTime / 1000 / 2, {y:forwardDest, ease:Sine.easeIn, onComplete:restorePlayer});
								
								// turn off obstacle display
								entity.get(Display).visible = false;
								
								// notify game of points
								_game.gotPoints(collider.points, collider.type);

								// remove from on-screen array
								return true;
								
								// if slick collider
							case RaceCollider.SLICK:
								
								// play sfx
								playSFX(entity);
								
								// spin player
								_game.crashAnim(_game.playerEntity, true, true);
								_game.playerEntity.remove(Tween);
								_game.playerEntity.get(Spatial).rotation = 350;
								TweenUtils.entityTo(_game.playerEntity, Spatial, collider.slickTime, {rotation:0, onComplete:untiltPlayer});
								
								// play animation if any
								if (entity.has(Timeline))
								{
									entity.get(Timeline).gotoAndPlay(0);
								}
								
								// tilt player car
								if (_game.playerEntity.has(Timeline))
									_game.playerEntity.get(Timeline).gotoAndStop("left");
								
								// turn off player control
								_game.setPlayerControl(false);
								SceneUtil.delay(group, collider.slickTime, _game.setPlayerControl);
								break;
							
							// if the collider should be immoveable
							case RaceCollider.OBSTACLE:
								// play sfx
								playSFX(entity);
								// notify game of hit
								_game.gotHit(playerAtRight, collider.type);
								break;
						}
					}
				}
			}
			return false;
		}
		
		/**
		 * Play sound effect attached to collider object
		 */
		private function playSFX(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			if (audio.allEventAudio != null)
				AudioUtils.play(group, audio.allEventAudio[GameEvent.DEFAULT]["impact"].asset);
		}
		
		/**
		 * Determine boost speed addition based on elapsed time
		 */
		private function addBoost(time:Number):Number
		{
			if (_boostActive)
			{
				// get elapsed time in milliseconds
				var elapsedTime:Number = time - _boostStartTime;
				// get extra speed based on sine curve
				var extra:Number = _boostSpeed * Math.sin(Math.PI * elapsedTime / _boostTimeLength);
				// if within boost time, return value
				if (elapsedTime < _boostTimeLength)
					return extra;
					// when curve and time are done, then turn off
				else
				{
					_boostActive = false;
					// hide boost clip
					if (_game.boostTimeline != null)
					{
						_game.boostTimeline.gotoAndStop("boostStop");
					}
				}
			}
			return 0;
		}
		
		/**
		 * Tween player back to starting Y position for last half of boost
		 */
		private function restorePlayer():void
		{
			TweenUtils.entityTo(_game.playerEntity, Spatial, _boostTimeLength / 1000 / 2, {y:_game.playerY, ease:Sine.easeOut});
		}
		
		/**
		 * untilt player car when slick spin is completed
		 */
		private function untiltPlayer():void
		{
			if (_game.playerEntity.has(Timeline))
				_game.playerEntity.get(Timeline).gotoAndStop(0);
		}
	}
}