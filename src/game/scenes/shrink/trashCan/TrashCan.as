package game.scenes.shrink.trashCan
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.motion.FollowTarget;
	import game.creators.ui.ButtonCreator;
	import game.data.ui.ToolTipType;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.shared.groups.ShrinkScene;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class TrashCan extends ShrinkScene
	{		
		public function TrashCan()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/trashCan/";
			
			super.init(container);
		}
		
		private var shrink:ShrinkEvents;
		
		private var cameraTarget:Entity;
		
		private const EYE:String = "eye.swf";
		private const RESTART_BUTTON:String = "restart.swf";
		
		private function setUpEye():void
		{
			var clip:MovieClip = getAsset(EYE);
			clip.x = clip.width;
			clip.y = shellApi.viewportHeight - clip.height;
			var eye:Entity = ButtonCreator.createButtonEntity(clip, this, clickEye, overlayContainer, null, null, null, true);
			cameraTarget = EntityUtils.createSpatialEntity(this, new Sprite(), _hitContainer);
			cameraTarget.add(new FollowTarget(shellApi.inputEntity.get(Spatial), .1, true));
		}
		
		private var _lookingAround:Boolean = false;
		
		private function clickEye(eye:Entity):void
		{
			_lookingAround = !_lookingAround;
			followTarget(_lookingAround);
		}
		
		private function followTarget(follow:Boolean):void
		{
			if(follow)
			{
				CharUtils.lockControls(this.player, true, false);
				this.shellApi.defaultCursor = ToolTipType.TARGET;
				SceneUtil.setCameraTarget(this,cameraTarget);
			}
			else
			{
				CharUtils.lockControls(this.player, false, false);
				this.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
				SceneUtil.setCameraTarget(this, player);
			}
		}
		
		// all assets ready
		override public function loaded():void
		{
			shrink = events as ShrinkEvents;
			
			addChildGroup(new TrashGroup(_hitContainer, this));
			setUpEye();
			setUpRestartButton();
			getEntityById("block4").remove(Sleep);
			super.loaded();
		}
		
		private function setUpRestartButton():void
		{
			var clip:MovieClip = getAsset(RESTART_BUTTON);
			clip.x = clip.width + 25;
			clip.y = shellApi.viewportHeight - clip.height;
			var restartButton:Entity = ButtonCreator.createButtonEntity(clip, this, restart, overlayContainer, null, null, true, true);
		}
		
		private function restart(entity):void
		{
			shellApi.loadScene(TrashCan);
		}
	}
}