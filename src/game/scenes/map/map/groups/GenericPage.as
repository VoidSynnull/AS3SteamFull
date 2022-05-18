package game.scenes.map.map.groups
{
	import com.poptropica.AppConfig;
	import flash.net.URLRequest;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.net.navigateToURL;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	
	import game.creators.ui.ButtonCreator;
	import game.data.PlayerLocation;
	import game.data.dlc.PackagedFileState;
	import game.scene.template.ContentRetrievalGroup;
	import game.scenes.hub.town.Town;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.TextUtils;
	
	public class GenericPage extends IslandPopupPage
	{
		protected var _contentType:String = "Island";
		protected var _contentRetrievalGroup:ContentRetrievalGroup;
		
		public function GenericPage(container:DisplayObjectContainer=null)
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
			var clip:MovieClip = this.pageContainer.getChildByName("button_play") as MovieClip;
			var entity:Entity = ButtonCreator.createButtonEntity(clip, this);
			var display:DisplayObjectContainer = Display(entity.get(Display)).displayObject;
			var interaction:Interaction = entity.get(Interaction);
			
			var textfield:TextField = TextUtils.refreshText(display.getChildByName("description") as TextField);
			textfield.autoSize = TextFieldAutoSize.CENTER;
			
			_contentRetrievalGroup = new ContentRetrievalGroup();
			_contentRetrievalGroup.setupGroup( this, true, this.groupContainer.parent.parent );
			
			// create buttons
			if(this.pageXML.status == "coming_soon")
			{
				textfield.text = "Coming Soon";
			}
			else
			{
				if( !PlatformUtils.isMobileOS || super.shellApi.dlcManager == null || AppConfig.ignoreDLC )
				{
					textfield.text = "Play";
					interaction.click.add(playClicked);
				}
				else
				{
					var contentId:String = DataUtils.getString( this.pageXML.island );
					var packagedFileState:String = super.shellApi.dlcManager.getPackagedFileState(contentId);
					
					trace("IslandPage : packaged file state for " + this.pageXML.island + " : " + packagedFileState);
					
					if(packagedFileState != null)
					{
						//This shouldn't be, unless you are testing locally and skipping zips/downloads/purchasing
						if(packagedFileState == PackagedFileState.UNCOMPRESSED || super.shellApi.dlcManager.isInstalled(contentId))
						{
							textfield.text = "Play";
							interaction.click.add(playClicked);
						}
						else
						{
							if( !super.shellApi.dlcManager.isFree(this.pageXML.island) && !super.shellApi.dlcManager.isPurchased(contentId) )
							{
								textfield.text = "Buy";
								interaction.click.add(purchaseClicked);
							}
							else if( packagedFileState == PackagedFileState.REMOTE_COMPRESSED)	// QUESTION :: Does packagedFileState after the content has been downloaded? 
							{
								textfield.text = "Download And Play";
								interaction.click.add(downloadClicked);
							}
							else	// must be localCompressed, so we uncompress, but don't need to download 
							{
								textfield.text = "Play";
								interaction.click.add(downloadClicked);
							}
						}
					}
				}
			}
		}
		
		protected function purchaseClicked(button:Entity=null):void
		{
			var contentId:String = DataUtils.getString( this.pageXML.island );
			_contentRetrievalGroup.processComplete.addOnce( retrievalResponse );	// add handler for when content is complete.  Need to make sure this doesn't get out of sync. - bard
			_contentRetrievalGroup.purchaseContent(contentId, _contentType, true );
		}
		
		protected function downloadClicked(button:Entity):void
		{
			var contentId:String = DataUtils.getString( this.pageXML.island );
			_contentRetrievalGroup.processComplete.addOnce( retrievalResponse );	// add handler for when content is complete.  Need to make sure this doesn't get out of sync. - bard
			_contentRetrievalGroup.downloadContent(contentId, _contentType );
		}
		
		protected function retrievalResponse( success:Boolean = false, content:String = "" ):void
		{
			if( success )
			{
				this.returnToIslandAndScene();
			}
		}
		
		private function playClicked(entity:Entity):void
		{
			(entity.get(Interaction) as Interaction).lock = true;
			
			this.returnToIslandAndScene();
		}
		
		private function returnToIslandAndScene():void
		{
			var island:String = "";
			if(this.pageXML && this.pageXML.island)
			{
				island = String(this.pageXML.island);
			}
			
			var vars:URLVariables = new URLVariables();
			vars.context = 	"episode_selected:" + island + ";" +
							"episode_selected_percentage:" + 0;
			vars.dimensions = new Object();
			vars.dimensions["episode_selected"] = island;
			vars.dimensions["episode_selected_percentage"] = 0;
			this.shellApi.track("MapIslandPlayed", null, null, null, null, null, null, vars);
			
			if(island == "early")
			{
				navigateToURL(new URLRequest('/base.php'), '_self');
				return;
			}
			
			/*
			For some reason, there are Objects in this dictionary when there should only be
			old Strings or new PlayerLocations. Check if a PlayerLocation, and if not,
			just load the default scene. Hard to test AFTER a ProfileData has already been updated.
			*/
			var lastLoc:* = this.shellApi.profileManager.active.lastScene[island];
			
			//If we have a last location, put them there.
			if(lastLoc is PlayerLocation)
			{
				var lastLocation:PlayerLocation = lastLoc;
				// fix for coming back from registration for lands
				if (lastLocation.scene == "RedirectToRegistration")
					this.shellApi.loadFile(super.shellApi.dataPrefix + "scenes/" + island + "/island.xml", this.islandXMLLoaded);
				else
					this.loadSceneAS3OrAS2(island, lastLocation.scene, lastLocation.locX, lastLocation.locY, lastLocation.direction == "L" ? "left" : "right");
			}
			//If not, we'll load the island's default starting scene and location.
			else
			{
				this.shellApi.loadFile(super.shellApi.dataPrefix + "scenes/" + island + "/island.xml", this.islandXMLLoaded);
			}
		}
		
		private function islandXMLLoaded(xml:XML):void
		{
			if(!xml) return;
			
			var island:String = String(xml.island);
			
			var firstScene:XML = XML(xml.firstScene);
			
			var scene:String 		= String(firstScene.scene);
			var x:Number 			= Number(firstScene.x);
			var y:Number 			= Number(firstScene.y);
			var direction:String 	= String(firstScene.direction);
			
			this.loadSceneAS3OrAS2(island, scene, x, y, direction);
		}
		
		private function loadSceneAS3OrAS2(island:String, scene:String, x:Number, y:Number, direction:String):void
		{
			//Go to AS3 (AS2 removed)
			if(scene.indexOf(".") > -1)
			{
				trace(this, "loadSceneAS3OrAS2() ::", "type = AS3", "island =", island, "scene =", scene, "x =", x, "y =", y, "direction =", direction);
				var sceneClass:Class = ClassUtils.getClassByName(scene);
				this.shellApi.loadScene(sceneClass, x, y, direction, null, null, onIslandLoadFailure);
			}
			else
			{
				shellApi.loadScene(Town);
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
	}
}
