// Used by:
// Card 3065
// This doesn't work on mobile because the action button becomes unclickable when the game is paused

package game.data.specialAbility.store 
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.data.specialAbility.SpecialAbility;
	import game.managers.ScreenManager;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.animation.FSMSystem;
	import game.systems.entity.EyeSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.TimelineUtils;

	/**
	 * Freeze or unfreeze game
	 */
	public class FreezeGame extends SpecialAbility
	{
		public var _swfPath:String;
		
		private var _popupClipEntity:Entity;
		private var _timeline:Entity;
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			// if wanting to freeze
			if ( !this.data.isActive )
			{
				this.setActive( true );
				
				// load popup if given
				if (_swfPath != null)
				{
					super.loadAsset(_swfPath, loadPopupComplete);
				}
				// else freeze
				else
				{
					freeze();
				}
			}
			// when unfreezing
			else
			{
				this.setActive( false );
				
				// finish popup animation
				Timeline(_timeline.get(Timeline)).gotoAndPlay("resume");
				
				// restore systems
				var scene:Scene = shellApi.currentScene;
				scene.addSystem( new FSMSystem());
				scene.addSystem( new EyeSystem());
				scene.addSystem( new TimelineControlSystem());
				
				// unpause
				shellApi.currentScene.unpause();
			}
		}
		
		/**
		 * when popup swf completes loading 
		 * @param clip
		 */
		protected function loadPopupComplete(clip:MovieClip):void
		{
			// return if no clip
			if (clip == null)
				return;
			
			// disable interaction
			clip.mouseChildren = clip.mouseEnabled = false;
			
			// Add the movieClip to scene
			var container:DisplayObjectContainer = shellApi.currentScene.overlayContainer;
			container.addChild(clip);
			
			// Create the new entity and set the display and spatial
			_popupClipEntity = new Entity();
			_popupClipEntity.add(new Display(clip, container));
			
			// scale to fit
			var x:Number = super.shellApi.viewportWidth/2;
			var y:Number = super.shellApi.viewportHeight/2;
			var clipSpatial:Spatial = new Spatial(x,y);
			clipSpatial.scaleX = shellApi.viewportWidth/ScreenManager.GAME_WIDTH;
			clipSpatial.scaleY = shellApi.viewportHeight/ScreenManager.GAME_HEIGHT;

			_popupClipEntity.add(clipSpatial);
			
			// add to scene
			super.group.addEntity(_popupClipEntity);
			
			// this converts the content clip for AS3
			_timeline = TimelineUtils.convertClip(clip.content, super.group);
			
			// label listeners
			TimelineUtils.onLabel( _timeline, "pause", pauseAnim );
			TimelineUtils.onLabel( _timeline, Animation.LABEL_ENDING, endPopupAnim );
		}
		
		/**
		 * When popup animation reaches pause 
		 */
		protected function pauseAnim():void
		{
			Timeline(_timeline.get(Timeline)).stop();
			freeze();
		}
		
		/**
		 * Freeze scene
		 */
		protected function freeze():void
		{
			var scene:Scene = shellApi.currentScene;
			// pause scene
			shellApi.currentScene.pause();
			// don't pause player or else keydown won't work
			shellApi.player.sleeping = false;
			shellApi.player.ignoreGroupPause = true;
			// remove player animation systems
			shellApi.currentScene.removeSystem(scene.getSystem(FSMSystem));
			shellApi.currentScene.removeSystem(scene.getSystem(EyeSystem));
			shellApi.currentScene.removeSystem(scene.getSystem(TimelineControlSystem));
		}
		
		/**
		 * When popup animation reaches end 
		 */
		protected function endPopupAnim():void
		{
			// remove popup
			removePopup();
		}
		
		/**
		 * Remove popup 
		 */
		private function removePopup():void
		{
			// remove popup
			super.group.removeEntity(_popupClipEntity);
			_popupClipEntity = null;
		}
	}
}
