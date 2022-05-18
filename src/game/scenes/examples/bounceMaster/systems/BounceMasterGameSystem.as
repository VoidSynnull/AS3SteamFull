package game.scenes.examples.bounceMaster.systems
{
	import com.poptropica.AppConfig;
	import com.smartfoxserver.v2.kernel;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import de.polygonal2.ds.VectorUtils;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.data.TimedEvent;
	import game.data.motion.time.FixedTimestep;
	import game.scene.template.ads.BotBreakerGame;
	import game.scenes.con3.shared.Vector2D;
	import game.scenes.examples.bounceMaster.BounceMasterCreator;
	import game.scenes.examples.bounceMaster.BounceMasterGroup;
	import game.scenes.examples.bounceMaster.components.BounceMasterGameState;
	import game.scenes.examples.bounceMaster.nodes.BounceMasterGameStateNode;
	import game.scenes.examples.bounceMaster.nodes.BouncerNode;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	import game.utils.AdUtils;
	
	import org.flintparticles.common.displayObjects.Rect;
	import org.flintparticles.common.utils.Maths;
	import org.flintparticles.threeD.geom.Vector3DUtils;
		
	public class BounceMasterGameSystem extends System
	{
		public function BounceMasterGameSystem(game:BotBreakerGame, group:Group, container:DisplayObjectContainer, creator:BounceMasterCreator, width:Number, height:Number,
												bouncerClip:MovieClip,player:Entity,playerClip:MovieClip)
		{
			_group = group;
			_container = container;
			_creator = creator;
			_width = width;
			_height = height;
			_bouncerClip = bouncerClip;
			_player = player;
			_playerClip = playerClip;
			_game = game;
			
			setupText();
			initSettings();
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		private function initSettings():void
		{
			if(_game.multiplierTime != 0)
				MULTIPLIER_TIME = _game.multiplierTime;
		}
		private function setupText():void
		{
			_restartText = new TextField();
			
			_restartText.x = _group.shellApi.viewportWidth/2.3;
			_restartText.y = _group.shellApi.viewportHeight*.3;
			_restartText.text = "Stage " + _currentStage.toString();
			_restartText.setTextFormat(new TextFormat("Billy Serif",36,null,null,null,null,null,null,TextFormatAlign.CENTER));
			_restartText.autoSize = TextFieldAutoSize.CENTER;
			_container["multipliericon"].visible = false;
			_container["powerbar"].visible = false;
			_container.addChild(_restartText);
		}
		override public function addToEngine( systemsManager:Engine ) : void
		{
			_gameStateNodes = systemManager.getNodeList(BounceMasterGameStateNode);
			_bouncerNodes = systemsManager.getNodeList(BouncerNode);
		}
		
		override public function removeFromEngine( systemsManager:Engine ) : void
		{
			systemsManager.releaseNodeList(BounceMasterGameStateNode);
			systemsManager.releaseNodeList(BouncerNode);
			
			_gameStateNodes = null;
			_bouncerNodes = null;
		}
		
		override public function update(time:Number):void
		{
			if(!_gameStateNodes.head)
			{
				return;
			}
			
			_state = BounceMasterGameStateNode(_gameStateNodes.head).state;
			
			if(_state.gameActive)
			{
				if(_state.gameStarted)
				{
					if(!_bouncerNodes.empty)
					{
						/*_state.addNewBouncerWait -= time;
						
						if(_state.addNewBouncerWait < 0)
						{
							_state.addNewBouncerWait = NEW_BOUNCER_WAIT;
							//loadBouncer();
							bouncerLoaded(_bouncerClip);
						}
						*/
						if(_state.addNewBouncer == true)
						{
							//bouncerLoaded(_bouncerClip);
							//_state.addNewBouncer = false;
							
						}
						if(_state.hitTimeWait > 0)
							_state.hitTimeWait -= time;
						if(_state.multiplierTime > 0)
						{
							_state.multiplierTime -= time;
							_container["multipliericon"].visible = true;
							_container["powerbar"].visible = true;
							_container["powerbar"].scaleX = _state.multiplierTime/MULTIPLIER_TIME;
							//_game.setScoreColor(0x32CD32);
						}
						else
						{
							_pointMultiplier = 1;
							//_canMakePointsPower = true;
							_container["multipliericon"].visible = false;
							_container["multipliericon"].visible = false;
							//_game.setScoreColor(0xFFFFFF);
						}
						if(AppConfig.mobile == false)
						{
							if(_game.movePlayerAmount)
							{
								_game.playerEntity.get(Spatial).x += _game.movePlayerAmount;
							}
						}
						updateBouncers(time);
					}
					else
					{
						_state.gameActive = false;
						_state.gameStarted = false;
						_state.gameOver.dispatch();
						return;
					}
				}
				else if(!_firstBouncerLoading)
				{
					_state.totalHits = 0;
					//BounceMasterGameStateNode(_gameStateNodes.head).hud.displayObject["hits"].text = 0;
					_firstBouncerLoading = true;
					_state.lives = 3;
					_state.addNewBouncerWait = RESTART_WAIT;
					_state.hitTimeWait = HIT_WAIT;
					//loadBouncer();
					var boundsClip:MovieClip = _container["bounds"];
					bouncerLoaded(_bouncerClip, new Rectangle(boundsClip.x,boundsClip.y,boundsClip.width,boundsClip.height));
					SceneUtil.addTimedEvent(_group,new TimedEvent(1,4,handleCountDown,true),"countdown");
				}
			}
		}
		private function handleCountDown():void
		{
			_state.addNewBouncerWait--;
			if(_state.addNewBouncerWait <= 0)
			{
				_state.gameActive = true;
				startBouncer();
				_restartText.visible = false;
				SceneUtil.getTimer( _group, "countdown" ).destroy();
				_state.addNewBouncerWait = RESTART_WAIT;
			}
			else
			{
				_restartText.visible = true;
				_restartText.text = _state.addNewBouncerWait.toString();
				_restartText.setTextFormat(new TextFormat("Billy Serif",36,null,null,null,null,null,null,TextFormatAlign.CENTER));
				
			}
		}
		public function reflect( vector:Vector2D, normal:Vector2D ):void
		{
			// using the formula [R = V - (2 * V.N) * N] or [V -= 2 * N * (N.V
			var dot:Number  = ( vector.x * normal.x ) + ( vector.y * normal.y );
			var vn2:Number  = 2.0 * vector.dot(normal );
			vector.x        = vector.x - ( normal.x * vn2 );
			vector.y        = vector.y - ( normal.y * vn2 );
		}
		private function getRandomNumber(start:Number, end:Number):Number
		{
			return start + Math.random() * (end - start);
		}
		private function updateBouncers(time:Number):void
		{
			var bouncerNode:BouncerNode;

			for( bouncerNode = _bouncerNodes.head; bouncerNode; bouncerNode = bouncerNode.next )
			{
				if(bouncerNode.hit.isHit && _state.hitTimeWait <= 0)
				{
					//if(bouncerNode.motion.velocity.y > 0)
					//{
						//player hit
						if(bouncerNode.hit.colliderId == "catcher") 
						{
							bouncerNode.motion.y = bouncerNode.hit.colliderY + bouncerNode.edge.rectangle.top;
							bouncerNode.motion.velocity.y *= -1;
							bouncerNode.motion.velocity.x += (bouncerNode.spatial.x - bouncerNode.hit.colliderEntity.get(Spatial).x)*_game.bounceFactor;
							
							if(_game.bounceSound != "")
							{
								AudioUtils.play(_group,_game.bounceSound);
							}
						}
						if(bouncerNode.hit.colliderId.indexOf("brick") > -1 /*&& _state.hitTimeWait <= 0*/) 
						{
							trace("hit: ball x: " + bouncerNode.hit.colliderEntity.get(Spatial).x + "hit: ball brick x check: " + (bouncerNode.spatial.x + bouncerNode.spatial.width));
							if(bouncerNode.hit.colliderEntity.get(Spatial).x > (bouncerNode.spatial.x + (bouncerNode.spatial.width/2)) || 
								 bouncerNode.hit.colliderEntity.get(Spatial).x < (bouncerNode.spatial.x - (bouncerNode.spatial.width/2)))
							{
								bouncerNode.motion.velocity.x *= -1;
							}
							else
							{
								bouncerNode.motion.velocity.y *= -1;
							}
							
							if(_canMakeMultiplierPower == true && _game.multiplierPowerChance >= getRandomNumber(0,100))
							{
								if( _group.getEntityById("multiplierpower") == null)
								{
									BounceMasterGroup(_group).createPointsPowerUp(_container["multiplierpower"],bouncerNode.hit.colliderEntity.get(Spatial));
									_canMakeMultiplierPower = false;
								}
								if( _group.getEntityById("multiplierpower") != null)
								{
									repositionPower(_group.getEntityById("multiplierpower"),new Spatial(bouncerNode.hit.colliderEntity.get(Spatial).x,bouncerNode.hit.colliderEntity.get(Spatial).y),new Spatial(0,150));
									_canMakeMultiplierPower = false;
								}
							}
						
							_group.removeEntity(bouncerNode.hit.colliderEntity);
							_game.gotPoints(_game.basicBrickPoints*_pointMultiplier);
							BounceMasterGroup(_group).numBricks--;
							
							if(BounceMasterGroup(_group).numBricks == 0 && _state.gameActive)
							{
								

								bouncerNode.motion.velocity.x = bouncerNode.motion.velocity.y = 0;
								if(_group.getEntityById("multiball1") == null)
								{
									_group.removeEntity(_group.getEntityById("multiball1"));
								}
								//repositionPower(_group.getEntityById("multiplierpower"),new Spatial(bouncerNode.hit.colliderEntity.get(Spatial).x,bouncerNode.hit.colliderEntity.get(Spatial).y),new Spatial(0,150));
								repositionBouncer(bouncerNode);
								SceneUtil.addTimedEvent(_group,new TimedEvent(2,1,stageWon,true),"countdown");
								_restartText.text = "Stage " + _currentStage.toString() + " Complete"
								_restartText.setTextFormat(new TextFormat("Billy Serif",36,null,null,null,null,null,null,TextFormatAlign.CENTER));
								_restartText.autoSize = TextFieldAutoSize.CENTER;
								if(_game.gameOverSound != "")
								{
									AudioUtils.play(_group,_game.gameOverSound);
								}
								_restartText.visible = true;
								AdUtils.setScore(_group.shellApi,_game.points,"botbreaker");
								_state.gameActive = false;
							}
							else
							{
								if(_game.brickSound != "")
								{
									AudioUtils.play(_group,_game.brickSound);
								}
							}
							
						}
						_state.hitTimeWait = HIT_WAIT;
					}

				if(bouncerNode.spatial.y > _playerClip.y + 50 && _numBallsActive == 1)
				{
					//trace("bouncer: "+_bouncerClip.y+"player:" + _playerClip.y);
					//_group.removeEntity(bouncerNode.entity);
					
					//_state.addNewBouncer = true;
					_bouncerEntity = bouncerNode.entity;
					_state.lives--;
					if(_state.lives >= 0)
					{
						trace("lose life. current: " + _state.lives);
						_game.loseLife(_state.lives);
						repositionBouncer(bouncerNode);
						SceneUtil.addTimedEvent(_group,new TimedEvent(1,4,handleCountDown,true),"countdown");
						
					}
					else
					{
						trace("game over lives: " + _state.lives);
						_state.gameActive = false;
						_state.gameStarted = false;
						AdUtils.setScore(_group.shellApi,_game.points,"botbreaker");
						_game.loseGame();
					}
					if(_game.loseSound != "")
					{
						AudioUtils.play(_group,_game.loseSound);
					}
					continue;
				}
				else if(bouncerNode.spatial.y > _playerClip.y + 50 && _numBallsActive > 1)
				{
					if(bouncerNode.entity.get(Id).id != "bouncer")
						_group.removeEntity(bouncerNode.entity);
					else
					{
						_bouncerEntity.get(Spatial).x = _group.shellApi.viewportWidth*2;
						_bouncerEntity.get(Spatial).y = _group.shellApi.viewportHeight*-2;
						_bouncerEntity.get(Motion).velocity.x = 0;
						_bouncerEntity.get(Motion).velocity.y = 0;
					}
					_numBallsActive--;
				}
				if(bouncerNode.motionBounds.top)
				{
					bouncerNode.motion.velocity.y = Math.abs(bouncerNode.motion.velocity.y);
					if(_game.bounceSound != "")
					{
						AudioUtils.play(_group,_game.bounceSound);
					}
				}
				
				if(bouncerNode.motionBounds.left)
				{
					bouncerNode.motion.velocity.x = Math.abs(bouncerNode.motion.velocity.x);
					if(_game.bounceSound != "")
					{
						AudioUtils.play(_group,_game.bounceSound);
					}
				}
				else if(bouncerNode.motionBounds.right)
				{
					bouncerNode.motion.velocity.x = -Math.abs(bouncerNode.motion.velocity.x);
					if(_game.bounceSound != "")
					{
						AudioUtils.play(_group,_game.bounceSound);
					}
				}
				
				bouncerNode.motion.rotationVelocity = bouncerNode.motion.velocity.x;
			}
			//if(_playerClip.hitTestObject(_container["multiball"])&& _group.getEntityById("multiball") != null)
			//{
				//repositionPower(_group.getEntityById("multiball"),new Spatial(_group.shellApi.viewportWidth*2,_group.shellApi.viewportWidth*-2),new Spatial(0,0));
				//_numBallsActive = 2;
				//BounceMasterGroup(_group).createMultiBouncer(_container,_player.get(Spatial).x,_player.get(Spatial).y,300,-300, _width, _height*1.5);
			//}
			if(_playerClip.hitTestObject(_container["multiplierpower"])&& _group.getEntityById("multiplierpower") != null)
			{
				repositionPower(_group.getEntityById("multiplierpower"),new Spatial(_group.shellApi.viewportWidth*2,_group.shellApi.viewportWidth*-2),new Spatial(0,0));
				_pointMultiplier = 2;
				_state.multiplierTime = MULTIPLIER_TIME;
				_canMakeMultiplierPower = true;
			}
			if(_group.getEntityById("multiball1") != null)
			{
				if(_group.getEntityById("multiball").get(Spatial).y > _player.get(Spatial).y + 50)
				{
					repositionPower(_group.getEntityById("multiball1"),new Spatial(_group.shellApi.viewportWidth*2,_group.shellApi.viewportWidth*-2),new Spatial(0,0));
					_canMakeMultiPower = true;
				}
			}
			if(_group.getEntityById("multiplierpower") != null)
			{
				if(_group.getEntityById("multiplierpower").get(Spatial).y > _player.get(Spatial).y + 50)
				{
					repositionPower(_group.getEntityById("multiplierpower"),new Spatial(_group.shellApi.viewportWidth*2,_group.shellApi.viewportWidth*-2),new Spatial(0,0));
					trace("set points power true");
					_canMakeMultiplierPower = true;
				}
			}
		}
		private function stageWon():void
		{
			_currentStage++;
			if(_container["stage" + _currentStage.toString()] != null)
			{
				//another stage found
				BounceMasterGroup(_group).setupStage(_container,"stage" + _currentStage,stageSetupCallback);
			}
			else
				_game.winGame();
		}
		private function stageSetupCallback():void
		{
			_restartText.text = "Stage " + _currentStage.toString();
			_restartText.setTextFormat(new TextFormat("Billy Serif",36,null,null,null,null,null,null,TextFormatAlign.CENTER));
			_restartText.autoSize = TextFieldAutoSize.CENTER;
			SceneUtil.addTimedEvent(_group,new TimedEvent(1,4,handleCountDown,true),"countdown");
			
		}
		private function loadBouncer():void
		{
			_group.shellApi.loadFile(_group.shellApi.assetPrefix + _bouncerAsset, bouncerLoaded);
		}
		private function repositionBouncer(bouncer:BouncerNode):void
		{
			_bouncerEntity = _group.getEntityById("bouncer");
			_bouncerEntity.get(Spatial).x = _group.shellApi.viewportWidth/2;
			_bouncerEntity.get(Spatial).y = _group.shellApi.viewportHeight/2;
			_bouncerEntity.get(Motion).velocity.x = 0;
			_bouncerEntity.get(Motion).velocity.y = 0;
		}
		private function repositionPower(entity:Entity, spatial:Spatial, motion:Spatial):void
		{
			entity.get(Spatial).x = spatial.x;
			entity.get(Spatial).y = spatial.y;
			entity.get(Motion).velocity.x = motion.x;
			entity.get(Motion).velocity.y = motion.y;
		}
		private function startBouncer():void
		{
			_bouncerEntity.get(Motion).velocity.x = Utils.randInRange(100, _game.speed);
			_bouncerEntity.get(Motion).velocity.y = _game.speed;
		}
		private function bouncerLoaded(clip:MovieClip, bounds:Rectangle):void
		{
			var x:Number = _group.shellApi.viewportWidth/2;
			var y:Number = _group.shellApi.viewportHeight/2;
			//var velX:Number = Utils.randInRange(100, 600);
			//var velY:Number = 300;
			//var ratio:Number = 2 - (1 - velX / 600);

			//clip.scaleX = clip.scaleY = ratio;
			
			//if(Math.random() > .5)
			//{
			//	x = _width;
			//	velX = -velX;
			//}
			
			_bouncerEntity = _creator.createBouncer(clip, x, y, 0, 0, bounds);
			
			_container.addChild(clip);
			
			_group.addEntity(_bouncerEntity);
			
			if(!_state.gameStarted)
			{
				_state.gameStarted = true;
				_firstBouncerLoading = false;
			}
		}
		
		private function bouncerCollision(bouncer1:Entity, bouncer2:Entity, minDistance:Number):void
		{
			var motion1:Motion = bouncer1.get(Motion);
			var motion2:Motion = bouncer2.get(Motion);
			var dx:Number = motion2.x - motion1.x;
			var dy:Number = motion2.y - motion1.y;
			var angle:Number = Math.atan2(dy, dx);
			var tx:Number = motion1.x + Math.cos(angle) * minDistance;
			var ty:Number = motion1.y + Math.sin(angle) * minDistance;
			var collisionSpring:Number = 1;
			var ax:Number = (tx - motion2.x) * collisionSpring;
			var ay:Number = (ty - motion2.y) * collisionSpring;

			motion1.velocity.x -= ax;
			motion1.velocity.y -= ay;
			motion2.velocity.x += ax;
			motion2.velocity.y += ay;
		}
		
		private var _gameStateNodes:NodeList;
		private var _bouncerNodes:NodeList;
		private var _group:Group;
		private var _creator:BounceMasterCreator;
		private var _container:DisplayObjectContainer;
		private var _bouncerAsset:String = "scenes/examples/standaloneMotion/ball2.swf";
		private var _width:Number;
		private var _height:Number;
		private var _state:BounceMasterGameState;
		private var _firstBouncerLoading:Boolean = false;
		private const HIT_WAIT:Number = .2;
		private const RESTART_WAIT:Number = 4;
		private var _restartText:TextField;
		private var _bouncerClip:MovieClip;
		private var _player:Entity;
		private var _playerClip:MovieClip;
		private var _currentStage:Number = 1;
		private var _game:BotBreakerGame;
		private var _lives:Number = 3;
		private var _bouncerEntity:Entity;
		
		//powers
		private var _numBallsActive:Number = 1;
		private var _canMakeMultiPower:Boolean = true;
		private var _canMakeMultiplierPower:Boolean = true;
		private var MULTIPLIER_TIME:Number = 10;
		private var _pointMultiplier:Number = 2;
	
	
	}
}