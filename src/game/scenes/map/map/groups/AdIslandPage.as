package game.scenes.map.map.groups
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.getDefinitionByName;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.managers.DLCManager;
	import game.managers.ads.AdManager;
	import game.managers.ads.AdManagerMobile;
	import game.scene.template.ContentRetrievalGroup;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.TextUtils;
	import game.utils.AdUtils;
	
	/**
	 * Map popup page for ad island (MMQ) 
	 * @author VHOCKRI
	 */
	public class AdIslandPage extends IslandPopupPage
	{
		protected var _contentType:String = "Quest";
		protected var _contentRetrievalGroup:ContentRetrievalGroup;
		
		public function AdIslandPage(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		override protected function allXMLAssetsLoaded():void
		{
			this.setupTitle();
			this.setupDescription();
			this.setupPlayButton();
		}
		
		private function setupTitle():void
		{
			var title:TextField = this.pageContainer.getChildByName("title") as TextField;
			title = TextUtils.refreshText(title);
			title.text = String(this.pageXML.title);
		}
		
		private function setupDescription():void
		{
			var description:TextField = this.pageContainer.getChildByName("description") as TextField;
			description = TextUtils.refreshText(description);
			description.text = String(this.pageXML.description);
		}
		
		private function setupPlayButton():void
		{
			// get campaign name from island folder path (usually ends with MMQ)
			_campaignName = super.islandFolder.split("/")[1];
			// get ad quest name for content ID (should end with "Quest")
			_contentId = AdUtils.convertNameToQuest(_campaignName);
			
			// check if using "popURL" for island
			// this means that a pop url is used in the CMS for the clickURL
			// works like an ad driver
			if ((this.pageXML != null) && (this.pageXML.island == "popURL"))
			{
				// get ad data
				var adManager:AdManagerMobile = AdManagerMobile(super.shellApi.adManager);
				var adData:AdData = adManager.getAdDataByCampaign(_campaignName);
				// if ad data and clickURL start with "pop://", then get it
				if ((adData != null) && (adData.clickURL != null) && (adData.clickURL.substr(0,6) == "pop://"))
				{
					_popURL = adData.clickURL;
				}
			}

			var clip:MovieClip = this.pageContainer.getChildByName("button_play") as MovieClip;
			clip.gotoAndStop(1);
			var entity:Entity = ButtonCreator.createButtonEntity(clip, this);
			var display:DisplayObjectContainer = Display(entity.get(Display)).displayObject;
			var interaction:Interaction = entity.get(Interaction);
			var textfield:TextField = TextUtils.refreshText(clip.getChildByName("description") as TextField);
			textfield.autoSize = TextFieldAutoSize.CENTER;
			
			_contentRetrievalGroup = new ContentRetrievalGroup();
			_contentRetrievalGroup.setupGroup( this, true, this.groupContainer.parent.parent );
			
			// if popURL then show play button
			if (_popURL != null)
			{
				textfield.text = "Play";
				interaction.click.add(openPopURL);
			}
			// if web (not mobile), then show play button
			else if (!PlatformUtils.isMobileOS)
			{
				textfield.text = "Play";
				interaction.click.add(playClicked);
			}
			else
			{
				// if mobile
				// if ignoring downloadable content, then show download button (to simulate downloading when running locally)
				if (AppConfig.ignoreDLC)
				{
					textfield.text = "Download & Play";
					interaction.click.add(downloadClicked);
				}
				else
				{
					// if using dlc manager
					var dlcManager:DLCManager = super.shellApi.dlcManager;
					
					// if zip installed and doesn't need validation and isn't blocked for being invalid, then show play button
					if ((dlcManager.isInstalled(_contentId)) && (!dlcManager.needsValidation(_contentId)) && (!dlcManager.blockInvalidContent(_contentId)))
					{
						textfield.text = "Play";
						interaction.click.add(playClicked);
					}
					else
					{
						// else show download button
						textfield.text = "Download & Play";
						interaction.click.add(downloadClicked);
					}
				}
			}
		}
		
		protected function openPopURL(entity:Entity):void
		{
			// click tracking
			super.shellApi.adManager.track(_campaignName, AdTrackingConstants.TRACKING_CLICKED, "Map");
			AdUtils.openSponsorURL(this.shellApi, _popURL, _campaignName, "Map", "Page");
		}
		
		protected function playClicked(entity:Entity):void
		{			
			var adManager:AdManagerMobile = AdManagerMobile(super.shellApi.adManager);
			
			var islandId:String;
			if(this.pageXML != null)
			{
				islandId = this.pageXML.island;
			}
			
			this.loadIsland(islandId);
		}
		
		/**
		 * Click download button 
		 * @param button Entity
		 */
		protected function downloadClicked(button:Entity):void
		{
			trace("AdIslandPage: downloadClicked: from MMQ: " + _campaignName + " for content: " + _contentId );
			
			var adManager:AdManagerMobile = AdManagerMobile(super.shellApi.adManager);
			
			// track button click
			adManager.track(_campaignName, AdTrackingConstants.TRACKING_DOWNLOAD_CLICKED);
			
			// if ignoring downloadable content, load quest interior right away
			if (AppConfig.ignoreDLC)
				adManager.loadQuestInterior();
			else
			{
				// if using DLC manager
				// add handler for when content is complete. Need to make sure this doesn't get out of sync. - bard
				_contentRetrievalGroup.processComplete.addOnce( this.retrievalResponse );
				// initiate download
				_contentRetrievalGroup.downloadContent(_contentId, _contentType );
			}
		}
		
		protected function retrievalResponse( success:Boolean = false, content:String = "" ):void
		{
			if( success )
			{
				loadIsland(content);
			}
		}
		
		/**
		 * Load ad island quest interior 
		 * @param contentId
		 */
		protected function loadIsland( contentId:String = "" ):void
		{
			// if content ID is valid, then load quest interior
			if ( DataUtils.validString(contentId) )
			{
				AdManagerMobile(super.shellApi.adManager).loadQuestInterior();
			}
			else
			{
				// if invalid, then failure
				trace("AdIslandPage: Error: loadIsland: not a valid island id: " + contentId );
				this.onIslandLoadFailure();
			}
		}
		
		/**
		 * If the island fails to load we recover by closing the content retrieval popup 
		 * 
		 */
		private function onIslandLoadFailure():void
		{
			if( _contentRetrievalGroup )
			{
				_contentRetrievalGroup.processComplete.removeAll();
				_contentRetrievalGroup.closePopup();
			}
		}
		
		private var _popURL:String;
		private var _campaignName:String;
		private var _contentId:String;
	}
}

