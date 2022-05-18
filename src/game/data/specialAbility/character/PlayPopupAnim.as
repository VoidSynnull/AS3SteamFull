// Used by:
// Card 2457 using item sponsor_dork_pen (simple popup animation)
// Card 2531 using item ad_dragonsberk2_shield (push animation followed by shield effect, then pop and stand)
// Card 2533 using ability limited/popup_anim_caprisun (has delayed avatar animation)
// Card 2544 using item ad_legomovie_awesome (plays simulataneous sound - sound must be in sound/limited folder)
// Card 2546 using overshirt ad_dxd_anim_stevenecklace (plays automatic animation on eaxh scene load and does not lock input)
// Card 2551 using avatar overshirt ad_planes2_badge (simple popup animation)
// Card 2567 using item ad_caprisun_high_kicker (aligns to player and has ending avatar animation)
// Card 2571 using ability limited/activate_actionanim_splash (simple popup animation)
// Card 2583 using ability limited/activate_actionanim_lalaloopsy (everyone dances three times)
// Card 2601 using item limited_mhff (simple popup animation)
// Card 2602 using item ad_streethawk_rc (flips popup for character direction and has player dialog at end)
// Card 2604 using item limited_dipop (simple popup animation)
// Card 2631 using item limited_strangemagic_staff (spin item and play sound after popup)
// Card 2645 using item limited_penguins_dibble (aligns animation to player)
// Card 2646 using item limited_mixels_booglybrick (simple popup animation)
// Card 2641 using item limited_cinderalla (turn NPCs into random male and female looks)
// Card 2647 using item limited_mixels_niksputbrick (hides player and aligns to player)
// Card 2648 using item limited_mixels_flamzerbrick (simple popup animation)
// Card 2677 using facial limited_percyjackson_eyepower (aligned animation with facial part toggling on/off with each activation)
// Card 2705 using item limited_captainunderpants_hat (fart cloud with FartCloud particle effect with dialog)

