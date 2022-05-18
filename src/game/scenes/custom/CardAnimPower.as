// used by the following cards: 2442, 2447, 2462, 2468, 2473, 2477, 2491, 2497, 2504, 2505, 2519, 2526, 2536, 2565, 2572, 2659

package game.scenes.custom
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
	
	/**
	 * Play popup animation from card 
	 * If you need more flexibility, use the PlayPopupAnim special ability (refer to card 2533 or 2583)
	 * 
	 * required params
	 * swfPath
	 * 
	 * optional params
	 * alignDirection
	 * offsetX
	 * offsetY
	 */
	public class CardAnimPower extends Popup
	{
		public function CardAnimPower()
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
			
			super.init(container);
			load();
		}		
				
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			shellApi.loadFile(shellApi.assetPrefix + super.data.swfPath, gotFile);
		}
		
		// when file loaded
		public function gotFile(clip:MovieClip):void
		{			
			if (clip == null)
			{
				trace("no asset loaded");
			}
			else
			{
		 		super.screen = clip;
				
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
			}
			
			super.loaded();
		}
	}
}
