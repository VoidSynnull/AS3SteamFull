package game.ui.popup
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.data.animation.Animation;
	import game.ui.hud.Hud;
	import game.ui.popup.Popup;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class CardPopupPower extends Popup
	{
		public function CardPopupPower()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = false;
			// RLH: hide inventory
			Popup(super.shellApi.groupManager.getGroupById('inventory')).hide(true);
			// hide hud's dimmed background
			Hud(super.getGroupById(Hud.GROUP_ID)).hideDarken(true);
			
			super.groupPrefix = "";
			super.init(container);
			load();
		}		
				
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array(super.data.swfPath));
		}
		
		// all assets ready
		override public function loaded():void
		{			
	 		super.screen = super.getAsset(super.data.swfPath, true) as MovieClip;
			
			// this converts the content clip for AS3
			// NOTE: if the animation instance is not named "content" then you will get an error here!!!!
			var vTimeline:Entity = TimelineUtils.convertClip(super.screen.content, super);
			TimelineUtils.onLabel( vTimeline, Animation.LABEL_ENDING, super.endPopupAnim );
			
			// position popup
			if ((!isNaN(super.data.offsetX)) && (!isNaN(super.data.offsetY)))
			{
				var playerX:Number = super.shellApi.offsetX(super.shellApi.player.get(Spatial).x);
				var playerY:Number = super.shellApi.offsetY(super.shellApi.player.get(Spatial).y);
				
				if (super.data.alignDirection)
				{
					// if facing left
					if (super.shellApi.player.get(Spatial).scaleX > 0)
						super.screen.content.x = playerX - super.data.offsetX;
					else
						super.screen.content.x = playerX + super.data.offsetX;
				}
				else
				{
					super.screen.content.x = playerX + super.data.offsetX;
				}
				super.screen.content.y = playerY + super.data.offsetY;
			}

			// disable user input
			SceneUtil.lockInput(super, true);
			
			super.loaded();
		}
	}
}
