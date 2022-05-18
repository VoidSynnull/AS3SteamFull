// Used by:
// Card 2534 using item ad_landofstored_connor (boys only)
// Card 2535 using item ad_landofstories_alex (girls only)
// Card 2545 using item ad_legomovie_batman

package game.data.specialAbility.character
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.animation.Animation;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.SpecialAbilityData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionChain;
	import game.util.TimelineUtils;
	
	/**
	 * Display swf thought bubble
	 * 
	 * Required params:
	 * swfPath		STring		Path to swf file
	 */
	public class ThoughtBubble extends SpecialAbility
	{		
		override public function activate(node:SpecialAbilityNode):void
		{
			if((!super.data.isActive) && (_swfPath))
			{
				super.setActive(true);
				
				// load swf
				super.loadAsset(_swfPath, loadComplete);
			}
		}
		
		/**
		 * When swf loaded 
		 * @param clip
		 */
		private function loadComplete(clip:MovieClip):void
		{
			if (clip == null)
				return;
			
			// get char position
			var charSpatial:Spatial = super.entity.get(Spatial);
			
			// remember thought clip
			_clip = clip;
			clip.visible = false;
			
			// Create thought entity and set the display
			_thoughtEntity = new Entity();
			_thoughtEntity.add(new Display(clip, super.entity.get(Display).container));
			super.group.addEntity(_thoughtEntity);
		
			// set spatial
			var spatial:Spatial = new Spatial(charSpatial.x, charSpatial.y - OFFSET_Y);
			spatial.scaleX = spatial.scaleY = 0;
			_thoughtEntity.add(spatial);
			
			// init values
			_pauseScaling = false;
			_scaleDown= false;
			_animationTime = 0;
			
			// this converts the content clip for AS3
			var vTimeline:Entity = TimelineUtils.convertClip(clip.content, super.group);
			
			// listen for animation completion
			TimelineUtils.onLabel( vTimeline, Animation.LABEL_ENDING, endPopupAnim );
			
			// trigger any now actions
			actionCall(SpecialAbilityData.NOW_ACTIONS_ID);
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if( _thoughtEntity )
			{
				var thoughtSpatial:Spatial = _thoughtEntity.get(Spatial);;
				
				// get current spatial of avatar
				var charSpatial:Spatial = super.entity.get(Spatial);
				
				// move the thought bubble to follow avatar
				thoughtSpatial.x = charSpatial.x;
				thoughtSpatial.y = charSpatial.y - OFFSET_Y;
				
				// if not pausing or hiding, then scale up
				if( (!_pauseScaling) && (!_scaleDown) )
				{	
					thoughtSpatial.scaleX += SCALE_INCREMENT;
					thoughtSpatial.scaleY += SCALE_INCREMENT;
				}
				
				// if reach full size, then _pauseScaling
				if( thoughtSpatial.scaleX >= 1 )
					_pauseScaling = true;
				
				// if paused, then update timer
				if( _pauseScaling )
					_animationTime++;
				
				// when timer beyond limit, then scale down
				if( _animationTime >= ANIM_DELAY )
				{
					_pauseScaling = false;
					_scaleDown = true;
					thoughtSpatial.scaleX -= SCALE_INCREMENT;
					thoughtSpatial.scaleY -= SCALE_INCREMENT;
				}
				
				// keep scale minimum at zero
				if(thoughtSpatial.scaleX <= 0)
					thoughtSpatial.scaleX = thoughtSpatial.scaleY = 0;	
			}
		}
		
		/**
		 * When animation ended 
		 */
		private function endPopupAnim():void
		{
			// remove popup if exists
			if (_thoughtEntity)
			{
				removePopup();
				
				// call action chain if exists
				if (!actionCall(SpecialAbilityData.AFTER_ACTIONS_ID, null, endAbility))
					endAbility();
			}
		}
		
		/**
		 * When ability ends 
		 * @param action
		 */
		private function endAbility(action:ActionChain = null):void
		{
			// make inactive
			super.setActive( false );
		}
		
		/**
		 * Remove popup 
		 */
		private function removePopup():void
		{
			// remove popup
			super.group.removeEntity(_thoughtEntity);
			_thoughtEntity = null;
			_clip = null;
		}

		override public function deactivate( node:SpecialAbilityNode ):void
		{
			// remove popup if exists
			if (_thoughtEntity)
				removePopup();
		}	
		
		public var required:Array = ["swfPath"];
		
		public var _swfPath:String;
		
		private const OFFSET_Y:Number = 90;
		private const ANIM_DELAY:int = 64;
		private const SCALE_INCREMENT:Number = 0.05;
		
		private var _clip:MovieClip;
		private var _thoughtEntity:Entity;
		private var _animationTime:Number = 0;
		private var _pauseScaling:Boolean = false;
		private var _scaleDown:Boolean = false;
	}
}