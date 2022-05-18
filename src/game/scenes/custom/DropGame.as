package game.scenes.custom
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.managers.ads.AdManager;
	import game.scenes.virusHunter.condoInterior.classes.PopupDragItem;
	import game.systems.SystemPriorities;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.MovieClipHitSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class DropGame extends AdGamePopup
	{
		
		private var content:MovieClip;
		private var lives:int;
		private var life:int = 0;
		private var hud:Timeline;
		private var _score:TextField;
		private var _requirementText:TextField;
		private var _requirementClip:Timeline;
		private var hitSounds:Dictionary;
		private var _wrongChoiceAnimation:Entity;
		private var _gameObject1:MovieClip;
		private var _gameObject2:MovieClip;
		private var _gameObjects:Array;
		private var _REQUIREDNUMTOSORT:Number;
		private var _zone1:Entity;
		private var _zone2:Entity;
		private var _animatingEntity1:Timeline;
		private var _animatingEntity2:Timeline;
		private var _currentObject:PopupDragItem;
		private var _points:Number;
		private var _currentPoints:Number = 0;
		private var _time:Number;
		private var _TIMEOUT:Number = 120;
		private var _secs:Number;
		private var _progressBar:MovieClip;
		private var _currSorted:Number = 0;
		private var _dropPos:String = "0";
		
		
		public function DropGame()
		{
			super();
		}
		override protected virtual function parseXML(xml:XML):void
		{
			super.parseXML(xml);
			
			if(xml.hasOwnProperty("sounds"))
			{
				setUpHitSounds(xml.sounds);
			}
			if(xml.hasOwnProperty("numToSort"))
			{
				_REQUIREDNUMTOSORT = xml.numToSort;
			}
			if(xml.hasOwnProperty("points"))
			{
				_points = xml.points;
			}
			if(xml.hasOwnProperty("timeout"))
			{
				_TIMEOUT = xml.timeout;
			}
			if(xml.hasOwnProperty("dropPos"))
			{
				_dropPos = xml.dropPos;
			}
			
		}
		private function setUpHitSounds(xml:XMLList):void
		{
			hitSounds = new Dictionary();
			for(var i:int = 0; i < xml.children().length(); i++)
			{
				var sound:XML = xml.children()[i];
				var hitId:String = DataUtils.getString(sound.attribute("id")[0]);
				if(hitId != null)
					hitSounds[hitId] = DataUtils.getString(sound);
			}
		}	
		override protected virtual function loadedSwf(clip:MovieClip):void
		{
			// save clip to screen
			super.screen = clip;
			autoOpen = false;
			super.preparePopup();
			super.centerPopupToDevice();
			content = screen.content;
			content.x -= shellApi.viewportWidth/2;
			content.y -= shellApi.viewportHeight/2;
			
			// play music
			if (_musicFile != null)
			{
				AdManager(super.shellApi.adManager).playCampaignMusic(_musicFile);
			}
			initializeGame();
		}
		private function initializeGame():void
		{
			var gameName:String = _swfName.substring(1, _swfName.indexOf(".swf"));
			var motionUrl:String = xmlPath.replace(gameName, "motionMaster");
			var segmentsUrl:String = xmlPath.replace(gameName, "segmentPatterns");
			_gameObjects = new Array();
			this.addSystem(new DropGameSystem(), SystemPriorities.update );
			SetUpGame();
		}
		private function SetUpGame():void
		{
			var clip:MovieClip = content["progress"];
			if (clip)
			{
				var child:MovieClip = clip["progress"];
				var mask:MovieClip = clip["mask"];
				if(child && mask)
				{
					child.mask = mask;
					clip = mask;
				}
				_progressBar = clip;
				startTimer();
				_progressBar.addEventListener(Event.ENTER_FRAME,fnTimer);
			}
			var text:TextField = content["score"];
			if (text)
			{
				_score = text;
			}
			text = content["requirementText"];
			if (text)
			{
				_requirementText = text;
			}
			clip = content["requirementClip"];
			if(clip)
			{
				var require:Entity = TimelineUtils.convertClip(clip, this,require, null, false);
				_requirementClip = require.get(Timeline);
			}
			clip = content["hud"];
			if(clip)
			{
				var entity:Entity = TimelineUtils.convertClip(clip, this,entity, null, false);
				lives = clip.totalFrames -1;
				hud = entity.get(Timeline);
			}
			
			clip = content["wrong"];
			if(clip)
			{
				_wrongChoiceAnimation = EntityUtils.createSpatialEntity(this, clip);
				TimelineUtils.convertClip(clip, this, _wrongChoiceAnimation, null, false);
				TimelineUtils.onLabel(_wrongChoiceAnimation,"end",EndWrongAnimation,false);
				_wrongChoiceAnimation.get(Display).visible = false;
			}
			var _movieclips:Array = new Array();
			clip = content["object1"];
			if(clip)
				_movieclips.push(clip);
			clip = content["object2"];
			if(clip)
				_movieclips.push(clip);
			clip = content["zone1"];
			if(clip)
			{
				_zone1 = EntityUtils.createSpatialEntity(this, clip, content);
			}
			clip = content["zone2"];
			if(clip)
			{
				_zone2 = EntityUtils.createSpatialEntity(this, clip, content);
			}
			clip = content["animation1"];
			if(clip)
			{
				var ani1:Entity = TimelineUtils.convertClip(clip, this,ani1, null, false);
				_animatingEntity1 = ani1.get(Timeline);
				_animatingEntity1.handleLabel("goIdle",GoToIdle1,false);
				_animatingEntity1.play();
			}
			clip = content["animation2"];
			if(clip)
			{
				var ani2:Entity = TimelineUtils.convertClip(clip, this,ani2, null, false);
				_animatingEntity2 = ani2.get(Timeline);
				_animatingEntity2.handleLabel("goIdle",GoToIdle2,false);
				_animatingEntity1.play();
			}
			for(var i:Number=0;i<_movieclips.length;i++)
			{
				var dragItem:PopupDragItem = new PopupDragItem( this, _movieclips[i] );
				dragItem.draggable.onEndDrag.add( this.doDrag );
				dragItem.entity.add(new Id((i+1).toString()));
				_gameObjects.push(dragItem);
				dragItem.entity.get(Spatial).x=shellApi.viewportWidth/2;
			}
			nextObject(_gameObjects,-1);
			
			// create the collider for the player, making sure that its the same
			// no matter what ridiculous costume they may be wearing... antman cough cough
			clip = new MovieClip();
			clip.graphics.beginFill(0,0);
			clip.graphics.drawCircle(0,-10,35);
			clip.graphics.endFill();
			var hit:Entity = EntityUtils.createSpatialEntity(this, clip, content);
			
			// adding necesary systems
			if(getSystem(FollowTargetSystem) == null)
				addSystem(new FollowTargetSystem());
			if(getSystem(HitTestSystem) == null)
				addSystem(new HitTestSystem());
			if(getSystem(MovieClipHitSystem) == null)
				addSystem(new MovieClipHitSystem());
			
			finalizeGame();
		}
		private function GoToIdle1():void
		{
			_animatingEntity1.gotoAndPlay("idle");
		}
		private function GoToIdle2():void
		{
			_animatingEntity2.gotoAndPlay("idle");
		}
		private function EndWrongAnimation():void
		{
			var timeline:Timeline = _wrongChoiceAnimation.get(Timeline);
			timeline.stop();
			timeline.gotoAndStop(1);
			_wrongChoiceAnimation.get(Display).visible = false;
		}
		private function randomMinMax( minNum:Number, maxNum:Number ):Number
		{
			return (Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum);
		}
		private function HandleObject(object:Entity):void
		{
			_currentObject.draggable.stopDrag();
			_currentObject.draggable.disable();
			object.get(Spatial).x = shellApi.viewportWidth/2;
			object.get(Spatial).y = -125;
			_currentObject.draggable.enable();
			nextObject(_gameObjects,randomMinMax(-1,0));
		}
		private function IncorrectChoice(object:Entity):void
		{
			_wrongChoiceAnimation.get(Display).visible = true;
			_wrongChoiceAnimation.get(Spatial).x = object.get(Spatial).x;
			_wrongChoiceAnimation.get(Spatial).y = object.get(Spatial).y;
			_wrongChoiceAnimation.get(Timeline).play();
			HandleObject(object);
			
			if(life >= lives)
			{
				EndGame(false);
			}
			else
			{
				life++;
				if(hud)
					hud.gotoAndStop(life);
			}
		}
		private function CorrectChoice(object:Entity, id:String):void
		{
			HandleObject(object);
			_currSorted++;
			if(_requirementText)
				_requirementText.text = _currSorted.toString() + "/" + _REQUIREDNUMTOSORT.toString();
			if(_requirementClip && _currSorted >= _REQUIREDNUMTOSORT)
				_requirementClip.gotoAndStop(1);
			_currentPoints += _points;
			if(_score)
				_score.text = _currentPoints.toString();
			if(id == "1")
				_animatingEntity1.gotoAndPlay("action");
			else
				_animatingEntity2.gotoAndPlay("action");
		}
		private function doDrag( e:Entity ):void {
			if(_currentObject.draggable.enabled)
			{
				if(EntityUtils.distanceBetween(e,_zone1) < 100)
				{
					if(e.get(Id).id == "1")
						CorrectChoice(e,"1");
					else
						IncorrectChoice(e);
				}
				else if(EntityUtils.distanceBetween(e,_zone2) < 100)
				{
					if(e.get(Id).id == "2")
						CorrectChoice(e,"2");
					else
						IncorrectChoice(e);
				}
			}	
		} 
		private function sendToStartingPos(clip:MovieClip):void
		{
			clip.x = 600;
			clip.y = -250;
		}
		private function nextObject(arr:Array,curr:Number):void
		{	
			_currentObject = arr[curr+1];
			var str:String 
			if(_dropPos != "0")
				str = _dropPos;
			else
				str = (shellApi.viewportWidth/2).toString();
			var drag:Entity =  arr[curr+1].entity;
			TweenUtils.entityTo( drag, Spatial, .2,{y:str});
		}
		override protected function finalizeGame(...args):void
		{
			open(super.groupReady);
		}
		
		private function onHit(entity:Entity, id:String):void
		{
			var hit:Entity = getEntityById(id);
			Timeline(hit.get(Timeline)).gotoAndPlay("hit");
			
			if(hitSounds.hasOwnProperty(id))
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + hitSounds[id]);
			}
			else
			{
				//check to see if the id derives from any of the keys
				for(var key:String in hitSounds)
				{
					if(id.indexOf(key) >= 0)
					{
						AudioUtils.play(this, SoundManager.EFFECTS_PATH + hitSounds[key]);
						break;
					}
				}
			}
		}
		
		private function resume():void
		{
			if(life >= lives)
			{
				EndGame(false);
			}
			else
			{
				life++;
				if(hud)
					hud.gotoAndStop(life);
			}
			
		}
		private function EndGame(win:Boolean):void
		{
			if(_progressBar)
				StopTimer();
			close();
			if(win)
				winGame();
			else
				gameOver();
		}
		private function startTimer():void
		{
			_time = getTimer();
			_secs = _TIMEOUT / 1000;
		}
		
		private function fnTimer(e:Event):void
		{
			var vSecs:Number = Math.floor(_TIMEOUT - (getTimer() - _time) / 1000);
			if (vSecs != _secs)
			{
				_secs = vSecs;
				
				_progressBar.scaleX = (vSecs / _TIMEOUT);
				if (vSecs == 0 )
				{
					if(_currSorted >= _REQUIREDNUMTOSORT)
						EndGame(true)
					else
						EndGame(false);
				}
			}
		}
		public function StopTimer():void
		{
			_progressBar.removeEventListener(Event.ENTER_FRAME, fnTimer);
			
		}
	}
}