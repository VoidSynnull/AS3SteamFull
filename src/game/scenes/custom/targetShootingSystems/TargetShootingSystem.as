package game.scenes.custom.targetShootingSystems
{
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	import ash.core.Node;
	
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.managers.ScreenManager;
	import game.scenes.custom.TargetShootingGamePower;
	import game.systems.GameSystem;
	import game.util.TimelineUtils;
	
	// Refer to card 2599 for pumpkin bazooka game
	
	public class TargetShootingSystem extends GameSystem
	{
		// from xml
		private var _frameRate:int = 31;				// frame rate
		private var _timeout:int = 30;					// timeout in seconds
		private var _targetSpeed:int = 8;				// speed for targets to move up and down
		private var _shootDelay:int = 15;				// number of frames before next shoot
		private var _projectileName:String;				// name of projectile swf
		private var _projectileTotal:int;				// number of projectiles
		private var _projectileFrames:int = 22;			// number of frames for projectile explosion
		private var _distractorPoints:int = 25;			// points lost if hit flying distractor
		private var _distractorDist:int;				// distance to distractor
		private var _targets:Array;						// array of target names
		private var _weights:Array;						// array of target weights for random appearance (fractions of 1)
		
		// passed as params
		private var _game:TargetShootingGamePower;		// reference to target shooting game
		private var _gameClip:MovieClip;				// game movieClip
		private var _gamePath:String;					// path to game files
		private var _scoreClip:MovieClip;				// reference to score clip
		
		// time and scoring
		private var _time:Number;						// current time
		private var _lastTime:Number;					// time since last frame update
		private var _secs:Number = 0;					// elapsed seconds
		
		// miscellaneous
		private var _numTargets:int;					// total number of targets
		private var _score:Number = 0;					// current score
		
		// projectiles
		private var _shootCounter:Number = 0;			// counter between shooting
		private var _farDist:int = 15;					// far distance when to remove projectile
		private var _projectileSpeed:Number = 0.4;		// projectile speed increase per frame
		private var _projectileScale:Number = 0.92;		// projecticle scale per frame
		
		// distractors
		private var _hasDistractors:Boolean = false;	// has distractors flag
		private var _leftDistractor:MovieClip;			// left distractor
		private var _rightDistractor:MovieClip;			// right distractor
		private var _distractorClip:MovieClip = null;	// flying distractor clip
		private var _distractorTop:int = 230;			// distractor top
		private var _distractorSpacing:int = 95;		// distractor y spacing
		private var _distractorSpeed:int = 10;			// distractor x speed
		
		// init system
		public function TargetShootingSystem(game:TargetShootingGamePower, gameClip:MovieClip, gamePath:String, scoreClip:MovieClip, gameXML:XML):void
		{
			trace("start game: " + gameXML);
			_game = game;
			_gameClip = gameClip;
			_gamePath = gamePath;
			_scoreClip = scoreClip;
			_scoreClip.tally.text = "0";
			_lastTime = getTimer();
			_time = getTimer();
			
			// get xml values
			if (gameXML.hasOwnProperty("frameRate"))
				_frameRate = int(gameXML.frameRate);
			if (gameXML.hasOwnProperty("timeout"))
				_timeout = int(gameXML.timeout);
			if (gameXML.hasOwnProperty("targetSpeed"))
				_targetSpeed = int(gameXML.targetSpeed);
			if (gameXML.hasOwnProperty("shootDelay"))
				_shootDelay = int(gameXML.shootDelay);
			if (gameXML.hasOwnProperty("projectileName"))
				_projectileName = String(gameXML.projectileName);
			if (gameXML.hasOwnProperty("projectileTotal"))
				_projectileTotal = int(gameXML.projectileTotal);
			if (gameXML.hasOwnProperty("projectileFrames"))
				_projectileFrames = int(gameXML.projectileFrames);
			if (gameXML.hasOwnProperty("distractorPoints"))
				_distractorPoints = int(gameXML.distractorPoints);
			if (gameXML.hasOwnProperty("distractorDist"))
				_distractorDist = int(gameXML.distractorDist);
			if (gameXML.hasOwnProperty("drops"))
				var drops:Array = gameXML.drops.split(",");
			
			// these are mandatory
			_targets = gameXML.targets.split(",");
			_numTargets = _targets.length;
			_weights = gameXML.weights.split(",");
			var scores:Array = gameXML.scores.split(",");
			var delays:Array = gameXML.delays.split(",");
			// distance is number of frames that projectile is in air before checking collision with target
			var distances:Array = gameXML.distances.split(",");

			// process targets and drop down
			var weight:Number = 0;
			for (var i:int = 0; i != _numTargets; i++)
			{
				var name:String = _targets[i];
				var clip:MovieClip = _gameClip[name];
				// stagenum: 0:down, 1:moving up, 2:up, 3:moving down
				clip.stagenum = 0;
				clip.hit = false;
				clip.hotspot.alpha = 0;
				clip.score = int(scores[i]);
				clip.delay = int(delays[i]);
				// if targets drop
				if (drops)
				{
					// all target clips have y at the top
					if (clip.topy == null)
					{
						clip.topy = clip.y;
					}
					else
					{
						clip.y = clip.topy;
					}
					clip.drop = int(drops[i]);
					clip.y += clip.drop;
				}
				clip.dist = int(distances[i]);
				weight += Number(_weights[i]);
				_weights[i] = weight;
				
				// setup timelines if more than one frame
				if (clip.totalFrames != 1)
				{
					var entity:Entity = TimelineUtils.convertClip(clip, _game, null, null, false, _frameRate);
					var timeline:Timeline = entity.get(Timeline);
					timeline.labelReached.add(Command.create(checkAnimLabel, clip));
					clip.timeline = timeline;
					clip.entity = entity;
				}
				// set reference to clip
				_targets[i] = clip;
			}
			
			// setup flying distractors, if any
			if (String(gameXML.leftDistractor) != "")
			{
				_hasDistractors = true;
				_leftDistractor = _gameClip[String(gameXML.leftDistractor)];
				_leftDistractor.x = ScreenManager.GAME_WIDTH;
				TimelineUtils.convertClip(_leftDistractor, _game);
			}
			if (String(gameXML.rightDistractor) != "")
			{
				_hasDistractors = true;
				_rightDistractor = _gameClip[String(gameXML.rightDistractor)];
				_rightDistractor.x = 0;
				TimelineUtils.convertClip(_rightDistractor, _game);
			}
			
			super( Node, updateNode);			
		}
		
		// update system
		private function updateNode( node:Node, etime:Number ):void
		{
			var now:Number = getTimer();
			// if number of ticks for framerate has elapsed
			if (now - _lastTime > 1000/_frameRate)
			{
				_lastTime = now;
				// get seconds
				var vSecs:int = Math.floor(_timeout - (getTimer() - _time) / 1000);
				if (vSecs != _secs)
				{
					trace(vSecs);
					_secs = vSecs;
					showTime();
					// if out of time, then end game and return
					if (vSecs == 0)
					{
						endGame();
						_game.endGame(_score);
						return;
					}
				}
				
				// get random target based on random number and weightings
				var target:MovieClip;
				var random:Number = Math.random();
				for (var i:int = 0; i != _numTargets; i++)
				{
					if (random < _weights[i])
					{
						target = _targets[i];
						break;
					}
				}
				
				// if target selected
				if (target != null)
				{
					// if down, then start to move up
					if (target.stagenum == 0)
					{
						target.stagenum = 1;
						target.counter = 0;
						// if timeline, then start enter sequence
						if (target.timeline)
						{
							target.timeline.gotoAndPlay(2);
						}
						else
						{
							// set to bottommost position
							target.y = target.topy + target.drop;
						}
					}
				}

				// update all targets
				for each (target in _targets)
				{
					switch(target.stagenum)
					{
						case 1: // moving up
							if (target.timeline == null)
							{
								target.y -= _targetSpeed;
								// if reach top then set to next stage
								if (target.y <= target.topy)
									target.stagenum = 2;
							}
							break;
						case 2: // staying at top
							target.counter++;
							// if reach delay count, then set to next stage
							if (target.counter == target.delay)
								target.stagenum = 3;
							break;
						case 3: // moving down
							if (target.timeline == null)
							{
								target.y += _targetSpeed;
								// if reach bottommost position, then set to stage 0
								if (target.y >= target.topy + target.drop )
									target.stagenum = 0;
							}
							else
							{
								// if on hold frame, then play exit sequence
								if (target.timeline.currentFrameData.label == "hold")
								{
									target.timeline.gotoAndPlay("exit");
								}
							}
							break;
					}
				}
				
				// update bazooka
				_gameClip.bazooka.x = _gameClip.mouseX;
				_gameClip.bazooka.y = 480 + (_gameClip.mouseY - 160) * 0.1875;
				
				// projectiles
				_shootCounter++;
				// if ready to shoot again
				if (_shootCounter == _shootDelay)
				{
					_shootCounter = 0;
					// get random number from number of projectiles and load swf
					var frame:int = 1 + Math.floor(Math.random() * _projectileTotal);
					_game.shellApi.loadFile(_game.shellApi.assetPrefix + _gamePath + _projectileName + frame + ".swf", gotProjectile);
				}
				
				// update all projectiles
				var numChildren:int = _gameClip.projectiles.numChildren;
				for (var p:int = numChildren-1; p!= -1; p--)
				{
					var clip:MovieClip = _gameClip.projectiles.getChildAt(p);
					clip.counter++;
					// if not already exploding
					if(!clip.explode)
					{
						// travel and scale
						clip.speedY += _projectileSpeed;
						clip.y += clip.speedY;
						clip.scaleX = clip.scaleY = clip.scaleX * _projectileScale;
						
						// if reach far distance then remove
						if (clip.counter >= _farDist)
						{
							_gameClip.projectiles.removeChild(clip);
						}
						// if reach distractor distance then check collision with distractor
						else if (clip.counter == _distractorDist)
						{
							checkFlyingClip(clip);
						}
						// else check all targets by distance (counter value)
						else
						{
							checkTargetHits(clip, clip.counter);
						}
					}
					// if reach destination frame then remove projectile
					else if (clip.counter == clip.dest)
					{
						_gameClip.projectiles.removeChild(clip);					
					}
				}
				
				// flying distractors
				if (_hasDistractors)
				{
					// if not flying then trigger distractor
					if (_distractorClip == null)
					{
						// decide which distractor
						var chooseRight:Boolean = (Math.random() < 0.5);
						// handle if there is only one distractor
						if (_leftDistractor == null)
						{
							chooseRight = true;
						}
						else if (_rightDistractor == null)
						{
							chooseRight = false;
						}
						// going right
						if (chooseRight)
						{
							_distractorClip = _rightDistractor;
							_distractorClip.y = _distractorTop + _distractorSpacing * Math.floor(3 * Math.random());
							_distractorClip.x = 0;
							_distractorClip.speedX = _distractorSpeed;
							_distractorClip.dest = ScreenManager.GAME_WIDTH + _distractorClip.width;
							_distractorClip.left = -_distractorClip.width;
							_distractorClip.right = 0;
						}
						else
						{
							// going left
							_distractorClip = _leftDistractor;
							_distractorClip.y = _distractorTop + _distractorSpacing * Math.floor(3 * Math.random());
							_distractorClip.x = ScreenManager.GAME_WIDTH;
							_distractorClip.speedX = -_distractorSpeed;
							_distractorClip.dest = 0 - _distractorClip.width;
							_distractorClip.left = 0;
							_distractorClip.right = _distractorClip.width;
						}
					}
					// if flying, then update horizontal position
					else
					{
						_distractorClip.x += _distractorClip.speedX;
						// if reach destination then stop
						if ((_distractorClip == _rightDistractor) && (_distractorClip.x > _distractorClip.dest))
						{
							_distractorClip = null;
						}
						else if ((_distractorClip == _leftDistractor) && (_distractorClip.x < _distractorClip.dest))
						{
							_distractorClip = null;
						}
					}
				}
			}
		}
		
		// when projectile loaded
		private function gotProjectile(aClip:MovieClip):void
		{
			// add to holder clip
			_gameClip.projectiles.addChild(aClip);
			// convert timeline
			var entity:Entity = TimelineUtils.convertClip(aClip.projectile, _game, null, null, false, _frameRate);
			//var entity:Entity = BitmapTimelineCreator.createBitmapTimeline(aClip.projectile, true, true, null, PerformanceUtils.defaultBitmapQuality, _frameRate);
			//_game.addEntity(entity);
			var timeline:Timeline = entity.get(Timeline);
			//vTimeline.stop();
			aClip.timeline = timeline;
			// align to bazooka
			aClip.x = _gameClip.bazooka.x;
			aClip.y = _gameClip.bazooka.y + 30;
			// set speed (range is 320 - 410)
			aClip.speedY = -(570 - _gameClip.bazooka.y)/3.75 - 6;
			aClip.counter = 0;
		}
		
		// update time display
		private function showTime():void
		{
			var vMins:Number = Math.floor(_secs / 60 );
			var vLeft:Number = _secs - vMins * 60;
			var vDigits:String = "0";
			if (vLeft < 10)
				vDigits += String(vLeft);
			else
				vDigits = String(vLeft);
			_gameClip.timerClip.timer.text = String(vMins) + ":" + vDigits;
		}
		
		// check for target collisions
		private function checkTargetHits(projectile:MovieClip, distance:int):void
		{
			// for each target
			for each (var clip:MovieClip in _targets)
			{
				// if distance matches - frames after projectile has been shot
				// targets higher up on the screen will have higher distance values
				if (clip.dist == distance)
				{
					// if target not down and within x range
					var hotspotX:Number = clip.x + clip.hotspot.x;
					if ((clip.stagenum != 0) && (projectile.x > hotspotX) && (projectile.x < hotspotX + clip.hotspot.width))
					{
						var hotspotY:Number = clip.y + clip.hotspot.y;
						// if within y range
						if ((projectile.y > hotspotY) && (projectile.y < hotspotY + clip.hotspot.height))
						{
							// explode projectile and update score
							// if negative score, then no explosion (for ghosts)
							if (clip.score > 0)
							{
								explode(projectile, clip.score);
							}
							if (clip.timeline)
							{
								if (!clip.hit)
								{
									clip.hit = true;
									clip.timeline.gotoAndPlay("hit");
								}
							}
						}
					}
				}
			}
		}
		
		// check projectile clip and if hit deduct points
		private function checkFlyingClip(clip:MovieClip):void
		{
			// if flying clip and within x range
			if ((_distractorClip) && (clip.x > _distractorClip.x + _distractorClip.left) && (clip.x < _distractorClip.x + _distractorClip.right))
			{
				// if within y range
				if ((clip.y > _distractorClip.y) && (clip.y < _distractorClip.y + _distractorClip.height))
				{
					// explode projectile and update score
					explode(clip, -_distractorPoints);
				}
			}									
		}
		
		// explode projectile and update score
		private function explode(projectile:MovieClip, value:Number):void
		{
			projectile.explode = true;
			projectile.timeline.gotoAndPlay(2);
			projectile.dest = projectile.counter + _projectileFrames;
			
			// update score
			_score += value;
			if (_score < 0)
			{
				_score = 0;
			}
			_scoreClip.tally.text = String(_score);
		}
		
		private function checkAnimLabel(label:String, clip:MovieClip):void
		{
			switch (label)
			{
				case "enterEnd":
					clip.stagenum = 2;
					clip.timeline.gotoAndPlay("hold");
					break;
				case "holdLoop":
					clip.timeline.gotoAndPlay("hold");
					break;
				case "exitEnd":
				case "hitEnd":
					// go back to first frame
					clip.timeline.gotoAndStop(0);
					clip.stagenum = 0;
					clip.hit = false;
					break;
			}
		}
		
		private function endGame():void
		{
			var numChildren:int = _gameClip.projectiles.numChildren;
			for (var p:int = numChildren-1; p!= -1; p--)
			{
				var clip:MovieClip = _gameClip.projectiles.getChildAt(p);
				_gameClip.projectiles.removeChild(clip);
			}
			// for each target, remove entity
			for each (clip in _targets)
			{
				if (clip.entity != null)
				{
					_game.removeEntity(clip.entity);
				}
			}
		}
	}
}