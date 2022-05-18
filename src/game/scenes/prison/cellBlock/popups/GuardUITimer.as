package game.scenes.prison.cellBlock.popups
{
	import com.greensock.TweenMax;
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.UIView;
	
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class GuardUITimer extends UIView
	{
		public function GuardUITimer(container:DisplayObjectContainer)
		{
			super(container);
			this.id = GROUP_ID;		
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			this.groupPrefix = "scenes/prison/cellBlock/popups/";
			this.screenAsset = "guardUI.swf";
			
			super.init(container);
			this.load();
			
			completed = new Signal();
		}
		
		override public function destroy():void
		{
			if(completed)
			{
				completed.removeAll();
				completed = null;
			}
			
			super.destroy();
		}
		
		override public function loaded():void
		{		
			super.loaded();
			
			groupEntity.ignoreGroupPause = true;
			screen.x = shellApi.viewportWidth*.5 - screen.width*.5;
			_guard = EntityUtils.createSpatialEntity(this, screen.guard);
			_guard = TimelineUtils.convertClip(screen.guard, this, _guard, null, true, FRAME_RATE);
			
			_guardBack = EntityUtils.createSpatialEntity(this, screen.guard_back);
			_guardBack = TimelineUtils.convertClip(screen.guard_back, this, _guardBack, null, false, FRAME_RATE);
			_guardBack.get(Display).visible = false;
			
			var timeline:Timeline = _guard.get(Timeline);
			timeline.gotoAndPlay(0);
			timeline.handleLabel("halfway", madeHalfway);
		}
		
		public function fadeOut():void
		{
			if(!_fadingOut)
			{
				_fadingOut = true;
				_currentTween = TweenUtils.globalTo(this, screen, .75, {alpha: 0, onComplete:fadedOut});
			}			
			
			if(fadeInTimer)
			{
				fadeInTimer.stop();
				fadeInTimer = null;
			}
		}
		
		private function fadedOut():void
		{
			_fadingOut = false;
		}
		
		public function fadeIn():void
		{
			_currentTween = TweenUtils.globalTo(this, screen, .75, {alpha:1});
		}
		
		public function showFull():void
		{
			fadeIn();
			screen.alpha = 1;
		}
		
		private function madeHalfway():void
		{
			SceneUtil.delay(this, WAIT_TIME, goBack);
		}
		
		private function goBack():void
		{
			_guardBack.get(Display).visible = true;
			_guard.get(Display).visible = false;
			
			var timeline:Timeline = _guardBack.get(Timeline);
			timeline.play();
			timeline.handleLabel("atCell", guardDone);
			timeline.handleLabel("ending", end);
		}
		
		private function guardDone():void
		{
			guardBack = true;
			completed.dispatch();
		}
		
		private function end():void
		{
			parent.removeGroup(this);
		}

		public static const GROUP_ID:String = "guardUI_group";
		private const FRAME_RATE:Number = 4;
		private const WAIT_TIME:Number = 3;
		
		private var _guard:Entity;
		private var _guardBack:Entity;
		private var _fadingOut:Boolean = false;
		private var _currentTween:TweenMax;
		
		public var fadeInTimer:TimedEvent;
		public var guardBack:Boolean = false;
		public var completed:Signal;
	}
}