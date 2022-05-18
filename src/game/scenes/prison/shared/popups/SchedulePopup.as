package game.scenes.prison.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.group.Scene;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.managers.ads.AdManager;
	import game.scenes.prison.PrisonEvents;
	import game.scenes.prison.adMixed2.AdMixed2;
	import game.scenes.prison.adStreet3.AdStreet3;
	import game.scenes.prison.cellBlock.CellBlock;
	import game.scenes.prison.messHall.MessHall;
	import game.scenes.prison.metalShop.MetalShop;
	import game.scenes.prison.yard.Yard;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	
	public class SchedulePopup extends Popup
	{
		public function SchedulePopup(container:DisplayObjectContainer=null, currentScene:Scene = null)
		{
			super(container);
			_currentScene = currentScene;
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.groupPrefix = "scenes/prison/shared/popups/";
			this.pauseParent = true;
			this.darkenBackground = true;
			this.darkenAlpha = .75;
			this.autoOpen = true;
			
			load();
		}
		
		override public function load():void
		{
			_currentDay = shellApi.getUserField(_prisonEvents.DAYS_IN_PRISON_FIELD, shellApi.island);
			if(!_currentDay || _currentDay == "NaN") _currentDay = "1";
			
			this.loadFiles(["schedulePopup.swf"], false, true, loaded);
		}
		
		override public function loaded():void
		{
			this.screen = getAsset("schedulePopup.swf", true) as MovieClip;
			this.letterbox(screen.content, new Rectangle(0, 0, 397, 415), false);
			
			setupDayText();
			setupXs();
			
			SceneUtil.lockInput(this, true);
			SceneUtil.delay(this, 1, showX);
			SceneUtil.delay(this, 4, nextScene);
			super.loaded();
		}
		
		private function nextScene():void
		{
			shellApi.loadScene(_nextScene, NaN, NaN, null, 2, 3);
		}
		
		private function showX():void
		{
			_currentX.gotoAndPlay("marking");
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "draw_on_paper_02.mp3");
		}
		
		private function setupDayText():void
		{
			var textfield:TextField = new TextField();
			textfield.defaultTextFormat = TEXT_FORMAT;
			textfield.wordWrap = false;
			textfield.multiline = false;
			textfield.embedFonts = true;
			textfield.width = screen.content.dayLoc.width;
			textfield.height = screen.content.dayLoc.height;
			textfield.text = _currentDay;			
			screen.content.dayLoc.addChild(textfield);
		}	
		
		private function setupXs():void
		{
			var _numToSetup:Number = 0;
			var adManager:AdManager = shellApi.adManager as AdManager;
			var noAd:Boolean = AdUtils.noAds(this);
			if(_currentScene is Yard)
			{
				_numToSetup=1;
				_nextScene = MetalShop;
			}
			else if(_currentScene is MetalShop)
			{
				_numToSetup=2;
				_nextScene = MessHall;
			}
			else if(_currentScene is MessHall)
			{
				_numToSetup=3;
				if(noAd)
					_nextScene = CellBlock;
				else
					_nextScene = AdStreet3;
			}
			else if(_currentScene is CellBlock)
			{
				_numToSetup=4;
				if(noAd)
					_nextScene = Yard;
				else
					_nextScene = AdMixed2;
			}
			
			for(var i:int = 0; i < 4; i++)
			{
				if(i+1 < _numToSetup)
				{
					MovieClip(screen.content["x"+i]).gotoAndStop("stable");
				}
				else if(i+1 == _numToSetup)
				{
					var entity:Entity = TimelineUtils.convertClip(screen.content["x"+i], this);
					_currentX = entity.get(Timeline);
					_currentX.gotoAndStop("blank");
				}
				else
				{
					screen.content.removeChild(screen.content["x"+i]);
				}
			}
		}
		
		private const TEXT_FORMAT:TextFormat = new TextFormat("Chaparral Pro", 24, 0x44412A, null, null, null, null, null, "center");
		private var _prisonEvents:PrisonEvents;
		private var _currentScene:Scene;
		private var _nextScene:*;
		private var _currentDay:String;
		private var _currentX:Timeline;
	}
}