package game.systems.actionChain.actions
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.data.animation.Animation;
	import game.managers.ScreenManager;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.SceneUIGroup;
	import game.systems.actionChain.ActionCommand;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;

	/**
	 * Display overlay animation over current scene
	 */
	public class ShowOverlayAnimAction extends ActionCommand
	{
		private var swfPath:String;
		private var scaleMode:String;
		
		private var _popupClip:MovieClip;
		private var _popupClipEntity:Entity;
		private var _group:Group;
		private var _callback:Function;
		private var _sceneUIGroup:SceneUIGroup;
		
		/**
		 * Display overlay animation over current scene
		 * @param swfPath		Path to swf overlay animation
		 */
		public function ShowOverlayAnimAction(swfPath:String, scaleMode:String = null)
		{
			this.swfPath = swfPath;
			this.scaleMode = scaleMode;
		}

		override public function preExecute(callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			// if clip path
			if (swfPath)
			{
				_callback = callback;
				_group = group;
				
				// load swf
				group.shellApi.loadFile(group.shellApi.assetPrefix + swfPath, loadPopupComplete);
			}
		}
		
		/**
		 * When swf loaded 
		 * @param clip
		 */
		private function loadPopupComplete(clip:MovieClip):void
		{
			// return if no clip
			if (clip == null)
			{
				_callback();
				return;
			}
			
			// remember clip
			_popupClip = clip;
			
			// Add the movieClip to scene
			_sceneUIGroup = _group.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
			_sceneUIGroup.container.addChild(clip);
			
			// Create the new entity and set the display and spatial
			_popupClipEntity = new Entity();
			_popupClipEntity.add(new Display(clip, _sceneUIGroup.container));
			
			var x:Number = 0;
			var y:Number = 0;
			var scale:Number = 1;
			
			// add to scene
			_group.addEntity(_popupClipEntity);
			
			// this converts the content clip for AS3
			var timeline:Entity = TimelineUtils.convertClip(clip.content, _group);
			TimelineUtils.onLabel( timeline, Animation.LABEL_ENDING, endPopupAnim );
			
			// if scale to fill
			if (scaleMode == "scaleToFill")
			{
				// target proportions for device
				var targetProportions:Number = _group.shellApi.viewportWidth/_group.shellApi.viewportHeight;
				var destProportions:Number = ScreenManager.GAME_WIDTH/ScreenManager.GAME_HEIGHT;
				// if narrower, then fit to width and center vertically
				if (destProportions <= targetProportions)
				{
					scale = _group.shellApi.viewportWidth/ScreenManager.GAME_WIDTH;
				}
				else
				{
					// else fit to height and center horizontally
					scale = _group.shellApi.viewportHeight/ScreenManager.GAME_HEIGHT;
				}
				x = _group.shellApi.viewportWidth / 2 - ScreenManager.GAME_WIDTH * scale / 2;
				y = _group.shellApi.viewportHeight / 2 - ScreenManager.GAME_HEIGHT * scale/ 2;
			}
			else if(scaleMode == "player")
			{
				var ref:DisplayObject = EntityUtils.getDisplayObject(_group.shellApi.player);
				var p:Point = DisplayUtils.localToLocal(ref, _sceneUIGroup.container);
				x = p.x;
				y = p.y;
			}
			// apply to spatial
			var clipSpatial:Spatial = new Spatial(x, y);
			clipSpatial.scaleX = clipSpatial.scaleY = scale;
			_popupClipEntity.add(clipSpatial);
		}
		
		/**
		 * When animation done 
\		 */
		private function endPopupAnim():void
		{
			// remove popup
			_sceneUIGroup.container.removeChild(_popupClip);
			_group.removeEntity(_popupClipEntity);
			_popupClip = null;
			_popupClipEntity = null;
			
			// end action
			_callback();
		}
	}
}