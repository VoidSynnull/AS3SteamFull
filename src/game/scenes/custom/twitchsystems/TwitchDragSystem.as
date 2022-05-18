package game.scenes.custom.twitchsystems {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.data.TimedEvent;
	import game.components.timeline.Timeline;
	import game.scenes.custom.TwitchGamePower;
	import game.scenes.custom.twitchcomponents.DraggableComponent;
	import game.scenes.custom.twitchnodes.TwitchDragNode;
	import game.systems.GameSystem;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	// This is for dragging something around on the screen.
	
	public class TwitchDragSystem extends GameSystem {
		
		// Only one entity is dragged at a time.
		private var _currentDrag:Entity;
		private var gameOver:Boolean = false;
		private var SCALE_LIMIT:Number = 0;
		private var SCALE_RATE_MIN:Number = 0;
		private var SCALE_RATE_MAX:Number = 0;
		private var DECAY_RATE:Number = 0;
		private var _yMin:Number = 0;
		private var _yMax:Number = 0;
		private var _score:Number = 0;
		private var _soundEffect:String;
		private var _boundsOffset:Number = 60;
		private var _bounce:Boolean;
		private var _bounceDirection:Number = 1;
		private var _bounceCounter:Number = 0;
		private var _scoreText:TextField;
		private var _timerText:TextField;
		
		private var _addTimer:Boolean = false;
		private var _warningTimer:Number = 0;
		private var _canPop:Boolean = true;
		private var _jumpTimer : uint;
		private var _replay:Boolean =false;
		private var _warningVisible:Boolean = false;
		private var _startReplay:Boolean = true;
		
		private var _time:Number;
		private var _TIMEOUT:Number = 120;
		private var _secs:Number;
		private var _resetScale:Boolean = false;
		private var _twitchGame:TwitchGamePower;
		public function TwitchDragSystem(scaleLimit:Number, scaleRateMin:Number, scaleRateMax:Number, decayRate:Number, yMin:Number, yMax:Number,
										 bounce:Boolean, timeOut:Number, textFormat:TextFormat, soundEffect:String, twitchGame:TwitchGamePower, replay:Boolean=false):void {
			SCALE_LIMIT = scaleLimit;
			SCALE_RATE_MIN = scaleRateMin;
			SCALE_RATE_MAX = scaleRateMax;
			DECAY_RATE = decayRate;
			_twitchGame = twitchGame;
			_soundEffect = soundEffect;
			_yMin = yMin;
			_yMax = yMax;
			_bounce = bounce;
			_TIMEOUT = timeOut;
			_replay = replay;
			_warningVisible = false;
			if(_replay == true)
			{
				_resetScale = true;
				_startReplay = false;
				SceneUtil.addTimedEvent(_twitchGame.groupEntity.group,  new TimedEvent( 1, 1, setStartReplay ));
			}
			if(timeOut > 0)
				_addTimer = true;
			
			_twitchGame.screen.content.warning.visible = false;
			_twitchGame.screen.content.gameStartScreen.visible = false;
			_twitchGame.screen.content.gameOverScreen.visible = false;
			_twitchGame.screen.content.gameWinScreen.visible = false;
			gameOver = false;
			if(_addTimer)
			{
				_scoreText = twitchGame.screen.content.HUD.score;
				
				_timerText = twitchGame.screen.content.HUD.timer;

				startTimer();
				_timerText.addEventListener(Event.ENTER_FRAME,fnTimer);
			}
			super( TwitchDragNode, updateNode, nodeAdded, nodeRemoved );
		}
		
		private function setStartReplay():void
		{
			_startReplay = true;
		}
		
		private function setJump(node:TwitchDragNode):void
		{
			node.draggable.canJump = true;
			node.draggable.canSetTimeout = true;
			clearTimeout(_jumpTimer);
		}
		
		private function updateNode( node:TwitchDragNode, time:Number ):void
		{
			if(!gameOver)
			{
				if(_startReplay)
				{
					var clip:MovieClip = node.display.displayObject as MovieClip;
					var draggable:DraggableComponent = node.draggable;
					if ( node.entity != _currentDrag ) {
						if(draggable.firstTouch == true)
						{
							if(node.display.visible == true)
							{
								
								if(node.draggable.resetScale == true)
								{
									node.spatial.scaleX = 0;
									node.spatial.scaleY = 0;
									node.draggable.resetScale = false;
								}
								if(node.draggable.speedy == true)
								{
									if(node.display.container)
										node.display.container.setChildIndex(node.display.displayObject,3);
								}
								node.spatial.scaleX += (node.draggable.scaleRate * time);
								node.spatial.scaleY += (node.draggable.scaleRate * time);
								if(node.draggable.jumper == true)
								{
									if(node.draggable.canJump == false && node.draggable.canSetTimeout == true)
									{
										_jumpTimer = setTimeout( setJump, 2500, node);
										node.draggable.canSetTimeout = false;
									}
									if(node.draggable.canJump)
									{
										TweenUtils.entityTo(node.entity,Spatial, 2.5, {x:randomMinMax( draggable.bounds.left + 100, draggable.bounds.right - 100 ), y:randomMinMax(_yMin,_yMax )});
										node.draggable.canJump = false;
									}
								}
							}
							if(_bounce)
								doBounce(node);
							checkScale(node);
							checkEnabled(draggable, clip, node);
						}
						if(draggable.firstTouch == false )
						{
							clip.endAni.visible = true;
							if(clip.main)
								clip.main.visible = false;
							if(draggable.playEndAnimation)
							{
								clip.endAni.gotoAndPlay(1);
								draggable.playEndAnimation = false; //reset to avoid constant looping
							}
							draggable.timeline.gotoAndStop("lastFrame");
							
							if(clip.endAni.currentFrame >= getFrameByLabel(clip.endAni,"lastAniFrame"))
							{
								clip.endAni.gotoAndStop("lastAniFrame");
							}
							decay(node, draggable, time);
						}
						else
						{
							clip.endAni.visible = false;
							if(clip.main)
								clip.main.visible = true;
							clip.endAni.gotoAndStop(1);
						}
						doEffects(time);
						
						_scoreText.text = _score.toString();
						return;
					}
				}
			}
			else
			{
				node.draggable.resetScale = true;
				node.display.visible = false;
				node.spatial.scaleX = 0;
				node.spatial.scaleY = 0;
			}
		} 
		
		private function showPopEffect(inX:Number, inY:Number):void
		{
			_twitchGame.screen.content.popEffect.visible = true;
			_twitchGame.screen.content.popEffect.alpha = 1;
			_twitchGame.screen.content.popEffect.x = inX;
			_twitchGame.screen.content.popEffect.y = inY - 20;
		}
		
		private function doBounce(node:TwitchDragNode):void
		{
			_bounceCounter++;
			node.spatial.y += _bounceDirection;
			if(_bounceCounter > 100)
			{
				_bounceDirection *= -1;
				_bounceCounter = 0;
			}	
		}
		
		private function doEffects(time:Number):void
		{
			if(_twitchGame.screen.content.popEffect.visible == true)
			{
				_twitchGame.screen.content.popEffect.y -= (20 * time);
				_twitchGame.screen.content.popEffect.alpha -= (0.2 * time);
				if(_twitchGame.screen.content.popEffect.alpha <= 0)
					_twitchGame.screen.content.popEffect.visible = false;
			}
		}
		
		private function checkEnabled(draggable:DraggableComponent, clip:MovieClip, node:TwitchDragNode):void
		{
			if(draggable.shouldShow == false)
			{
				node.display.visible = false;
				clip.scaleX = node.spatial.scaleX = 0;
				clip.scaleY = node.spatial.scaleY = 0;
				
				if(Math.random() < .01)
				{
					if(_yMin != 0 && _yMax != 0)
					{
						node.spatial.x = randomMinMax(draggable.bounds.left + 100, draggable.bounds.right - 100);
						node.spatial.y = randomMinMax(_yMax, _yMin); 
					}
					else
					{
						node.spatial.x = randomMinMax(draggable.bounds.left + 100, draggable.bounds.right - 100);
						node.spatial.y = randomMinMax(draggable.bounds.top + 100, draggable.bounds.bottom - 100); 
					}
					node.display.alpha = 1.0;
					if(node.display.container)
						node.display.container.setChildIndex(node.display.displayObject,3);
					draggable.shouldShow = true;
				}
			}
			else
			{
				node.display.visible = true;
			}
			
			// loop animation
			var timeline:Timeline = draggable.timeline;
			if((timeline.currentIndex >= timeline.totalFrames-2) && (draggable.firstTouch) && (!gameOver))
			{
				timeline.gotoAndPlay(0);
			}
		}
		
		private function getFrameByLabel( clip:MovieClip, frameLabel: String ):int
		{
			var scene:Scene = clip.currentScene;
			
			var frameNumber:int = -1;
			
			for( var i:int ; i < scene.labels.length ; ++i )
			{
				if( scene.labels[i].name == frameLabel )
					frameNumber = scene.labels[i].frame;
			}
			
			return frameNumber;
		}
		
		private function nodeAdded( node:TwitchDragNode ):void
		{
			InteractionCreator.addToComponent( node.display.displayObject, [ InteractionCreator.DOWN, InteractionCreator.UP ], node.interaction );
			
			node.interaction.down.add( this.mouseDown );
			
			node.draggable.onStartDrag = new Signal( Entity );
			node.draggable.onDrag = new Signal( Entity, Number );
			node.draggable.onEndDrag = new Signal( Entity );
			
			var display:DisplayObjectContainer = node.display.displayObject;
		} 
		
		private function mouseDown( e:Entity ):void {
			
			var draggable:DraggableComponent = e.get( DraggableComponent );
			
			if ( draggable.enabled && draggable.firstTouch == true && !gameOver && _canPop)
			{
				showPopEffect(e.get( Spatial).x, e.get( Spatial).y);
				if(_soundEffect != null)
					AudioUtils.play(_twitchGame.groupEntity.group, SoundManager.EFFECTS_PATH + _soundEffect, 1.5, false);
				draggable.firstTouch = false;
				//set to play pop ani
				draggable.playEndAnimation = true;
				_score += 10;
			}
		}
		
		private function checkScale(node:TwitchDragNode):void
		{
			if(node.spatial.scaleX >= SCALE_LIMIT)
			{
				_warningVisible = true;
				_canPop = false;
				_twitchGame.screen.content.warning.visible = true;
				_warningTimer++;
				if(_warningTimer > 100)
				{
					setGameOver();
					_warningTimer = 0;
				}
				
				if(gameOver)
				{
					if(!_twitchGame.loadedCloseButton)
						_twitchGame.loadClose(_score, false, false);
					else if(_replay)
						_twitchGame.loadClose(_score, false, true);
					stopTimer();
				}	
			}
		}
		
		private function setGameOver():void
		{
			gameOver = true;
		}
		
		private function decay(node:TwitchDragNode, draggable:DraggableComponent, time:Number):void
		{
			node.display.alpha -= (DECAY_RATE * time);
			if(node.display.alpha <= 0)
			{
				draggable.shouldShow = false;
				draggable.firstTouch = true;
			}
		}
		
		private function nodeRemoved( node:TwitchDragNode ):void
		{
			node.draggable.onStartDrag.removeAll();
			node.draggable.onDrag.removeAll();
			node.draggable.onEndDrag.removeAll();
		}
		
		private function randomMinMax( min:Number, max:Number ):Number
		{
			return min + (max - min) * Math.random();
		}
		
		private function startTimer():void
		{
			_time = getTimer();
			_secs = _TIMEOUT / 1000;
		}
		
		private function fnTimer(e:Event):void
		{
			if(_startReplay)
			{
				var vSecs:Number = Math.floor(_TIMEOUT - (getTimer() - _time) / 1000);
				if (vSecs != _secs)
				{
					_secs = vSecs;
					fnShowTime();
					if (vSecs == 0 && !_warningVisible)
					{
						if(_replay)
							_twitchGame.loadClose(_score, true, true);
						else
							_twitchGame.loadClose(_score, true, false);
						gameOver = true;
						stopTimer();
					}
					
				}
			}
		}
		
		private function fnShowTime():void
		{
			var vMins:Number = Math.floor(_secs / 60);
			var vLeft:Number = _secs - vMins * 60;
			var vDigits:String = "0";
			if (vLeft < 10)
			{
				vDigits += String(vLeft);
			}
			else
			{
				vDigits = String(vLeft);
				
			}
			_timerText.text = String(vMins) + ":" + vDigits;
		}
		
		public function stopTimer():void
		{
			if(_timerText)
			{
				_timerText.removeEventListener(Event.ENTER_FRAME, fnTimer);
			}
		}
	}
}