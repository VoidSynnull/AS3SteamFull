package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	
	import game.adparts.parts.AdVideo;
	import game.components.entity.Dialog;
	import game.components.entity.character.BitmapCharacter;
	import game.components.timeline.Timeline;
	import game.data.ads.AdvertisingConstants;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Grief;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.nodes.entity.character.NpcNode;
	import game.scene.template.ads.AdVideoGroup;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	/**
	 * Plays a timeline video file from a card 
	 * Refer to the MuppetsMostWantedMVU2 campaign and card 2516
	 */
	public class CardVideoPower extends Popup
	{
		public function CardVideoPower()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = false;
			super.init(container);
			load();
		}		
				
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			
			// if missing limited, then add
			if (super.data.swfPath.substr(0,7) != AdvertisingConstants.AD_PATH_KEYWORD)
				super.data.swfPath = AdvertisingConstants.AD_PATH_KEYWORD + "/" + super.data.swfPath;
			
			super.loadFiles(new Array(super.data.swfPath));
		}
		
		// all assets ready
		override public function loaded():void
		{
	 		super.screen = super.getAsset(super.data.swfPath, true) as MovieClip;
			
			// this converts the content clip for AS3
			// NOTE: if the animation instance is not named "content" then you will get an error here!!!!
			_timeline = TimelineUtils.convertClip(super.screen.content, super);
			TimelineUtils.onLabel( _timeline, Animation.LABEL_ENDING, endPopup );
			// label for when video should start
			TimelineUtils.onLabel( _timeline, "startVideo", startVideo );
			
			// setup video
			// if video group exists, then don't create new one
			_videoGroup = AdVideoGroup(super.shellApi.sceneManager.currentScene.groupManager.getGroupById("AdVideoGroup"));
			if (_videoGroup == null)
				_videoGroup = new AdVideoGroup();
			var videoData:Object = {};
			videoData.width = super.data.videoWidth;
			videoData.height = super.data.videoHeight;
			// use video passed to popup
			videoData.videoFile = super.data.video;
			_videoEntity = _videoGroup.setupAutoCardVideo(this, super.screen.content.popupVideo, super.screen.content, videoData);
			// disable user input
			SceneUtil.lockInput(super, true);
			
			super.loaded();
		}
		
		private function startVideo():void
		{
			_videoEntity.get(AdVideo).fnClick();
			switch (super.data.event)
			{
				case "ConstantineSteal":
					// Used for Muppets Most Wanted campaign
					// give avatar mole and burlar bag
					var lookData:LookData = new LookData();
					var lookAspect:LookAspectData = new LookAspectData( SkinUtils.ITEM, "ad_muppets2_burglarbag" ); 
					lookData.applyAspect( lookAspect );
					lookAspect = new LookAspectData( SkinUtils.MARKS, "ad_constantine_mole" );
					lookData.applyAspect( lookAspect )			
					SkinUtils.applyLook( super.shellApi.player, lookData, false );

					// hide hair
					var npcList:NodeList = this.systemManager.getNodeList( NpcNode );
					for( var npcNode:NpcNode = npcList.head; npcNode; npcNode = npcNode.next )
					{
						if (!npcNode.entity.has(BitmapCharacter))
						{
							CharUtils.getPart( npcNode.entity, "hair" ).get(Display).visible = false;
							CharUtils.getPart( npcNode.entity, "facial" ).get(Display).visible = false;
							CharUtils.getPart( npcNode.entity, "marks" ).get(Display).visible = false;
						}
					}
					break;
			}
		}
		
		public function doneVideo():void
		{
			_timeline.get(Timeline).play();
			// dispose of video
			_videoEntity.get(AdVideo).fnDispose();
			_videoGroup.removeEntity(_videoEntity);
		}
		
		private function endPopup():void
		{
			switch (super.data.event)
			{
				case "ConstantineSteal":
					// Used for Muppets Most Wanted campaign
					// avatar speaks
					super.shellApi.player.get(Dialog).say("Heh, heh, heh.");
					// others do grief anim
					var npcList:NodeList = this.systemManager.getNodeList( NpcNode );
					for( var npcNode:NpcNode = npcList.head; npcNode; npcNode = npcNode.next )
					{
						if (!npcNode.entity.has(BitmapCharacter))
							CharUtils.setAnim( npcNode.entity, Grief );
					}
					break;
			}
			super.endPopupAnim();
		}
		
		private var _videoGroup:AdVideoGroup;
		private var _videoEntity:Entity;
		private var _timeline:Entity;
	}
}
