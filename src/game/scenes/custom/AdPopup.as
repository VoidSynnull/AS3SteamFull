package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.getDefinitionByName;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.ads.AdData;
	import game.data.ads.AdvertisingConstants;
	import game.data.animation.Animation;
	import game.scene.template.CharacterGroup;
	import game.scene.template.SFSceneGroup;
	import game.ui.popup.Popup;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	
	/**
	 * Ad popup class for loading a popup in the ad interior (offers support for player clone and npcs)
	 * Used for Wormhole.swf in PoptropicaComicsQuest
	 * @author Justin Kelly
	 */
	public class AdPopup extends Popup
	{
		/**
		 * Constructor 
		 * @param container
		 * @param adData
		 * @param baseName base name for swf and xml without extension
		 */
		public function AdPopup(container:DisplayObjectContainer = null, adData:AdData=null, baseName:String = null)
		{
			_adData = adData;
			_baseName = baseName;
			super();
		}
		
		/**
		 * Init popup 
		 * @param container
		 */
		override public function init(container:DisplayObjectContainer = null):void
		{
			// quest name used for pulling files
			_questName = AdUtils.convertNameToQuest(_adData.campaign_name);
			// darken background
			//super.darkenBackground = true;
			// assets will be found in limited folder
			super.groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/";
			super.init(container);
			load();
		}
		
		/**
		 * Load campaign specific assets 
		 */
		override public function load():void
		{
			// add signal for completion
			super.shellApi.fileLoadComplete.addOnce(loaded);
			// set paths and load files
			_npcXMLPath =   _questName  + "/" + _baseName + ".xml";
			_swfPath = _questName  + "/" + _baseName + ".swf";
			super.loadFiles(new Array(_swfPath, _npcXMLPath));
		}
		
		/**
		 * All assets ready 
		 */
		override public function loaded():void
		{
			// hide emotes in party room
			var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			if(sfSceneGroup != null)
				sfSceneGroup.emotes.getButton().get(Display).visible = false;
			
			// get swf
			super.screen = MovieClip(super.getAsset(_swfPath, true));
			
			// if clip not found, then error
			if (super.screen == null)
			{
				trace("Can't find popup: " + _swfPath);
			}
			else
			{
				// if found
				// if player instance, then load player clone
				if (super.screen.content.playerInstance)
				{
					var charGroup:CharacterGroup = new CharacterGroup();
					charGroup.setupGroup( this, super.screen.content.playerInstance, null, null );
					_char = charGroup.createNpcPlayer( onCharLoaded, null, new Point( super.screen.content.playerInstance.x, super.screen.content.playerInstance.y ));
				}
				
				// if npc instance and npc xml, then load npcs from xml into npc clip
				if ((super.screen.content.npc) && (super.getData(_npcXMLPath)))
				{
					var charGroupNPC:CharacterGroup = new CharacterGroup();
					charGroupNPC.setupGroup( this, super.screen.content.npc, super.getData(_npcXMLPath));
				}
				
				// convert content into timeline
				var vTimeline:Entity = TimelineUtils.convertClip(super.screen.content, super);
				// signal for when timeline animation reaches end
				TimelineUtils.onLabel( vTimeline, Animation.LABEL_ENDING, endpopup);
				
				//TODO? :: if sounds, set audio to mute, unmute when close popup
				//var _audioSystem:AudioSystem = AudioSystem(super.getSystem(AudioSystem));
				//_audioSystem.muteSounds();
				
				// center screen
				super.screen.content.x = super.shellApi.viewportWidth/2;
				super.screen.content.y =super.shellApi.viewportHeight/2;
			}
			super.loaded();
		}
		
		/**
		 * When player clone is loaded
		 * NOTE: the avatar is scaled up to compensate for a scaled-down player instance clip in Wormhole.swf
		 * This needs to be removed or adjusted for any new campaigns
		 * @param charEntity
		 */
		private function onCharLoaded( charEntity:Entity = null ):void
		{
			_char.get(Spatial).scaleX = _char.get(Spatial).scaleY = 2;
		}
		
		/**
		 * When popup animation reaches end 
		 */
		private function endpopup():void
		{
			// unhide emots in party room
			var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			if(sfSceneGroup != null)
				sfSceneGroup.emotes.getButton().get(Display).visible = true;
			
			// event to trigger anything after the popup is done
			super.shellApi.triggerEvent("AdPopupDone",false, false);
			// restore user input and remove popup
			super.endPopupAnim();
		}
		
		private var _adData:AdData;
		private var _questName:String;
		private var _baseName:String;
		private var _char:Entity;
		private var _npcXMLPath:String;
		private var _swfPath:String;
	}
}