package game.data.specialAbility.character
{	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.animation.Animation;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.SpecialAbilityData;
	import game.managers.ScreenManager;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.GameScene;
	import game.systems.actionChain.ActionChain;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	/**
	 * Play popup animation
	 * Centers 960x480 popup or aligns to player coordinates
	 * If you are playing a popup animation from a card, you can also use the CardAnimPower class which hides the inventory and allows offsets
	 * 
	 * Required params:
	 * swfPath				String		Path to swf file
	 * swfPaths				Array		array of swf files to play at random
	 * 
	 * Optional params:
	 * lockInput			Boolean		Lock user input (default is true)
	 * alignToPlayer		Boolean 	Align popup to player location (default is false) - align swf content to offset from player position
	 * standingOnly			Boolean		Trigger popup only if player is standing (default is false)
	 * flipPopup			Boolean		Flip popup to align with player direction (default is false)
	 * alignToPart			String		Avatar part to align to
	 * center				Boolean		Center popup on screen (default is false)
	 * scaleToFill			Boolean		Scale to fill screen (for Wrinkle in Time)
	 */
	public class PlayPopupAnim extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			// check for standing only
			var allowActivate:Boolean = ((!_standingOnly) || ((_standingOnly) && (CharUtils.getStateType(entity) == CharacterState.STAND)));
			
			// convert single path to array if no swfPaths
			if ((_swfPath) && (_swfPaths == null))
				_swfPaths = [_swfPath];
			
			// if not active and standing only, then make active
			if ( (!super.data.isActive) && (allowActivate) )
				doActivate();
		}
		
		/**
		 * Activate inactive ability 
		 */
		protected function doActivate():void
		{
			// make active
			super.setActive( true );
			
			// lock input during animation
			if (_lockInput)
				SceneUtil.lockInput(super.group, true);
			
			// load popup
			loadPopup();
		}
		
		/**
		 * load popup 
		 */
		protected function loadPopup(entity:Entity = null):void
		{
			var scene:GameScene = GameScene(super.shellApi.sceneManager.currentScene);
			
			if(_actions != null)
			{
				_actionId = "_"+_actions[Math.floor(_actions.length * Math.random())];
				actionCall(SpecialAbilityData.NOW_ACTIONS_ID + _actionId,null, endAbility);
				return;
			}
			
			// if aligning to player or player part, then add to hit container
			if ((_alignToPlayer) || (_alignToPart))
			{
				_container = scene.hitContainer;
			}
			else if (_center)
			{
				_container = scene.hitContainer;
			}
			else
			{
				// else center over scene in overlay container
				_container = scene.overlayContainer;
			}
			// select random swf from array
			var filePath:String = _swfPaths[Math.floor(_swfPaths.length * Math.random())];
			
			// load popup
			trace("BasePlayPopupAnim: load popup " + filePath);
			super.loadAsset(filePath, loadPopupComplete);		
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
			
			trace("BasePlayPopupAnim: Popup loaded");
			
			// remember clip
			_popupClip = clip;
			
			// disable interaction
			clip.mouseChildren = clip.mouseEnabled = false;
			
			// Add the movieClip to scene
			_container.addChild(clip);
			
			// Create the new entity and set the display and spatial
			_popupClipEntity = new Entity();
			_popupClipEntity.add(new Display(clip, _container));
			
			// if aligning popup to player, then position
			var playerSpatial:Spatial = super.entity.get(Spatial);
			var clipSpatial:Spatial;
			if ((_alignToPlayer) || (_alignToPart))
			{
				clipSpatial = new Spatial(playerSpatial.x, playerSpatial.y);
				// if aligning to part, then perform offsets
				if (_alignToPart)
				{
					var partSpatial:Spatial = CharUtils.getJoint(super.entity, _alignToPart).get(Spatial);					
					var direction:String = playerSpatial.scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
					
					clipSpatial.y = playerSpatial.y + (partSpatial.y * playerSpatial.scale);
					if (direction == CharUtils.DIRECTION_LEFT)
						clipSpatial.x = playerSpatial.x + (partSpatial.x * playerSpatial.scale);
					else
						clipSpatial.x = playerSpatial.x - (partSpatial.x * playerSpatial.scale);			
				}
			}
			else
			{
				// target proportions for device
				var targetProportions:Number = super.shellApi.viewportWidth/super.shellApi.viewportHeight;
				var destProportions:Number = ScreenManager.GAME_WIDTH/ScreenManager.GAME_HEIGHT;
				var scale:Number;
				if (_scaleToFill)
				{
					// if narrower, then fit to width and center vertically
					if (destProportions <= targetProportions)
					{
						scale = super.shellApi.viewportWidth/ScreenManager.GAME_WIDTH;
					}
					else
					{
						// else fit to height and center horizontally
						scale = super.shellApi.viewportHeight/ScreenManager.GAME_HEIGHT;
					}
				}
				else
				{
					// if wider, then fit to width and center vertically
					if (destProportions >= targetProportions)
					{
						scale = super.shellApi.viewportWidth/ScreenManager.GAME_WIDTH;
					}
					else
					{
						// else fit to height and center horizontally
						scale = super.shellApi.viewportHeight/ScreenManager.GAME_HEIGHT;
					}
				}
				var x:Number = super.shellApi.viewportWidth / 2 - ScreenManager.GAME_WIDTH * scale / 2;
				var y:Number = super.shellApi.viewportHeight / 2 - ScreenManager.GAME_HEIGHT * scale/ 2;
				clipSpatial = new Spatial(x, y);
				clipSpatial.scaleX = clipSpatial.scaleY = scale;
			}
			
			// if flip popup is requested and player is facing left
			if( (_flipPopup) && (playerSpatial.scaleX > 0) )
			{
				clip.content.scaleX *= -1;
				clipSpatial.scaleX *= -1;
			}
			_popupClipEntity.add(clipSpatial);
			
			// add to scene
			super.group.addEntity(_popupClipEntity);
			
			// this converts the content clip for AS3
			_timeline = TimelineUtils.convertClip(clip.content, super.group);
			TimelineUtils.onLabel( _timeline, Animation.LABEL_ENDING, endPopupAnim );
			if(_moveToBack)
				DisplayUtils.moveToBack(clip);
			if(_useRandomBG)
				_popupClip.content.bgClip.gotoAndStop(randomRange(1,_numBGs));
			// trigger any now actions
			actionCall(SpecialAbilityData.NOW_ACTIONS_ID + _actionId);
		}
		
		private function randomRange(minNum:Number, maxNum:Number):Number 
		{
			return (Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum);
		}
		
		/**
		 * When popup animation reaches end 
		 */
		protected function endPopupAnim():void
		{
			if (_popupClip)
			{
				// remove popup
				removePopup();
				
				// call action chain if exists
				if (!actionCall(SpecialAbilityData.AFTER_ACTIONS_ID + _actionId, null, endAbility))
					endAbility();
			}
		}
		
		/**
		 * Remove popup 
		 */
		private function removePopup():void
		{
			// remove popup
			_container.removeChild(_popupClip);
			super.group.removeEntity(_popupClipEntity);
			_popupClip = null;
			_popupClipEntity = null;
		}
			
		/**
		 * When ability ends 
		 * @param action
		 */
		private function endAbility(action:ActionChain = null):void
		{
			// unlock input
			SceneUtil.lockInput(super.group, false);
			
			// make inactive
			super.setActive( false );
		}
				
		/**
		 * deactivate (end animation if running) 
		 * @param node
		 */
		override public function deactivate( node:SpecialAbilityNode ):void
		{	
			// remove popup if exists
			if (_popupClip)
				removePopup();
		}		
		
		public var required:Array = ["swfPath","swfPaths"];
		
		public var _swfPath:String;
		public var _swfPaths:Array;
		public var _alignToPlayer:Boolean = false;
		public var _moveToBack:Boolean = false;
		public var _lockInput:Boolean = true;
		public var _standingOnly:Boolean = false;
		public var _flipPopup:Boolean = false;
		public var _alignToPart:String;
		public var _center:Boolean = false;
		public var _scaleToFill:Boolean = false;
		public var _actions:Array;
		
		protected var _popupClipEntity:Entity;
		protected var _popupClip:MovieClip;
		protected var _timeline:Entity;
		
		protected var _container:DisplayObjectContainer;		
		private var _action:Class;
		private var _label:String;
		private var _isMobile:Boolean;
		private var _actionId:String = "";
		public var _useRandomBG:Boolean = false;
		public var _numBGs:Number = 1;
	}
}