package game.scenes.map.map.groups
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	import com.poptropica.AppConfig;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.PlayerLocation;
	import game.data.comm.PopResponse;
	import game.data.dlc.PackagedFileState;
	import game.data.profile.ProfileData;
	import game.proxy.Connection;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.scene.template.ContentRetrievalGroup;
	import game.scenes.hub.petBarn.PetBarn;
	import game.scenes.hub.town.Town;
	import game.scenes.map.map.IslandProgressLoader;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.util.StringUtil;
	import game.util.TextUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.PolyStar;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class IslandPage extends IslandPopupPage
	{
		private var progress:Number = 0;
		
		public function IslandPage(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		override protected function allXMLAssetsLoaded():void
		{
			island = DataUtils.getString( this.pageXML.island );
			this.setupTitle();
			this.setupDescription();
			this.setupMedallion();
			this.setupCompletions();
			this.setupDifficulty();
			this.setupProgress();
			this.setupRestartButton();
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
					var contentId:String = island;
					var packagedFileState:String = super.shellApi.dlcManager.getPackagedFileState(contentId);
					
					trace("IslandPage : packaged file state for " + island + " : " + packagedFileState);
					
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
							if( !super.shellApi.dlcManager.isFree(island) && !super.shellApi.dlcManager.isPurchased(contentId) )
							{
								textfield.text = "Buy";
								interaction.click.add(purchaseClicked);
							}
							else if( packagedFileState == PackagedFileState.REMOTE_COMPRESSED)	// QUESTION :: Does packagedFileState after the content has been downloaded? 
							{
								textfield.text = "Download & Play";
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
		
		private function setupRestartButton():void
		{
			var clip:MovieClip = this.pageContainer.getChildByName("button_restart") as MovieClip;
			if(clip)
			{
				ButtonCreator.createButtonEntity(clip, this, restartClicked);
			}
		}
		
		private function restartClicked(button:Entity):void
		{
			//this.traceLSO(ProxyUtils.as2lso.data);
			
			var popup:ConfirmationDialogBox = new ConfirmationDialogBox(2, "Are you sure you want to reset your progress and restart the island?", restartIsland);
			popup.pauseParent = true;
			popup.darkenBackground = true;
			this.parent.addChildGroup(popup);
			popup.init(IslandPopup(this.parent).groupContainer);
		}
		
		private function restartIsland(...args):void
		{
			this.progress = 0;
			
			var vars:URLVariables = new URLVariables();
			vars.context = 	"reset_button:" + 1 + ";" +
							"island_reset:" + island;
			vars.dimensions = new Object();
			vars.dimensions["reset_button"] = 1;
			vars.dimensions["island_reset"] = island;
			this.shellApi.track("MapIslandReset", island, null, null, null, null, null, vars);
			
			this.shellApi.triggerEvent("reset_progress_" + island);
			
			var entity:Entity = this.getEntityById("progress");
			var display:DisplayObjectContainer = Display(entity.get(Display)).displayObject;
			var bar:DisplayObject = display.getChildByName("bar");
			var background:DisplayObject = display.getChildByName("background");
			var tween:Tween = entity.get(Tween);
			if(!tween)
			{
				tween = new Tween();
				entity.add(tween);
			}
			tween.to(bar, (bar.width / background.width) * 1.5, {width:0, ease:Quad.easeInOut});
			
			this.shellApi.loadFile(this.shellApi.dataPrefix + "scenes/" + island + "/island.xml", islandResetXMLLoaded);
		}
		
		private function islandResetXMLLoaded(xml:XML):void
		{
			if(xml)
			{
				var as2Format:Boolean = String(xml.gameVersion) == "AS2";
				var island:String = String(xml.island);
				trace(this, island, "is of format", String(xml.gameVersion));
				
				this.shellApi.resetIsland(island, Command.create(onIslandResetResponse, xml), as2Format);
			}
		}
		
		private function onIslandResetResponse(response:PopResponse, xml:XML):void
		{
			//trace(this, "onIslandResetResponse()", "Error is", response.error);
			// response is null if guest
			if ((response == null) || (response.succeeded))
			{
				var as2Format:Boolean = String(xml.gameVersion) == "AS2";
				
				//Get the island name.
				var island:String = String(xml.island);
				//Uppercase it for the server/AS2.
				island = StringUtil.toUpperCamelCase(island);
				//If it's and AS3 island, then add "_as3".
				if(!as2Format)
				{
					island += "_as3";
				}
				
				//trace(this, "onIslandResetResponse()", "Island is", island);
				
				var lso:SharedObject = ProxyUtils.as2lso;
				if(lso)
				{
					//trace("Has LSO");
					if(lso.data)
					{
						//trace("Has Data");
						if(lso.data.inventory)
						{
							//trace("Has Inventory");
							lso.data.inventory[island] = null;
						}
						if(lso.data.completedEvents)
						{
							//trace("Has Completed Events");
							lso.data.completedEvents[island] = null;
						}
					}
				}
				lso.flush();
				if(lso)
				{
					if(lso.data)
					{
						if(lso.data.inventory)
						{
							//trace(lso.data.inventory[island]);
						}
						if(lso.data.completedEvents)
						{
							//trace(lso.data.completedEvents[island]);
						}
					}
				}
			}
		}
		
		private function traceLSO(object:Object, indent:String = ""):void
		{
			for(var key:* in object)
			{
				var value:* = object[key];
				//trace(typeof(value));
				trace(indent + key + " = " + value);
				if(typeof(value) != "string")
				{
					traceLSO(value, "  ");
				}
			}
		}
		
		private function setupDifficulty():void
		{
			var display:DisplayObjectContainer = this.pageContainer.getChildByName("difficulty") as DisplayObjectContainer;
			if(display)
			{
				var entity:Entity = EntityUtils.createSpatialEntity(this, display);
				entity.add(new Id("difficulty"));
				
				var tween:Tween = new Tween();
				entity.add(tween);
				
				var difficulty:int = int(this.pageXML.difficulty);
				
				for(var index:int = 1; index <= 3; ++index)
				{
					var skull:DisplayObject = display.getChildByName("skull" + index);
					if(skull)
					{
						var scaleX:Number = skull.scaleX;
						var scaleY:Number = skull.scaleY;
						skull.scaleX = 0;
						skull.scaleY = 0;
						if(index <= difficulty)
						{
							tween.to(skull, 0.5, {delay:index * 0.25, scaleX:scaleX, scaleY:scaleY, ease:Back.easeOut});
						}
						else
						{
							skull.visible = false;
						}
					}
				}
			}
		}
		
		private function setupProgress():void
		{
			var islandProgressLoader:IslandProgressLoader = new IslandProgressLoader(this.shellApi, island);
			islandProgressLoader.loaded.add(progressLoaded);
			islandProgressLoader.load();
		}
		
		private function progressLoaded(islandProgressLoader:IslandProgressLoader):void
		{
			this.progress = islandProgressLoader.progresses[0];
			
			var display:DisplayObjectContainer = this.pageContainer.getChildByName("progress") as DisplayObjectContainer;
			if(display)
			{
				var entity:Entity = EntityUtils.createSpatialEntity(this, display);
				entity.add(new Id("progress"));
				var background:DisplayObject = display.getChildByName("background");
				var bar:DisplayObject = display.getChildByName("bar");
				bar.width = 0;
				
				var width:Number = background.width * islandProgressLoader.progresses[0];
				
				// if ftue completed, then don't draw progress
				// rlh: fix for returning to ftue if have medal
				if ((island == "ftue") && (numCompletions > 0))
				{
					this.restartIsland();
				}
				else
				{				
					var tween:Tween = new Tween();
					tween.to(bar, (width / background.width) * 1.5, {width:width, ease:Linear.easeNone});
					entity.add(tween);
				}				
			}
			islandProgressLoader.destroy();
		}
		
		private function setupMedallion():void
		{
			var medallion:Entity = this.getEntityById("medallion");
			if(medallion != null)
			{
				numCompletions = this.shellApi.profileManager.active.islandCompletes[island];
				
				var display:Display = medallion.get(Display);
				var spatial:Spatial = medallion.get(Spatial);
				
				var clip:MovieClip = display.displayObject;
				
				var episode:int = int(this.pageXML.episode);
				if(episode > 0)
				{
					clip.gotoAndStop(episode);
				}
				
				if(numCompletions <= 0)
				{
					var r:Number = 0.30;
					var g:Number = 0.59;
					var b:Number = 0.11;
					clip.filters = [new ColorMatrixFilter([r, g, b, 0, 0, r, g, b, 0, 0, r, g, b, 0, 0, 0, 0, 0, 1, 0])];
				}
				
				var sprite:Sprite = this.createBitmapSprite(clip);
				Bitmap(sprite.getChildAt(0)).smoothing = true;
				display.displayObject = sprite;
				spatial.x = sprite.x;
				spatial.y = sprite.y;
				spatial.scaleX = sprite.scaleX;
				spatial.scaleY = sprite.scaleY;
				
				if(numCompletions > 0)
				{
					var scaleX:Number = spatial.scaleX;
					var scaleY:Number = spatial.scaleY;
					sprite.scaleX += 1;
					sprite.scaleY += 1;
					spatial.scaleX += 1;
					spatial.scaleY += 1;
					var tween:Tween = new Tween();
					tween.to(spatial, 0.5, {scaleX:scaleX, scaleY:scaleY, ease:Back.easeOut});
					medallion.add(tween);
					
					var emitter2D:Emitter2D = new Emitter2D();
					emitter2D.counter = new Blast(10);
					emitter2D.addInitializer(new ImageClass(PolyStar, [14, 8, 5, 0xF7D637]));
					//emitter2D.addInitializer(new Position(new RectangleZone(-50, -50, 50, 50)));
					emitter2D.addInitializer(new Velocity(new DiscZone(new Point(), 80, 80)));
					emitter2D.addInitializer(new RotateVelocity(-5, 5));
					emitter2D.addInitializer(new Lifetime(0.5, 1));
					
					emitter2D.addAction(new Age());
					emitter2D.addAction(new Rotate());
					emitter2D.addAction(new Move());
					emitter2D.addAction(new ScaleImage(1, 0.5));
					
					var emitterEntity:Entity = EmitterCreator.create(this, sprite.parent, emitter2D);
					var emitterSpatial:Spatial = emitterEntity.get(Spatial);
					emitterSpatial.x = sprite.x;
					emitterSpatial.y = sprite.y;
					//Remove the particle emitter once the blast of stars is done.
					Emitter(emitterEntity.get(Emitter)).remove = true;
				}
			}
		}
		
		private function setupCompletions():void
		{
			var display:DisplayObjectContainer = this.pageContainer.getChildByName("completions") as DisplayObjectContainer;
			if(display)
			{
				var numCompletions:int = this.shellApi.profileManager.active.islandCompletes[island];
				
				var entity:Entity = EntityUtils.createSpatialEntity(this, display);
				entity.add(new Id("completions"));
				
				var complete:TextField = TextUtils.refreshText(display.getChildByName("completions") as TextField);
				complete.text = String(numCompletions);
				complete.autoSize = TextFieldAutoSize.LEFT;
				
				var bubble:DisplayObject = display.getChildByName("bubble");
				bubble.width = complete.width + complete.x * 2;
			}
		}
		
		protected function purchaseClicked(button:Entity=null):void
		{
			trace("purchase clicked");
			// prevent device from going to sleep while downloading an island
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			var contentId:String = island;
			_contentRetrievalGroup.processComplete.addOnce( retrievalResponse );	// add handler for when content is complete.  Need to make sure this doesn't get out of sync. - bard
			_contentRetrievalGroup.purchaseContent(contentId, _contentType, true );
		}
		
		protected function downloadClicked(button:Entity):void
		{
			trace("download clicked");
			// prevent device from going to sleep while downloading an island
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			var contentId:String = island;
			_contentRetrievalGroup.processComplete.addOnce( retrievalResponse );	// add handler for when content is complete.  Need to make sure this doesn't get out of sync. - bard
			_contentRetrievalGroup.downloadContent(contentId, _contentType );
		}
		
		protected function retrievalResponse( success:Boolean = false, content:String = "" ):void
		{
			trace("download complete");
			// return sleep mechanics to normal after downloading is completed
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
			if( success )
			{
				this.returnToIslandAndScene();
			}
		}
		
		private function playClicked(entity:Entity):void
		{
			if(shellApi.networkAvailable())
			{
				(entity.get(Interaction) as Interaction).lock = true;
				
				this.returnToIslandAndScene();
			}else
			{
				shellApi.showNeedNetworkPopup();
			}
			
		}
		
		private function returnToIslandAndScene():void
		{			
			var vars:URLVariables = new URLVariables();
			vars.context = 	"episode_selected:" + island + ";" +
							"episode_selected_percentage:" + int(this.progress * 100);
			vars.dimensions = new Object();
			vars.dimensions["episode_selected"] = island;
			vars.dimensions["episode_selected_percentage"] = int(this.progress * 100);
			this.shellApi.track("MapIslandPlayed", island, null, null, null, null, null, vars);
			
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
			trace(this, "loadSceneAS3OrAS2()", "island=", island, "scene=", scene, "x=", x, "y=", y, "direction=", direction);
			if(scene.indexOf(".") > -1)
			{
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

		private function preVisit(islandName:String, sceneName:String, playerX:Number, playerY:Number, playerDirection:String):void
		{
			islandName = islandName.charAt(0).toUpperCase() + islandName.substring(1);
			var profile:ProfileData = shellApi.profileManager.active;
			if (profile.isGuest) {
				return;
			}
			var postVars:URLVariables = new URLVariables();
			postVars.login		= profile.login;
			postVars.pass_hash	= profile.pass_hash;
			postVars.dbid		= profile.dbid;
			postVars.island		= islandName;
			postVars.lastRoom	= sceneName;
			postVars.lastx		= playerX;
			postVars.lasty		= playerY;
			
			// get data
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/visit_scene.php", postVars, URLRequestMethod.POST);
		}
		
		protected var _contentType:String = "Island";
		protected var _contentRetrievalGroup:ContentRetrievalGroup;
		private var numCompletions:int;
		private var island:String;
	}
}

