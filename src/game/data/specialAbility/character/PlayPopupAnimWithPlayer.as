// Used by:
// Card 2630 using item limited_strangemagic (animation with hidden player followed by flying player)
// Card 2630 using pack limited_strangemagic (animation with hidden player followed by flying player)
// Card 2669 using pack limited_tomorrowland_jetpack (flying player)
// Card 2670 using hair limited_kartkingdom (flying player)
// Card 2684 using pack limited_wingsoffire (flying player)
// Card 2838 using item limited_bottle_ship (centered popup with scaled avatar riding ship)

package game.data.specialAbility.character
{	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.data.animation.entity.character.Run;
	import game.data.animation.entity.character.Walk;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	/**
	 * Play popup animation with player NPC inserted into popup
	 * Player avatar is hidden during animation
	 * Player input is locked during animation
	 * Zero position of popup clip should be aligned to player position
	 * 
	 * Optional params:
	 * pack					String		Pack part to use during animation
	 * 
	 * Optional parent params:
	 * lockInput			Boolean		Lock user input (default is true)
	 * alignToPlayer		Boolean 	Align popup to player location (default is false) - align swf content to offset from player position
	 * standingOnly			Boolean		Trigger popup only if player is standing (default is false)
	 * flipPopup			Boolean		Flip popup to align with player direction (default is false)
	 * hidePlayer			Boolean		Hide player (default is true)
	 * charScale			Number		Player character scale (default is 1.0)
	 * npcOnTop				Boolean		NPC on top of popup (default is false)
	 * swapForeground		Boolean		Swap foreground with hit container during animation (default is false);
	 * pack					String		pack part to apply temporarily
	 * parts				String		List of part IDs to apply temporarily (comma-delimited list)
	 * values				String		List of part values to apply temporarily (comma-delimited list)
	 * animClass			Class		animation class
	 * maxFrames			Number		number of frames for above class
	 * animClassReturn		Class		returning animation triggered by timeline
	 */
	public class PlayPopupAnimWithPlayer extends PlayPopupAnim
	{
		override protected function doActivate():void
		{
			// make active
			super.setActive( true );
			
			// lock input during animation
			if (_lockInput)
				SceneUtil.lockInput(super.group, true);
			
			// get character group
			_charGroup = CharacterGroup(super.group.getGroupById("characterGroup"));
			
			// create NPC player
			_playerSpatial = super.entity.get(Spatial);
			_npcPlayer = _charGroup.createNpcPlayer(onCharLoaded, null, new Point(0, 0));
		}
		
		/**
		 * When NPC player is loaded 
		 * @param charEntity
		 */
		private function onCharLoaded( charEntity:Entity = null ):void
		{
			// fix to prevent sleeping when NPC comes from offscreen
			charEntity.get(Sleep).ignoreOffscreenSleep = true;

			// set character scale
			if (_charScale != 0.36)
			{
				_npcPlayer.get(Spatial).scaleX = _npcPlayer.get(Spatial).scaleY = _charScale;
			}
			
			// if aligning
			if ((_alignToPlayer) || (_alignToPart))
			{
				// flip NPC to align
				_npcPlayer.get(Spatial).scaleX = _playerSpatial.scaleX;
			}			

			// if pack part, then apply
			if(_pack != null)
			{
				var lookAspect:LookAspectData = new LookAspectData( SkinUtils.PACK, _pack); 
				var lookData:LookData = new LookData();
				lookData.applyAspect( lookAspect );
				SkinUtils.applyLook( _npcPlayer, lookData, false, loadPopup);
			}
			
			// if passing any kind of parts
			if ((_parts != null) && (_values != null))
			{
				var parts:Array = _parts.split(",");
				var values:Array = _values.split(",");
				for (var i:int = parts.length-1; i!=-1; i--)
				{
					lookAspect = new LookAspectData(parts[i], values[i] ); 
					lookData = new LookData();
					lookData.applyAspect( lookAspect );
					SkinUtils.applyLook( _npcPlayer, lookData, false );
				}
			}
			
			// load popup now
			if (_pack == null)
			{
				super.loadPopup();
			}
		}
		
		/**
		 * when popup swf completes loading 
		 * @param clip
		 */
		override protected function loadPopupComplete(clip:MovieClip):void
		{
			super.loadPopupComplete(clip);
			
			// hide player now that NPC player is loaded and popup is loaded
			if (_hidePlayer)
				super.entity.get(Display).visible = false;
			
			SceneUtil.showHud(super.shellApi.currentScene,false);
			
			// add label listeners
			TimelineUtils.onLabel( _timeline,"invisible", setInvisible );
			TimelineUtils.onLabel( _timeline,"visible", setVisible );
			TimelineUtils.onLabel( _timeline,"stateWalk", setWalk );
			TimelineUtils.onLabel( _timeline,"stateRun", setRun );
			TimelineUtils.onLabel( _timeline,"faceRight", faceRight );
			TimelineUtils.onLabel( _timeline,"return", doReturn );
			TimelineUtils.onLabel( _timeline,"freeze", doFreeze );
			TimelineUtils.onLabel( _timeline,"freeze2", doFreeze );

			var scene:GameScene = GameScene(super.shellApi.sceneManager.currentScene);
			
			// if not aligning, then get offset to center
			if ((!_alignToPlayer) && (!_alignToPart))
			{
				_popupScale = _popupClipEntity.get(Spatial).scaleY;
				_npcXOffSet = _popupClipEntity.get(Spatial).x - scene.hitContainer.x - super.shellApi.viewportWidth/2;
				_npcYOffSet = _popupClipEntity.get(Spatial).y - scene.hitContainer.y - super.shellApi.viewportHeight/2;
			}
			
			// move NPC to top (assumes both are within hit container and not overlay container
			if (_npcOnTop)
				_container.swapChildren(_npcPlayer.get(Display).displayObject, clip);
			
			// swap foreground if requested
			if (_swapForeground)
			{
				var fgEntity:Entity = scene.getEntityById("foreground");
				if (fgEntity != null)
				{
					_foregroundClip = scene.getEntityById("foreground").get(Display).displayObject;
					_foregroundClip.parent.swapChildren(_foregroundClip, _container);
				}
			}
			
			// set animation if any
			if (_animClass != null)
			{
				CharUtils.setAnim( _npcPlayer, _animClass);
			}
		}
		
		private function setInvisible():void
		{
			_npcPlayer.get(Display).visible = false;
		}
		
		private function setVisible():void
		{	
			_npcPlayer.get(Display).visible = true;
		}
		
		private function setWalk():void
		{	
			CharUtils.setAnim(_npcPlayer, Walk);
		}
		private function setRun():void
		{	
			CharUtils.setAnim(_npcPlayer, Run);
		}
		
		private function faceRight():void
		{	
			if(_npcPlayer.get(Spatial).scaleX > 0)
				_npcPlayer.get(Spatial).scaleX *= -1;
		}
		
		private function doReturn():void
		{	
			// set animation if any
			if (_animClassReturn != null)
			{
				CharUtils.freeze(_npcPlayer, false);
				CharUtils.setAnim( _npcPlayer, _animClassReturn);
			}
		}
		
		private function doFreeze():void
		{
			CharUtils.freeze(_npcPlayer);
		}
		
		public override function update(node:SpecialAbilityNode, time:Number):void
		{
			// if NPC player and popup clip			
			if( (_npcPlayer) && (_popupClip) )
			{
				// apply clip's content player instance coords to npc player
				var playerInstance:MovieClip = _popupClip.content.playerInstance;
				if ((_alignToPlayer) || (_alignToPart))
				{
					_npcPlayer.get(Spatial).x = _playerSpatial.x +  playerInstance.x + _npcXOffSet;
					_npcPlayer.get(Spatial).y = _playerSpatial.y + playerInstance.y + _npcYOffSet;
				}
				else
				{
					// get position of centered popup
					_npcPlayer.get(Spatial).x = _npcXOffSet + playerInstance.x * _popupScale;
					_npcPlayer.get(Spatial).y = _npcYOffSet + playerInstance.y * _popupScale;
				}
				_npcPlayer.get(Spatial).rotation = playerInstance.rotation;
			}
		}
		
		/**
		 * When popup animation reaches end 
		 */
		override protected function endPopupAnim():void
		{
			//turn on any layers
			SceneUtil.showHud(super.shellApi.currentScene,true);
			
			// if swapping, then reverse layers for foreground and hit container
			if ((_swapForeground) && (_foregroundClip != null))
				_foregroundClip.parent.swapChildren(_container, _foregroundClip);

			super.endPopupAnim();			
			
			// make player visible
			super.entity.get(Display).visible = true;
			
			// remove NPC player
			_charGroup.removeEntity(_npcPlayer);
			_npcPlayer = null;
		}
		
		public var _pack:String;
		public var _npcXOffSet:Number = 0;
		public var _npcYOffSet:Number = 0;
		public var _hidePlayer:Boolean = true;
		public var _charScale:Number = 0.36;
		public var _npcOnTop:Boolean = false;
		public var _swapForeground:Boolean = false;
		public var _parts:String;
		public var _values:String;
		public var _animClass:Class;
		public var _animClassReturn:Class;
		
		private var _npcPlayer:Entity;
		private var _charGroup:CharacterGroup;
		private var _playerSpatial:Spatial;
		private var _popupScale:Number;
		private var _foregroundClip:DisplayObject;
	}
}
